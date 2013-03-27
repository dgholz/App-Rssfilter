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
        'App::Rssfilter::Group::Test::AddedRule',
        'App::Rssfilter::Group::Test::AddedFeed',
        'App::Rssfilter::Group::Test::AddedGroup',
        'App::Rssfilter::Group::Test::FetchedSubgroupByName',
    ],
);

done_testing;
