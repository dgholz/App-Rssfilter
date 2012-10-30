use strict;
use warnings;
use feature qw< :5.14 >;

package App::Rssfilter::Feed::Test::ChecksOldFeed {

    use Test::Routine;
    use Test::More;
    use namespace::autoclean;

    requires 'mock_storage';

    test checks_old_feed => sub {
        my ( $self ) = @_;
        my ( $name, $args );

        ( $name, $args ) = $self->mock_storage->next_call;
        is( $name, 'load', 'loaded old feed' );

        ( $name, $args ) = $self->mock_storage->next_call;
        is( $name, 'last_modified', 'found last time old feed was modified' );
    };

}

1;
