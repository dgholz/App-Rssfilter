use strict;
use warnings;
use feature qw< :5.14 >;

use Test::Routine::Util;
use Test::Most;
use lib qw< t/lib >;

run_tests(
    'group',
    [
        'App::Rssfilter::Group::Tester',
        'App::Rssfilter::Group::Test::Update',
        'App::Rssfilter::Group::Test::UpdatedFeed',
        'App::Rssfilter::Group::Test::UpdatedGroup',
    ],
);

done_testing;
