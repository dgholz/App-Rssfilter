use Test::Most;

use App::Rssfilter;

my $config = { 
    groups => [
        { group => 'foo', },
        { group => 'bar', },
        { group => 'baz', },
    ]
};

is_deeply
    [ App::Rssfilter::requested_groups_or_everything( $config ) ],
    [ { group => 'foo' }, { group => 'bar' }, { group => 'baz' }, ],
        'returns all groups if no groups requested';

is_deeply
    [ App::Rssfilter::requested_groups_or_everything( $config, 'foo' ) ],
    [ { group => 'foo' }, ],
        'returns matching group if a group requested ...';

is_deeply
    [ App::Rssfilter::requested_groups_or_everything( $config, qw( foo baz ) ) ],
    [ { group => 'foo' }, { group => 'baz' }, ],
        ' ... and returns all matching groups if multiple groups requested';

throws_ok
    { App::Rssfilter::requested_groups_or_everything( $config, qw( quux ) ) }
    qr/don't know how to get groups: quux/,
        'throws error when requested group not found';

done_testing;
