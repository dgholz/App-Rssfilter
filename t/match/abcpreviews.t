use Test::Most;

use Rss::Match::AbcPreviews;
use Mojo::DOM;

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
