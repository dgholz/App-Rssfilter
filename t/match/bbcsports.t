use Test::Most;

use Rss::Match::BbcSports;
use Mojo::DOM;

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
