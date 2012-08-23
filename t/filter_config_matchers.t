use Test::Most;
use Test::MockObject;

use YAML::XS;
use Rss::Filter;

my $games_fetch = Mojo::Message::Response->new;
$games_fetch->parse(<<"EOM");
HTTP/1.0 200 OK
Content-Type: text/xml
Date: Thu, 23 Aug 2012 23:02:31 GMT

<?xml version="1.0" encoding="UTF-8"?>
<rss>
  <channel>
    <item>
      <guid>8989</guid>
      <link>http://boardgamegeek.com/boardgame/8989/hansa</link>
      <category>game:board</category>
    </item>
    <item>
      <guid>5782</guid>
      <link>http://boardgamegeek.com/boardgame/5782/coloretto</link>
      <category>game:card</category>
    </item>
  </channel>
</rss>
EOM

my $mock_ua = Test::MockObject->new;
$mock_ua->set_always( 'get', Mojo::Transaction->new->res( $games_fetch ) );

my $games_storage = Test::MockObject->new;
$games_storage->set_always( '-load_existing', Mojo::DOM->new );
$games_storage->set_always( '-last_modified', 'Thu, 23 Aug 2012 23:02:30 GMT' );
$games_storage->set_true( 'save_feed' );

Test::MockObject->fake_module( 'Mock::Feed::Storage', new => sub {
    return $games_storage;
});

my $test_config = Load(<<"End_Of_Config");
groups:
- group: Test
  match:
  - Games[board,video,card]
  ifMatched: DeleteItem
  feeds:
  - BGG: http://boardgamegeek.com/recentadditions/rss?domain=boardgame
End_Of_Config

my $mock = Test::MockObject->new;
$mock->fake_module( 'Rss::Match::Games', match => sub { $mock->match( splice @_, 1 ); } );
$mock->set_true( 'match' );

my $rf = Rss::Filter->new( ua => $mock_ua, storage => 'Mock::Feed::Storage' );
use Log::Log4perl qw< :levels >;
$rf->logger->level( $OFF );

$rf->update_group( $test_config->{groups}->[0] );

$mock->called_args_pos_is( 0,
    2,
    'board',
    'passing first comma-separated value in square bracket from config as argument to match ...'
);

$mock->called_args_pos_is( 0,
    3,
    'video',
    '... and the second value ...'
);

$mock->called_args_pos_is( 0,
    4,
    'card',
    '... and the final value'
);

is(
     $mock->call_args(0),
    4,
    'only the comma-separated values in square brackets from config are passed to match()'
);

done_testing;
