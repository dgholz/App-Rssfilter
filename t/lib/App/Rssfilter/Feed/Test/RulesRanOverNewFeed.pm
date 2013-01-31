use strict;
use warnings;
use feature qw< :5.14 >;

package App::Rssfilter::Feed::Test::RulesRanOverNewFeed {

    use Test::Routine;
    use Test::More;
    use namespace::autoclean;
    use Method::Signatures;

    requires 'mock_rule';
    requires 'new_feed';

    test rules_ran_over_new_feed => method {
        my ( $name, $args ) = $self->mock_rule->next_call;
        is( $name, 'constrain',          'rules were called ... ' );
        is( $args->[1], $self->new_feed, ' ... with the new feed' );
    };

}

1;
