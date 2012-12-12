use strict;
use warnings;
use feature qw< :5.14 >;

package App::Rssfilter::Group::Test::GroupsCanBeNested {

    use Test::Routine;
    use Test::More;
    use namespace::autoclean;

    requires 'group';

    test nested_group => sub {
        my ( $self ) = @_;

        my $new_group = $self->group->add_group( 'hiiii' );
        my $new_feed  = $new_group->add_feed( 'welp' => 'http://we.lp/news.rss' );

        is(
            $new_feed->storage->group_name,
            join( '/', $self->group->name, 'hiiii' ),
            q{nested groups include their parent's name in the group_name passed to add_feed}
        );
    };

}

1;
