use strict;
use warnings;
use feature qw< :5.14 >;

package App::Rssfilter::Group::Test::GroupsCanBeNested {

    use Test::Routine;
    use Test::More;
    use namespace::autoclean;

    requires 'mock_group';
    requires 'group_name';

    test nested_group => sub {
        my ( $self ) = @_;

        my $new_group = $self->group->add_group( $self->mock_group );

        $self->group->update;

        $self->mock_group->called_ok( 'update', 'called update on nested group ...');

        $self->mock_group->called_args_pos_is(
               0,
               0,
               [ $self->group_name ],
               q{... and passed group name to nested group when updating}
        );
    };

}

1;
