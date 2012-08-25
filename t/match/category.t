use Test::Most;

use Rss::Match::Category;
use Mojo::DOM;

throws_ok(
    sub { Rss::Match::Category::match },
    qr/missing required argument/,
    'throws error when not given an item to match'
);

lives_ok(
    sub { Rss::Match::Category::match( Mojo::DOM->new( '<category>Sport</category>' ) ) },
    'no error thrown when given an item to match and no categories'
);

ok(
    ! Rss::Match::Category::match( Mojo::DOM->new( '<category>Sport</category>' ) ),
    'does not match item when no categories specified'
);

ok(
    Rss::Match::Category::match( Mojo::DOM->new( '<category>Stationary</category>' ), 'Stationary' ),
    'match item categorised as the specified catergory'
);

ok(
    Rss::Match::Category::match( Mojo::DOM->new( '<category>Stationary:pen</category>' ), 'Stationary' ),
    'disregard subcategory when considering categories'
);

ok(
    Rss::Match::Category::match( Mojo::DOM->new( '<category>Stationary</category><category>Refinery</category>' ), 'Refinery' ),
    'match specified category to item with multiple categories'
);

ok(
    Rss::Match::Category::match( Mojo::DOM->new( '<category>Refinery</category>' ), 'Stationary', 'Refinery' ),
    'match item categorised as any of multiple specified categories'
);

ok(
    ! Rss::Match::Category::match( Mojo::DOM->new( '<category>Stationary</category>' ), 'Refinery' ),
    'does not match item not categorised as the specified catergory'
);

ok(
    ! Rss::Match::Category::match( Mojo::DOM->new( '<category>Stationary</category>' ), 'Refinery', 'Lottery' ),
    'does not match item not categorised as any of multiple specified catergories'
);

ok(
    ! Rss::Match::Category::match( Mojo::DOM->new( '<category>Stationary:pen</category>' ), 'pen' ),
    'does not match item whose subcategory matches the specified catergory'
);

ok(
    Rss::Match::Category::match( Mojo::DOM->new( '<category>Stationary:pen</category>' ), ':pen' ),
    'disregard category when considering subcategories'
);

ok(
    ! Rss::Match::Category::match( Mojo::DOM->new( '<category>Stationary:pen</category>' ), ':Stationary' ),
    'does not match item whose category matches the specified subcatergory'
);

ok(
    ! Rss::Match::Category::match( Mojo::DOM->new( '<category>Stationary:pen</category>' ), 'Stationary:pencil' ),
    'does not match item whose category:subcategory does not match the specified category:subcatergory'
);

ok(
    Rss::Match::Category::match( Mojo::DOM->new( '<category>Stationary:pencil</category>' ), 'Stationary:pencil' ),
    'match item whose category:subcategory matches the specified category:subcatergory'
);

done_testing;
