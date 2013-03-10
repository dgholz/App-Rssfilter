use strict;
use warnings;
use feature qw< :5.14 >;

package App::Rssfilter::Group::Test::Update {

    use Test::Routine;
    use Test::Exception;
    use namespace::autoclean;
    use Method::Signatures;

    requires 'group';
    requires 'group_name';
    requires 'mock_storage';

    method do_update( $group ) {
        $self->mock_storage->set_always( path_push => $self->path_pushed_storage );
        $group->update;
    }

    test update => method {
        lives_ok(
            sub { $self->do_update( $self->group ) },
            'called update without calamitous results'
        );

        $self->mock_storage->called_ok( 'path_push', 'called path_push ...');

        $self->mock_storage->called_args_pos_is(
            0,
            2,
            $self->group_name,
            '... with the name of the group'
        );
    };

}

1;

