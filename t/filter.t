use Test::Most;

use Rss::Filter;

package Rss::Match::test {
    sub match {
        1;
    }
};

package Rss::Filter::test {
    sub filter {
        my ( $item, $matcher ) = @_;
        $item->replace_content('hello');
    }
};

package main;

my $rf = Rss::Filter->new( config => { } );
use Log::Log4perl qw< :levels >;
$rf->logger->level( $OFF );

is(
    $rf->filter_items( Mojo::DOM->new( '<item>hi</item>' ), 'Rss::Filter::test', 'Rss::Match::test'),
    '<item>hello</item>',
    'it lives it\'s alive'
);

is(
    $rf->filter_items( Mojo::DOM->new( '<item>hi</item>' ), 'Rss::Filter::test' ),
    '<item>hi</item>',
    'do nothing when no matchers given'
);

done_testing;
