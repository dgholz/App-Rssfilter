use strict;
use warnings;
use feature qw< :5.14 >;

use Test::Routine::Util;
use Test::Most;
use lib qw< t/lib >;

use Carp::Always;
run_tests(
    'converts lists of scalars, hashrefs, objects to certain type of objects',
    [
        'App::Rssfilter::FromHash::Tester',
        'App::Rssfilter::FromHash::Test::ConvertTo',
        'App::Rssfilter::FromHash::Test::ConvertToWithTwoScalars',
        'App::Rssfilter::FromHash::Test::ConvertToWithHashref',
        'App::Rssfilter::FromHash::Test::ConvertToWithObject',
    ],
);

done_testing;
