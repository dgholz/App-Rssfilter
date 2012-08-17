use strict;
use warnings;
use feature qw( :5.14 );

package Rss::Match::AbcPreviews {
    use Method::Signatures;
    func match ( $item ) {
        return $item->guid->text =~ / [^-] preview /xms and $item->title->text !~ / preview /ixms;
    }
}

1;
