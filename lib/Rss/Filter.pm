# ABSTRACT: download and transform RSS feeds

use strict;
use warnings;
use feature qw( :5.14 );

package Rss::Filter {
    use ojo;
    use List::Util qw( first );
    use File::Slurp;
    use Path::Class::File qw( file );
    use Log::Log4perl qw( :easy );
    use DateTime::Format::Strptime;
    use Try::Tiny;
    use Carp::Always;
    use Carp;
    use Module::Pluggable search_path => 'Rss::Match',  sub_name => 'matchers', require => 1;
    use Module::Pluggable search_path => 'Rss::Filter', sub_name => 'filters',  require => 1;

    Log::Log4perl->easy_init( { level => $DEBUG } );

    sub filter_items {
        my ( $feed_dom, $filter, @matchers ) = @_;
        my %memo;
        @memo{ __PACKAGE__->matchers } = map { $_->can( 'match' ) } __PACKAGE__->matchers;
        @matchers = grep { defined $memo{ $_ } } @matchers;
        $feed_dom->find('item')->each(
            sub {
                my ($item) = @_;
                if ( my $matcher = first { $_->match($item) } @matchers ) {
                    DEBUG( "will $filter since $matcher matched ", $item->guid->text );
                    $filter->filter( $item, $matcher );
                }
            }
        );
        return $feed_dom;
    }

    sub load_existing {
        my ( $filename ) = @_;
        DEBUG( "loading $filename ..." );
        if( ! -e $filename ) {
            return Mojo::DOM->new;
        }
        return Mojo::DOM->new( scalar read_file( $filename ) );
    }

    sub to_http_date {
        my ( $datetime_str ) = @_;
        my $datetime;
    try {
            $datetime = DateTime::Format::Strptime->new( on_error => 'croak', pattern => "%a, %d %b %Y %T %z")->parse_datetime( $datetime_str );
    } catch {
            $datetime = DateTime::Format::Strptime->new( on_error => 'croak', pattern => "%a, %d %b %Y %T %Z")->parse_datetime( $datetime_str );
    };
        return $datetime->set_time_zone("GMT")->strftime( "%a, %d %b %Y %T %Z" );
    }

    sub update_group {
        my ( $config, $group ) = @_;
        my $group_name = $group->{group};
        DEBUG( "filtering feeds in $group_name" );
        my @matchers = map { s/^/Rss::Match::/r } map { @{ $_->{match} // [] } } $group, $config;
        push @matchers, q{Rss::Match::Dupes};
        my %memo;
        @memo{ __PACKAGE__->filters } = map { $_->can( 'filter' ) } __PACKAGE__->filters;
        my $filter = first { defined $memo{ $_ } } map { s/^/Rss::Filter::/r } grep { defined } map { $_->{ifMatched} } $group, $config;
        $filter //= q{Rss::Filter::MarkTitle};
        if( not -d $group_name ) {
            DEBUG( "no $group_name directory! making one" );
            mkdir $group_name;
        }
        foreach my $feed ( @{ $group->{feeds} } ) {
            update_feed( $group, $feed, $filter, @matchers );
        }
    }

    sub update_feed {
        my ( $group, $feed, $filter, @matchers ) = @_;
        my ( $feed_name, $feed_url ) = each $feed;
        my ( $filename ) = map { tr/ /_/sr } Path::Class::File->new( $group->{group}, ( $feed_name . q{.rss} ) );
        my $old = load_existing( $filename );
        my $last_modified = 'Thu, 01 Jan 1970 00:00:00 +0000';
        if ( my $last_update = try { $old->at( 'rss > channel > lastBuildDate, pubDate' ) } ) {
            $last_modified = $last_update->text || $last_modified;
        }
        DEBUG( 'last update was ', $last_modified );
        my $new = g( $feed_url, { 'If-Modified-Since' => $self->to_http_date( $last_modified ) } )->res;
        if ( $new->code == 200 ) {
            DEBUG( "found a newer feed! ", $new->dom->at('rss > channel > lastBuildDate, pubDate')->text );
            DEBUG( "filtering $feed_name" );
            $new = filter_items( $new->dom, $filter, @matchers );
            DEBUG( "collecting guids from old feed" );
            DEBUG( "writing out new filtered feed to $filename" );
            write_file( $filename, $new->to_xml );
        }
    }

}

1;
