use strict;
use warnings;
use feature qw< :5.14 >;

package App::Rssfilter::Feed::Test::RulesNotRun {

    use Test::Routine;
    use Test::More;
    use namespace::autoclean;

    requires 'mock_rule';

    test rules_not_run => sub {
        my ( $self ) = @_;
        ok(
            ! $self->mock_rule->called( 'constain' ),
            'rules not run'
        );
    };

}

1;
