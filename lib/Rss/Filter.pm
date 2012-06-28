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
        sub_name    => '_matchers',
        require     => 1;
    use Module::Pluggable
        search_path => 'Rss::Filter',
        sub_name    => '_filters',
        require     => 1;
    use Feed::Storage;
    use Moo;

    has config => (
        is       => 'rw',
        required => 1,
    );

    has logger => (
        is => 'lazy',
    );

    method _build_logger {
        use Log::Log4perl qw< :levels >;
        Log::Log4perl->easy_init( { level => $DEBUG } );
        Log::Log4perl->get_logger( ref $self );
    }

    has filters => (
        is => 'lazy',
    );

    method _build_filters {
        return { prep_plugins( 'filter', $self->_filters ) };
    }

    has matchers => (
        is => 'lazy',
    );

    method _build_matchers {
        return { prep_plugins( 'match', $self->_matchers ) };
    }

    func prep_plugins( $method, @plugins ) {
        return  map { @$_ }
               grep { defined $_->[1] }
                map { [ $_, $_->can( $method ) ] } @plugins;
    }

    method filter_items( $feed_dom, $filter, @matchers ) {
        @matchers = grep { exists $self->matchers->{ $_ } }
                     map { /::/ ? $_ : s/^/Rss::Match::/r } @matchers;
        $filter = first  { exists $self->filters->{ $_ } }
                     map { /::/ ? $_ : s/^/Rss::Filter::/r } $filter;
        return $feed_dom unless @matchers and $filter;
        $feed_dom->find('item')->each(
            sub {
                my ($item) = @_;
                if ( my $matcher = first { $self->matchers->{ $_ }->($item) } @matchers ) {
                    $self->logger->debug( "applying $filter since $matcher matched ", $item->at('guid')// 'an item with no guid' );
                    $self->filters->{ $filter }->( $item, $matcher );
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

    method update_group( $group ) {
        $self->logger->debug( "filtering feeds in ". $group->{group} );
        foreach my $feed ( @{ $group->{feeds} } ) {
            $self->update_feed( $group, $feed );
        }
    }

    method update_feed( $group, $feed ) {
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
            $new = $self->filter_items( $new->dom, $group->{ifMatched}, @{ $group->{match} } );
            $self->logger->debug( "collecting guids from old feed" );
            $stored_feed->save_feed( $new );
        }
    }
}

1;
