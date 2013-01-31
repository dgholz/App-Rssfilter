use strict;
use warnings;
use feature qw< :5.14 >;

package App::Rssfilter::Feed::Test::RulesNotRun {

    use Test::Routine;
    use Test::More;
    use namespace::autoclean;
    use Method::Signatures;

    requires 'mock_rule';

    test rules_not_run => method {
        ok(
            ! $self->mock_rule->called( 'constain' ),
            'rules not run'
        );
    };

}

1;
