use strict;
use warnings;
use feature qw< :5.14 >;

use Test::Routine::Util;
use Test::Most;
use lib qw< t/lib >;

use Carp::Always;
run_tests(
    'from_yaml just calls from_hash',
    [
        'App::Rssfilter::FromYaml::Tester',
        'App::Rssfilter::FromYaml::Test::DelegatesToFromHash',
    ],
);

done_testing;
