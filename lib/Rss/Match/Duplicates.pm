use strict;
use warnings;
use feature qw( :5.14 );

package Rss::Match::Duplicates {
    use Method::Signatures;
    use Try::Tiny;
    func match ( $item ) {
        state %prev;
        my $link = try { $item->guid->text } || "";
        my $url  = try { $item->link->text =~ s/ [?] .* \z//xmsr } || "";
        my @matchables = grep { $_ ne "" } $link, $url;
        my $res  = grep { defined } @prev{ @matchables };
        @prev{ @matchables } = ( 1 ) x @matchables;
        return 0 < $res;
    }
}

1;
