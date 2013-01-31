use strict;
use warnings;
use feature qw< :5.14 >;

package App::Rssfilter::Feed::Test::RulesRanOverOldFeed {

    use Test::Routine;
    use Test::More;
    use namespace::autoclean;
    use Method::Signatures;

    requires 'mock_rule';
    requires 'old_feed';

    test rules_ran_over_old_feed => method {
        my ( $name, $args ) = $self->mock_rule->next_call;
        is( $name, 'constrain',          'rules were called ... ' );
        is( $args->[1], $self->old_feed, ' ... with the old feed' );
    };

}

1;
