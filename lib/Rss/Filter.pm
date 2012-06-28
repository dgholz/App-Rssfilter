# ABSTRACT: download and transform RSS feeds

use strict;
use warnings;
use feature qw( :5.14 );

package Rss::Filter {
    use Mojo::UserAgent;
    use List::Util qw( first );
    use DateTime::Format::Strptime;
    use Method::Signatures;
    use Try::Tiny;
    use Carp::Always;
    use Carp;
    use Module::Pluggable
        search_path => 'Rss::Match',
        sub_name    => 'matchers',
        require     => 1;
    use Module::Pluggable
        search_path => 'Rss::Filter',
        sub_name    => 'filters',
        require     => 1;
    use Feed::Storage;
    use Moo;

    has logger => (
        is => 'lazy',
    );

    method _build_logger {
        use Log::Log4perl qw< :levels >;
        Log::Log4perl->easy_init( { level => $DEBUG } );
        Log::Log4perl->get_logger( ref $self );
    }

    method filter_items( $feed_dom, $filter, @matchers ) {
        my %memo;
        @memo{ __PACKAGE__->matchers } = map { $_->can( 'match' ) } __PACKAGE__->matchers;
        @matchers = grep { defined $memo{ $_ } } @matchers;
        $feed_dom->find('item')->each(
            sub {
                my ($item) = @_;
                if ( my $matcher = first { $_->match($item) } @matchers ) {
                    $self->logger->debug( "applying $filter since $matcher matched ", $item->at('guid')// 'an item with no guid' );
                    $filter->filter( $item, $matcher );
                }
            }
        );
        return $feed_dom;
    }

    method to_http_date( $datetime_str ) {
        my $datetime;
        try {
                $datetime = DateTime::Format::Strptime->new( on_error => 'croak', pattern => "%a, %d %b %Y %T %z")->parse_datetime( $datetime_str );
        } catch {
                $datetime = DateTime::Format::Strptime->new( on_error => 'croak', pattern => "%a, %d %b %Y %T %Z")->parse_datetime( $datetime_str );
        };
        return $datetime->set_time_zone("GMT")->strftime( "%a, %d %b %Y %T %Z" );
    }

    method update_group( $config, $group ) {
        my $group_name = $group->{group};
        $self->logger->debug( "filtering feeds in ". $group->{group} );
        my @matchers = map { s/^/Rss::Match::/r } map { @{ $_->{match} // [] } } $group, $config;
        push @matchers, q{Rss::Match::Dupes};
        my %memo;
        @memo{ __PACKAGE__->filters } = map { $_->can( 'filter' ) } __PACKAGE__->filters;
        my $filter = first { defined $memo{ $_ } } map { s/^/Rss::Filter::/r } grep { defined } map { $_->{ifMatched} } $group, $config;
        $filter //= q{Rss::Filter::MarkTitle};
        foreach my $feed ( @{ $group->{feeds} } ) {
            $self->update_feed( $group, $feed, $filter, @matchers );
        }
    }

    method update_feed( $group, $feed, $filter, @matchers ) = @_;
        my ( $feed_name, $feed_url ) = each $feed;
        my $stored_feed = Feed::Storage->new(
            group_name => $group->{group},
            feed_name  => $feed_name,
        );
        my $old = $stored_feed->load_existing;
        my $last_modified = 'Thu, 01 Jan 1970 00:00:00 +0000';
        if ( my $last_update = try { $old->at( 'rss > channel > lastBuildDate, pubDate' ) } ) {
            $last_modified = $last_update->text || $last_modified;
        }
        $self->logger->debug( 'last update was ', $last_modified );
        my $new = Mojo::UserAgent->new->get( $feed_url, { 'If-Modified-Since' => $self->to_http_date( $last_modified ) } )->res;
        if ( $new->code == 200 ) {
            $self->logger->debug( "found a newer feed! ", $new->dom->at('rss > channel > lastBuildDate, pubDate')->text );
            $self->logger->debug( "filtering $feed_name" );
            $new = $self->filter_items( $new->dom, $filter, @matchers );
            $self->logger->debug( "collecting guids from old feed" );
            $stored_feed->save_feed( $new );
        }
    }
}

1;
