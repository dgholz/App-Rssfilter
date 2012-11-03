use strict;
use warnings;
use feature qw< :5.14 >;

use Test::Routine::Util;
use Test::Most;
use lib qw< t/lib >;

run_tests(
    'last_modified get value from underlying file',
    [
        'App::Rssfilter::Feed::Storage::Tester',
        'App::Rssfilter::Feed::Storage::Test::LastModifiedComesFromFile',
    ],
);

done_testing;
