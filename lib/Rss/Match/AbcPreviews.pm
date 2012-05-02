use strict;
use warnings;
use feature qw( :5.14 );

package Rss::Match::AbcPreviews {
    use Method::Signatures;
    method match ( $item ) {
        return $item->guid->text =~ / preview /xms;
    }
}

1;