# ABSTRACT: download and transform RSS feeds

use strict;
use warnings;
use feature qw( :5.14 );

package Rss::Filter {
    use Mojo::UserAgent;
    use List::Util qw( first );
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
    use Moo;

    has logger => (
        is => 'lazy',
    );

    method _build_logger {
        use Log::Log4perl qw< :levels >;
        Log::Log4perl->easy_init( { level => $DEBUG } );
        Log::Log4perl->get_logger( ref $self );
    }

    has storage => (
        is => 'ro',
        default => sub { use Feed::Storage; 'Feed::Storage' },
    );

    has ua => (
        is => 'ro',
        default => sub { use Mojo::UserAgent; Mojo::UserAgent->new },
    );

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
                my $matcher = first { $self->matchers->{ $_ }->($item) } @matchers;
                if ( $matcher ) {
                    $self->logger->debug( "applying $filter since $matcher matched ", $item->at('guid') // 'an item with no guid' );
                    $self->filters->{ $filter }->( $item, $matcher );
                }
            }
        );
        return $feed_dom;
    }

    method update_group( $group ) {
        $self->logger->debug( "filtering feeds in ". $group->{group} );
        foreach my $feed ( @{ $group->{feeds} } ) {
            $self->update_feed( $group, $feed );
        }
    }

    method update_feed( $group, $feed ) {
        my ( $feed_name, $feed_url ) = each $feed;
        my $stored_feed = $self->storage->new(
            group_name => $group->{group},
            feed_name  => $feed_name,
        );
        my $old = $stored_feed->load_existing;
        my $last_modified = $stored_feed->last_modified;
        $self->logger->debug( 'last update was ', $last_modified );
        my $new = $self->ua->get( $feed_url, { 'If-Modified-Since' => $last_modified } )->res;
        if ( $new->code == 200 ) {
            $self->logger->debug( "found a newer feed!" );
            $self->logger->debug( "filtering $feed_name" );
            $new = $self->filter_items( $new->dom, $group->{ifMatched}, @{ $group->{match} } );
            if( 0 < $new->find( 'item' )->size ) {
                $self->logger->debug( 'some items left in feed after filtering! saving it!');
                $stored_feed->save_feed( $new );
            }
        }
        # now run filters over previous version of the feed,
        # so old stories in this feed will be recognised as dupes in subsequent feeds
        $self->logger->debug( "collecting guids from old feed" );
        $self->filter_items( $old, $group->{ifMatched}, @{ $group->{match} } );
    }
}

1;
