use Test::Most;
use Rss::Filter;

use Test::MockObject;
use Mojo::DOM;
use Mojo::Transaction;
use Mojo::Message::Response;
use YAML::XS;

my $not_updated_existing = <<"END_OF_FEED";
<?xml version="1.0" encoding="UTF-8"?>
<rss>
  <channel>
    <item>
      <guid>Brideshead Revisited</guid>
      <link>http://feed.provider/bhr/</link>
    </item>
  </channel>
</rss>
END_OF_FEED

my $not_updated_fetch = Mojo::Message::Response->new;
$not_updated_fetch->parse(<<"EOM");
HTTP/1.0 304 Not Modified
Date: Thu, 01 Jan 1970 00:00:00 GMT
EOM

my $not_updated_storage = Test::MockObject->new;
$not_updated_storage->set_always( '-load_existing', Mojo::DOM->new( $not_updated_existing ) );
$not_updated_storage->set_always( '-last_modified', 'Thu, 01 Jan 1970 00:00:00 GMT' );

my $updated_fetch = Mojo::Message::Response->new;
$updated_fetch->parse(<<"EOM");
HTTP/1.0 200 OK
Content-Type: text/xml
Date: Mon, 20 Aug 2012 22:27:31 GMT

<?xml version="1.0" encoding="UTF-8"?>
<rss>
  <channel>
    <item>
      <guid>Jewel in the Crown</guid>
      <link>http://feed.provider/jitc/</link>
    </item>
    <item>
      <guid>Brideshead Revisited</guid>
      <link>http://feed.provider/bhr/</link>
    </item>
  </channel>
</rss>
EOM

my $updated_storage = Test::MockObject->new;
$updated_storage->set_always( '-load_existing', Mojo::DOM->new );
$updated_storage->set_always( '-last_modified', 'Mon, 20 Aug 2012 22:27:30 GMT' );
$updated_storage->set_true( 'save_feed' );

my $mock_storage = Test::MockObject->new;
$mock_storage->fake_module( 'Mock::Feed::Storage', new => sub {
    shift;
    my %args = @_;
    {
        not_updated => $not_updated_storage,
        updated     => $updated_storage,
    }->{ $args{feed_name} };
});

my $mock_ua = Test::MockObject->new;
$mock_ua->mock( 'get', sub {
    my $message_res = {
        'http://feed.provider/no_update'  => $not_updated_fetch,
        'http://feed.provider/yes_update' => $updated_fetch,
    }->{ $_[1] };
    Mojo::Transaction->new->res( $message_res );
});

my $rf = Rss::Filter->new( ua => $mock_ua, storage => 'Mock::Feed::Storage' );
use Log::Log4perl qw< :levels >;
$rf->logger->level( $OFF );

my $test_config = Load(<<"End_Of_Config");
groups:
- group: Test
  match:
  - Duplicates
  ifMatched: DeleteItem
  feeds:
  - not_updated: http://feed.provider/no_update
  - updated:     http://feed.provider/yes_update
End_Of_Config

$rf->update_group( $test_config->{groups}->[0] );

$updated_storage->called_pos_ok(
    1,
    'save_feed',
    'a newer feed was saved ...'
);

my $expected_save = Mojo::DOM->new(<<"End_Of_Feed");
<?xml version="1.0" encoding="UTF-8"?>
<rss>
  <channel>
    <item>
      <guid>Jewel in the Crown</guid>
      <link>http://feed.provider/jitc/</link>
    </item>
    
  </channel>
</rss>
End_Of_Feed

$updated_storage->called_args_pos_is(
    1,
    2,
    $expected_save,
    '... without the article present in the previous version of the feed which was not updated'
);

done_testing;
