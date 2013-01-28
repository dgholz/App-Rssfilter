use strict;
use warnings;
use feature qw< :5.14 >;

package App::Rssfilter::Group::Test::AddedGroup {

    use Test::Routine;
    use Test::More;
    use Method::Signatures;
    use namespace::autoclean;

    requires 'group';
    requires 'mock_group';

    method count_matches( $needle, \@haystack ) {
        return grep { $needle eq $_ } @haystack;
    }

    method count_mock_group_matches() {
        return $self->count_matches( $self->mock_group, $self->group->groups );
    }

    test added_group => method {
        my $pre_added_group_count = $self->count_mock_group_matches();

        $self->group->add_group( $self->mock_group );

        my $added_group_count = $self->count_mock_group_matches();

        is(
            $added_group_count - $pre_added_group_count,
            1,
            q{group has been added to group's list of subgroups}
        );
    };

}

1;
