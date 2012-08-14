use Test::Most;

use Rss::Match::Duplicates;
use Mojo::DOM;

throws_ok(
    sub { Rss::Match::Duplicates::match },
    qr/missing required argument/,
    'throws error when not given an item to match'
);

throws_ok(
    sub { Rss::Match::Duplicates::match( qw( one two ) ) },
    qr/too many arguments/,
    'throws error when given more than one argument'
);

ok(
    ! Rss::Match::Duplicates::match( Mojo::DOM->new( '<?xml version="1.0"?><guid>snowflake</guid><link>butterfly</link>' ) ),
    'item with guid and link not seen before is not marked as a duplicate'
);

ok(
    ! Rss::Match::Duplicates::match( Mojo::DOM->new( '<?xml version="1.0"?><guid>snowflakes</guid><link>moth</link>' ) ),
    'item with new guid sharing a prefix with previously seen guid is not marked as a duplicate'
);

ok(
    ! Rss::Match::Duplicates::match( Mojo::DOM->new( '<?xml version="1.0"?><guid>raindrop</guid><link>butterfly net</link>' ) ),
    'item with new link sharing a prefix with previously seen link is not marked as a duplicate'
);

ok(
    Rss::Match::Duplicates::match( Mojo::DOM->new( '<?xml version="1.0"?><guid>snowflake</guid><link>butterfly</link>' ) ),
    'item with guid and link seen before is marked as a duplicate'
);

ok(
    Rss::Match::Duplicates::match( Mojo::DOM->new( '<?xml version="1.0"?><guid>coin</guid><link>butterfly</link>' ) ),
    'item with new guid and link seen before is marked as a duplicate'
);

ok(
    Rss::Match::Duplicates::match( Mojo::DOM->new( '<?xml version="1.0"?><guid>snowflake</guid><link>ant</link>' ) ),
    'item with guid seen before and new link is marked as a duplicate'
);

ok(
    ! Rss::Match::Duplicates::match( Mojo::DOM->new( '<?xml version="1.0"?><guid>memoirs</guid><link>confessions</link>' ) ),
    'item with new guid and new link not seen before is not marked as a duplicate'
);

ok(
    Rss::Match::Duplicates::match( Mojo::DOM->new( '<?xml version="1.0"?><guid>justified</guid><link>butterfly?species=sinner</link>' ) ),
    'item with new guid and new link sharing a prefix with a previously seen link after a question mark is marked as a duplicate'
);

done_testing;
