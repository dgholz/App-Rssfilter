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
$mock_storage->fake_new(    'Mock::Feed::Storage' );
$mock_storage->set_always( 'load_existing', Mojo::DOM->new(<<"EOM") );
<rss><channel><pubDate>Mon, 06 Aug 2012 00:06:00 GMT</pubDate><item>hi</item></channel></rss>
EOM

my $message_res = Mojo::Message::Response->new;
$message_res->parse(<<"EOM");
HTTP/1.0 304 Not Modified
Date: Sun, 05 Aug 2012 10:34:56 GMT
EOM

my $mock_ua = Test::MockObject->new;
$mock_ua->set_always( 'get', Mojo::Transaction->new->res( $message_res ) );

my $rf = Rss::Filter->new( ua => $mock_ua, storage => 'Mock::Feed::Storage' );
use Log::Log4perl qw< :levels >;
$rf->logger->level( $OFF );

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

my ($name, $args) = $mock_ua->next_call;

is_deeply(
    $args->[2],
    { 'If-Modified-Since' => 'Mon, 06 Aug 2012 00:06:00 GMT' },
    'passes pubDate or lastBuildDate from stored feed in HTTP header'
);

ok(
    ! $mock_storage->called( 'save_feed' ),
    'did not attempted to save an unmodifeid feed'
);

done_testing;
