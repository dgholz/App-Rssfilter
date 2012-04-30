use strict;
use warnings;
use feature qw( :5.14 );

package Rss::Match::Dupes {
    use Method::Signatures;
    method match ( $item ) {
        state %prev;
        my $link = $item->guid->text;
        my $url  = $item->link->text =~ s/ [?] .* \z//xmsr;
        my $res  = grep { defined } @prev{ $link, $url };
        @prev{ $link, $url } = ( 1, 1 );
        return 0 < $res;
    }
}

1;
