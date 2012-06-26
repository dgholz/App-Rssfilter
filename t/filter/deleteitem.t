use Test::Most;

use Rss::Filter::DeleteItem;
use Mojo::DOM;

throws_ok(
    sub { Rss::Filter::DeleteItem::filter },
    qr/missing required argument/,
    'throws error when not given an item to delete'
);

throws_ok(
    sub { Rss::Filter::DeleteItem::filter( qw( one ) ) },
    qr/missing required argument/,
    'throws error when not given the name of a matcher'
);

throws_ok(
    sub { Rss::Filter::DeleteItem::filter( qw( one two three) ) },
    qr/too many arguments/,
    'throws error when given multiple matchers'
);

is(
    Rss::Filter::DeleteItem::filter( Mojo::DOM->new( '<title>Man Bites Dog</title>' ), 'SensationalHeadline' ),
    '',
    'deletes content of item'
);

done_testing;
