use strict;
use warnings;
use feature qw< :5.14 >;

package App::Rssfilter::Feed::Test::AttemptsToFetchNewFeed {

    use Test::Routine;
    use Test::More;
    use namespace::autoclean;

    requires 'feed';
    requires 'feed_url';
    requires 'mock_ua';
    requires 'last_modified';

    test attempts_to_fetch_new_feed => sub {
        my ( $self ) = @_;
        $self->feed->update;
        my ( $name, $args ) = $self->mock_ua->next_call;
        is( $name, 'get',                'attempted to fetch ... ' );
        is( $args->[1], $self->feed_url, ' ... the new feed' );

        if ( defined( $self->last_modified ) ) {
            is(
                $args->[2]->{ 'If-Modified-Since' },
                $self->last_modified,
                'and indicated the last time we fetched the feed' 
            );
        }
    };

}

1;
