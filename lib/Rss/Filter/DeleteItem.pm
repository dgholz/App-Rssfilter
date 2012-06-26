use strict;
use warnings;
use feature qw( :5.14 );

package Rss::Filter::DeleteItem {
    use Method::Signatures;
    func filter ( $item, $matcher ) {
        $item->replace(q{});
    }
}

1;
