use Test::Most;

use Rss::Match::AbcSport;
use Mojo::DOM;

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
