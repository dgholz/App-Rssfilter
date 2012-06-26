use Test::Most;

use Rss::Filter::MarkTitle;
use Mojo::DOM;

throws_ok(
    sub { Rss::Filter::MarkTitle->filter },
    qr/missing required argument/,
    'throws error when not given an item to mark the title of'
);

throws_ok(
    sub { Rss::Filter::MarkTitle->filter( qw( one ) ) },
    qr/missing required argument/,
    'throws error when not given the name of a matcher'
);

throws_ok(
    sub { Rss::Filter::MarkTitle->filter( qw( one two three) ) },
    qr/too many arguments/,
    'throws error when given multiple matchers'
);

is(
    Rss::Filter::MarkTitle->filter( Mojo::DOM->new( '<title>Man Bites Dog</title>' ), 'SensationalHeadline' ),
    '<title>SENSATIONALHEADLINE - Man Bites Dog</title>',
    q{prefixes item's title with uppercase name of matcher}
);

done_testing;
