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

        $self->group->add_group( $self->mock_group );
        my %update_args;
        $self->mock_group->mock( update => sub { shift; %update_args = @_ } );

        $self->group->update;

        $self->mock_group->called_ok( 'update', 'called update on nested group ...');

        is_deeply(
               $update_args{groups},
               [ $self->group_name ],
               q{... and passed group name to nested group when updating}
        );
    };

}

1;
