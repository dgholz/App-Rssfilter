use Test::Most;
use Rss::Filter;

use Test::MockObject;
use Mojo::DOM;
use Mojo::Transaction;
use Mojo::Message::Response;

package Rss::Match::AlwaysMatch {
    sub match { !!1; }
    1;
}

package Rss::Filter::ReplaceItemWithHello {
    sub filter {
        my ( $item, $matcher ) = @_;
        $item->replace_content('hello');
    }
    1;
}

my $mock_storage = Test::MockObject->new;
$mock_storage->fake_module( 'Mock::Feed::Storage' );
$mock_storage->fake_new( 'Mock::Feed::Storage' );
$mock_storage->set_always( 'load_existing', Mojo::DOM->new('<call>the doctor</call>' ) );
$mock_storage->set_true( 'save_feed' );

my $message_res = Mojo::Message::Response->new;
$message_res->parse(<<"EOM");
HTTP/1.0 200 OK
Content-Type: text/html

<rss><channel><pubDate>HEYO</pubDate></channel></rss>
EOM

my $mock_ua = Test::MockObject->new;
$mock_ua->set_always( 'get', Mojo::Transaction->new->res( $message_res ) );

my $rf = Rss::Filter->new( ua => $mock_ua, storage => 'Mock::Feed::Storage' );

my $fake_group = {
    group => 'BoneyM',
    feeds => [
        {
            'The Time is Right' => 'http://boney.m/',
        },
    ],
    match     => [ 'AlwaysMatch' ],
    ifMatched => 'ReplaceItemWithHello',
};

$rf->update_feed( $fake_group, { 'The Time is Right' => 'http://boney.m/' } );

ok( 1, 'hello' );

done_testing;
