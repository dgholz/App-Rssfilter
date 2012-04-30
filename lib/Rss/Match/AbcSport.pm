use strict;
use warnings;
use feature qw( :5.14 );
use Rss::Match::Category;

package Rss::Match::AbcSport {
    use Method::Signatures;
    method match ( $item ) {
        return Rss::Match::Category->match( $item, 'Sport' );
    }

}

1;
