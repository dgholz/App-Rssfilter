use Test::Most;
use Rss::Filter;

use Test::MockObject;
use Mojo::DOM;
use Mojo::Transaction;
use Mojo::Message::Response;
use YAML::XS;

my $updated_fetch = Mojo::Message::Response->new;
$updated_fetch->parse(<<"EOM");
HTTP/1.0 200 OK
Content-Type: text/xml
Date: Tue, 21 Aug 2012 23:10:31 GMT

<?xml version="1.0" encoding="UTF-8"?>
<rss>
  <channel>
    <item>
      <guid>Macbeth by Orson Welles</guid>
      <link>http://www.secondsightfilms.co.uk/cat.php?a=74&p=-1243</link>
      <category>Shakespeare</category>
    </item>
    <item>
      <guid>Othello by Orson Welles</guid>
      <link>http://www.secondsightfilms.co.uk/cat.php?a=80&p=-1213</link>
      <category>Shakespeare</category>
    </item>
  </channel>
</rss>
EOM

my $mock_ua = Test::MockObject->new;
$mock_ua->set_always( 'get', Mojo::Transaction->new->res( $updated_fetch ) );

my $updated_storage = Test::MockObject->new;
$updated_storage->set_always( '-load_existing', Mojo::DOM->new );
$updated_storage->set_always( '-last_modified', 'Tue, 21 Aug 2012 23:10:30 GMT' );
$updated_storage->set_true( 'save_feed' );

my $mock_storage = Test::MockObject->new;
$mock_storage->fake_module( 'Mock::Feed::Storage', new => sub {
    return $updated_storage;
});

my $rf = Rss::Filter->new( ua => $mock_ua, storage => 'Mock::Feed::Storage' );
use Log::Log4perl qw< :levels >;
$rf->logger->level( $OFF );

my $test_config = Load(<<"End_Of_Config");
groups:
- group: Test
  match:
  - Category[Shakespeare]
  ifMatched: DeleteItem
  feeds:
  - Second Sight: http://www.secondsightfilms.co.uk/
End_Of_Config

$rf->update_group( $test_config->{groups}->[0] );

ok(
    ! $updated_storage->called( 'save_feed' ),
    'did not attempt to save feed which had all its items filtered out',
);

done_testing;
