use strict;
use warnings;
use feature qw( :5.14 );

package Rss::Filter::MarkTitle {
    use Method::Signatures;
    method filter ( $item, $matcher ) {
        $item->title->replace_content(uc($matcher) ." - ".$item->title->content_xml);
    }
}

1;
