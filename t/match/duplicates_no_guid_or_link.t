use Test::Most;

use Rss::Match::Duplicates;
use Mojo::DOM;

lives_ok {
    Rss::Match::Duplicates::match( Mojo::DOM->new( '<?xml version="1.0"?><link>butterfly</link>' ) ),
} 'no error thrown when no guid in item';

lives_ok {
    Rss::Match::Duplicates::match( Mojo::DOM->new( '<?xml version="1.0"?><guid>snowflake</guid>' ) ),
} 'no error thrown when no link in item';

done_testing;
