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
$mock_storage->fake_module( 'Mock::Feed::Storage', new => sub { shift; $mock_storage->ctor( @_ ); } );
$mock_storage->set_always( 'ctor', $mock_storage );
$mock_storage->set_always( 'load_existing', Mojo::DOM->new('<call>the doctor</call>' ) );
$mock_storage->set_true( 'save_feed' );

my $message_res = Mojo::Message::Response->new;
$message_res->parse(<<"EOM");
HTTP/1.0 200 OK
Content-Type: text/html

<rss><channel><pubDate>HEYO</pubDate><item>hi</item></channel></rss>
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

my ($name, $args);

($name, $args) = $mock_storage->next_call;
is(
    $name,
    'ctor',
    'a new stored feed was created ...'
);

shift $args; # discard package name
is_deeply(
    { @{ $args } },
    { group_name => 'BoneyM', feed_name => 'The Time is Right', },
    '... with the correct group & feed name'
);

($name, $args) = $mock_storage->next_call;
is(
    $name,
    'load_existing',
    'update_feed loads the previously-saved RSS feed ...'
);

($name, $args) = $mock_ua->next_call;
is(
    $name,
    'get',
    'update_feed always attempts to fetch latest feed ...'
);

shift $args; # discard package name
is(
    @{ $args },
    2,
    '... with two arguments ...'
);

is(
    $args->[0],
    'http://boney.m/',
    '... of which the first is the URL of the feed ...'
);

is_deeply(
    $args->[1],
    { 'If-Modified-Since' => 'Thu, 01 Jan 1970 00:00:00 GMT' },
    '... and the second is the last updated time as an HTTP header'
);

($name, $args) = $mock_storage->next_call;
is(
    $name,
    'save_feed',
    'attempted to save a new feed ...'
);

is(
    $args->[1],
    Mojo::DOM->new(<<"EOM"),
<rss><channel><pubDate>HEYO</pubDate><item>hello</item></channel></rss>
EOM
    '... with the result of filtering the feed fetched from the URL'
);

done_testing;
