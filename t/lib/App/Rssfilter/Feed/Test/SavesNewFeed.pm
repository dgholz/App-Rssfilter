use strict;
use warnings;
use feature qw< :5.14 >;

package App::Rssfilter::Feed::Test::SavesNewFeed {

    use Test::Routine;
    use Test::More;
    use namespace::autoclean;

    requires 'mock_storage';
    requires 'new_feed';

    test saves_new_feed => sub {
        my ( $self ) = @_;
        my ( $name, $args ) = $self->mock_storage->next_call;
        is( $name, 'save',               'attempted to save ...' );
        is( $args->[1], $self->new_feed, '... the new feed' );
    };

}

1;