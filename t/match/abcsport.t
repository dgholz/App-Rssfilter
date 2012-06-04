use Test::Most;

use Rss::Match::AbcSport;
use Mojo::DOM;

throws_ok(
    sub { Rss::Match::AbcSport->match },
    qr/missing required argument/,
    'throws error when not given an item to match'
);

throws_ok(
    sub { Rss::Match::AbcSport->match( qw( one two ) ) },
    qr/too many arguments/,
    'throws error when given more than one argument'
);

is(
    Rss::Match::AbcSport->match( Mojo::DOM->new( '<category>Sport</category>' ) ),
    1,
    'match item categorised as "Sport"'
);

isnt(
    Rss::Match::AbcSport->match( Mojo::DOM->new( '<category>Entertainment</category>' ) ),
    1,
    'does not match item which is not categorised as "Sport"'
);

done_testing;
