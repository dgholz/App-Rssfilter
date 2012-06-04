use Test::Most;

use Rss::Match::BbcSports;
use Mojo::DOM;

throws_ok(
    sub { Rss::Match::BbcSports->match },
    qr/missing required argument/,
    'throws error when not given an item to match'
);

throws_ok(
    sub { Rss::Match::BbcSports->match( qw( one two ) ) },
    qr/too many arguments/,
    'throws error when given more than one argument'
);

is(
    Rss::Match::BbcSports->match( Mojo::DOM->new( '<guid>www.bbc.co.uk/sport/<\guid>' ) ),
    1,
    'match item whose guid contains the BBC sport URL'
);

is(
    Rss::Match::BbcSports->match( Mojo::DOM->new( '<guid>www.bbc.co.uk/sport1/<\guid>' ) ),
    1,
    'match item whose guid contains the variant BBC sport URL'
);

isnt(
    Rss::Match::BbcSports->match( Mojo::DOM->new( '<guid>www.bbc.co.uk/science<\guid>' ) ),
    1,
    'does not match item whose guid does not contains the BBC sport URL'
);

isnt(
    Rss::Match::BbcSports->match( Mojo::DOM->new( '<guid>espn.com/sport<\guid>' ) ),
    1,
    'does not match item whose guid does not contain a BBC URL'
);

done_testing;
