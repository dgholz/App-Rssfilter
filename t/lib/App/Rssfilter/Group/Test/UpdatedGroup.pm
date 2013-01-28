use strict;
use warnings;
use feature qw< :5.14 >;

package App::Rssfilter::Group::Test::UpdatedGroup {

    use Test::Routine;
    use Test::More;
    use Test::MockObject;
    use namespace::autoclean;

    requires 'mock_group';
    requires 'group_name';
    requires 'mock_storage';

    test nested_group => sub {
        my ( $self ) = @_;

        $self->group->add_group( $self->mock_group );
        my %update_args;
        $self->mock_group->mock( update => sub { shift; %update_args = @_ } );

        my $sub_storage = Test::MockObject->new;
        $sub_storage->set_isa( 'Rss::Appfilter::Feed;:Storage' );

        my @path_push_args;
        $self->mock_storage->mock( path_push => sub { @path_push_args = @_; return $sub_storage } );

        $self->group->update;

        $self->mock_storage->called_ok( 'path_push', 'called path_push ...');
        is(
            $path_push_args[1],
            $self->group_name,
            '... with the name of the group'
        );

        $self->mock_group->called_ok( 'update', 'called update on nested group ...');

        is_deeply(
               $update_args{storage},
               $sub_storage,
               '... and passed path_push storage to nested group when updating'
        );
    };

}

1;
