use Test::Most;

use Rss::Match::Category;
use Mojo::DOM;

throws_ok(
    sub { Rss::Match::Category->match },
    qr/missing required argument/,
    'throws error when not given an item to match'
);

is(
    Rss::Match::Category->match( Mojo::DOM->new( '<category>Stationary</category>' ), 'Stationary' ),
    1,
    'match item categorised as the specified catergory'
);

is(
    Rss::Match::Category->match( Mojo::DOM->new( '<category>Stationary:Pen</category>' ), 'Stationary' ),
    1,
    'disregard subcategory when considering categories'
);

is(
    Rss::Match::Category->match( Mojo::DOM->new( '<category>Stationary</category><category>Refinery</category>' ), 'Refinery' ),
    1,
    'match specified category to item with multiple categories'
);

is(
    Rss::Match::Category->match( Mojo::DOM->new( '<category>Refinery</category>' ), 'Stationary', 'Refinery' ),
    1,
    'match item categorised as any of multiple specified categories'
);

isnt(
    Rss::Match::Category->match( Mojo::DOM->new( '<category>Stationary</category>' ), 'Refinery' ),
    1,
    'does not match item not categorised as the specified catergory'
);

isnt(
    Rss::Match::Category->match( Mojo::DOM->new( '<category>Stationary</category>' ), 'Refinery', 'Lottery' ),
    1,
    'does not match item not categorised as any of the multiple specified catergories'
);

isnt(
    Rss::Match::Category->match( Mojo::DOM->new( '<category>Stationary:Pen</category>' ), 'Pen' ),
    1,
    'does not match item whose subcategory matches the specified catergory'
);

done_testing;
