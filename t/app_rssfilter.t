use Test::Most;

use Test::MockObject;
my $mock_rss_filter;
BEGIN {
    $mock_rss_filter = Test::MockObject->new;
    $mock_rss_filter->fake_module( 'Rss::Filter' );
    $mock_rss_filter->fake_new( 'Rss::Filter' );
}

use App::Rssfilter;

my $config = { 
    groups => [
        { group => 'giraffe', },
        { group => 'crocodile', },
    ]
};

is_deeply(
    [ App::Rssfilter::requested_groups_or_everything( $config ) ],
    [ { group => 'giraffe' }, { group => 'crocodile' }, ],
        'returns all groups if no groups requested'
);

is_deeply(
    [ App::Rssfilter::requested_groups_or_everything( $config, 'giraffe' ) ],
    [ { group => 'giraffe' }, ],
        'returns matching group if a group requested ...'
);

is_deeply(
    [ App::Rssfilter::requested_groups_or_everything( $config, qw( giraffe crocodile ) ) ],
    [ { group => 'giraffe' }, { group => 'crocodile' }, ],
        ' ... and returns all matching groups if multiple groups requested'
);

throws_ok(
    sub { App::Rssfilter::requested_groups_or_everything( $config, qw< fox > ) },
    qr/don't know how to get groups: fox/,
        'throws error when requested group not found'
);

$mock_rss_filter->set_true( 'update_group' );
{
    local @ARGV;
    App::Rssfilter->run( $config );
    my ( $name, $args );

    ( $name, $args ) = $mock_rss_filter->next_call;
    is(
        $name,
        'update_group',
            'run() will call Rss::Filter->update_group ...'
    );

    is_deeply(
        $args->[1],
        { group => 'giraffe' },
            '... with the first group from the passed config ...'
    );

    ( $name, $args ) = $mock_rss_filter->next_call;
    is(
        $name,
        'update_group',
            '... and will continue calling Rss::Filter->update_group ...'
    );

    is_deeply(
        $args->[1],
        { group => 'crocodile' },
            '... with the next group from the passed config ...'
    );

    ( $name, $args ) = $mock_rss_filter->next_call;
    is(
        $name,
        undef,
            q{... and that's all}
    );
}

{
    local @ARGV = 'crocodile';
    App::Rssfilter->run( $config );
    my ( $name, $args );

    ( $name, $args ) = $mock_rss_filter->next_call;
    is(
        $name,
        'update_group',
            'run() will call Rss::Filter->update_group ...'
    );

    is_deeply(
        $args->[1],
        { group => 'crocodile' },
            '... with the group from the config which is present in @ARGV ...'
    );

    ( $name, $args ) = $mock_rss_filter->next_call;
    is(
        $name,
        undef,
            q{... and that's all}
    );
}

{
    App::Rssfilter->run( $config, 'giraffe' );
    my ( $name, $args );

    ( $name, $args ) = $mock_rss_filter->next_call;
    is(
        $name,
        'update_group',
            'run( "group" ) will call Rss::Filter->update_group ...'
    );

    is_deeply(
        $args->[1],
        { group => 'giraffe' },
            '... with the group passed as an argument ...'
    );

    ( $name, $args ) = $mock_rss_filter->next_call;
    is(
        $name,
        undef,
            q{... and that's all}
    );
}

done_testing;
