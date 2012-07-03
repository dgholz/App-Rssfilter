use Test::Most;

use Rss::Filter;

package Rss::Match::AlwaysMatch {
    sub match {
        !!1;
    }
};

package Rss::Match::NeverMatch {
    sub match {
        !!0;
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

for my $meth ( map { "_build_$_" } qw< logger filters matchers > ) {
    throws_ok(
        sub { $rf->$meth( qw< one > ) },
        qr/too many arguments/,
        "$meth does not accept any arguments"
    );
}

throws_ok(
    sub { Rss::Filter::prep_plugins },
    qr/missing required argument/,
    'throws error when not given a method name to check that plugins can perform'
);

throws_ok(
    sub { $rf->filter_items },
    qr/missing required argument/,
    'throws error when not given a feed to filter'
);

throws_ok(
    sub { $rf->filter_items( Mojo::DOM->new( '<item>hi</item>' ) ) },
    qr/missing required argument/,
    'throws error when not given a filter to apply to matching items'
);

is(
    $rf->filter_items( Mojo::DOM->new( '<item>hi</item>' ), 'Rss::Filter::test', 'Rss::Match::AlwaysMatch'),
    '<item>hello</item>',
    'filters matching items'
);

is(
    $rf->filter_items( Mojo::DOM->new( '<item>hi</item>' ), 'Rss::Filter::test', 'Rss::Match::NeverMatch'),
    '<item>hi</item>',
    'does not filter items which are not matched'
);

is(
    $rf->filter_items( Mojo::DOM->new( '<item>hi</item>' ), 'test', 'Rss::Match::AlwaysMatch'),
    '<item>hello</item>',
    'assumes Rss::Filter namespace if no explicit namespace given for filter'
);

is(
    $rf->filter_items( Mojo::DOM->new( '<item>hi</item>' ), 'Rss::Filter::test', 'AlwaysMatch'),
    '<item>hello</item>',
    'assumes Rss::Match namespace if no explicit namespace given for matchers'
);

is(
    $rf->filter_items( Mojo::DOM->new( '<item>hi</item>' ), 'Rss::Filter::test' ),
    '<item>hi</item>',
    'do nothing when no matchers given'
);

is(
    $rf->filter_items( Mojo::DOM->new( '<item>hi</item>' ), 'Rss::Filter::test', 'Rss::Match::I_Do_Not_Exist'),
    '<item>hi</item>',
    'does not match when given non-existent matchers'
);

is(
    $rf->filter_items( Mojo::DOM->new( '<item>hi</item>' ), 'Rss::Filter::I_Do_Not_Exist', 'Rss::Match::AlwaysMatch'),
    '<item>hi</item>',
    'does not filter when given non-existent filter'
);

for my $meth ( map { "update_$_" } qw< group feed > ) {
    throws_ok(
        sub { $rf->$meth },
        qr/missing required argument/,
        "$meth throws error when not given a group to update"
    );
}

throws_ok(
    sub { $rf->update_group( qw< one two > ) },
    qr/too many arguments/,
    'update_group throws error when given more than a single group to update'
);

throws_ok(
    sub { $rf->update_feed( qw< one > ) },
    qr/missing required argument/,
    'update_feed throws error when given only a group and no feed to update'
);

throws_ok(
    sub { $rf->update_feed( qw< one two three > ) },
    qr/too many arguments/,
    'update_feed throws error when given more than a single feed in a group to update'
);

done_testing;
