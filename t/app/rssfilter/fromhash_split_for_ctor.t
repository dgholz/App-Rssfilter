use strict;
use warnings;
use feature qw< :5.14 >;

use Test::Routine::Util;
use Test::Most;
use lib qw< t/lib >;

use Carp::Always;
run_tests(
    'splits lists of scalars, hashrefs, objects into params suitable for ctors',
    [
        'App::Rssfilter::FromHash::Tester',
        'App::Rssfilter::FromHash::Test::SplitForCtor',
        'App::Rssfilter::FromHash::Test::SplitForCtorWithTwoScalars',
        'App::Rssfilter::FromHash::Test::SplitForCtorWithHashRef',
        'App::Rssfilter::FromHash::Test::SplitForCtorWithObject',
    ],
);

done_testing;
