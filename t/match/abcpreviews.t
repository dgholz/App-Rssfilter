use Test::Most;

use Rss::Match::AbcPreviews;
use Mojo::DOM;

throws_ok(
    sub { Rss::Match::AbcPreviews->match },
    qr/missing required argument/,
    'throws error when not given an item to match'
);

throws_ok(
    sub { Rss::Match::AbcPreviews->match( qw( one two ) ) },
    qr/too many arguments/,
    'throws error when given more than one item to match'
);

is(
    Rss::Match::AbcPreviews->match( Mojo::DOM->new( '<guid>I am a preview<\guid>' ) ),
    1,
    'match item whose guid contains "preview"'
);

isnt(
    Rss::Match::AbcPreviews->match( Mojo::DOM->new( '<guid>I am a human being<\guid>' ) ),
    1,
    'does not match item whose guid does not contain "preview"'
);

done_testing;
