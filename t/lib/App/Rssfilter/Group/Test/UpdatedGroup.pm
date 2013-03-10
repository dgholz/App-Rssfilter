use strict;
use warnings;
use feature qw< :5.14 >;

package App::Rssfilter::Group::Test::UpdatedGroup {

    use Test::Routine;
    use Test::More;
    use namespace::autoclean;
    use Method::Signatures;

    requires 'do_update';
    requires 'mock_group';
    requires 'path_pushed_storage';

    before 'do_update' => method( $group ) {
        $group->add_group( $self->mock_group );
    };

    test updated_group => method {
        $self->mock_group->called_ok( 'update', 'called update on nested group ...');

        my (undef, %group_update_args) = $self->mock_group->call_args(0);

        is_deeply(
               $group_update_args{storage},
               $self->path_pushed_storage,
               '... and passed path_push storage to nested group when updating'
        );

        is_deeply(
               $group_update_args{rules},
               $self->group->rules,
               '... and passed its rules to nested feed when updating'
        );
    };

}

1;
