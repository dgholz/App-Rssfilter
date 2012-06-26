use strict;
use warnings;
use feature qw( :5.14 );

package Rss::Match::Category {
    use List::MoreUtils qw( any );

    use Method::Signatures;
    func match ( $item, @bad_cats ) {
        my %cats =
          map { $_ => 1 } $item->find("category")->map( sub { $_->text =~ s/:.*$//r } )->each;
        return List::MoreUtils::any { defined $_ } @cats{ @bad_cats };
    }
}

1;
