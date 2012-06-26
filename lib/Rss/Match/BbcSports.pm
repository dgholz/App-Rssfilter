use strict;
use warnings;
use feature qw( :5.14 );

package Rss::Match::BbcSports {
    use Method::Signatures;
    func match ( $item ) {
        return $item->guid->text =~ qr{ www [.] bbc [.] co [.] uk / sport [1]? / }xms;
    }
}

1;
