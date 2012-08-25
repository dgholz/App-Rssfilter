use strict;
use warnings;
use feature qw( :5.14 );

# ABSTRACT: match an RSS item by category

=head1 SYNOPSIS

    use App::Rssfilter;
    use YAML::XS;

    App::Rssfilter->run( Load(<<"End_of_Config") );
    groups:
    - group: ABC
      match:
      - Category[Sport]
      ifMatched: DeleteItem
      feeds:
      - Top Stories: http://www.abc.net.au/news/feed/45910/rss.xml
    End_of_Config

    # or manually

    use Mojo::DOM;
    use Rss::Match::Category;

    my $rss = Mojo::DOM->new( <<"End_of_RSS" );
<?xml version="1.0" encoding="UTF-8"?>
<rss>
  <channel>
    <item>
      <title>Jumping jackrabbit smash long jump record</title>
      <category>Sport:leporine</category>
    </item>
    <item>
      <title>Online poll proves programmers cool, successful</title>
      <category>Internet:very_real_and_official</category>
    </item>
  </channel>
</rss>
    End_of_RSS

    $rss->find( 'item' )->each(
        sub {
          my $item = shift;
          if( Rss::Match::Category::match( $item, 'Sport' ) ) {
            say $item->title->text, " is a sport article";
          }
        }
    );

    # prints
    # Jumping jackrabbit smash long jump record is a sport article

=head1 DESCRIPTION

L<Rss::Match::Category> will match a Mojo::DOM element if it has a category which matches one of the specified categories.

You should use this module by specifying it under a group's 'match' section in your L<App::R-
=head1 SEE ALSO

=for :list
* L<App::Rssfilter>
* L<Rss::Match::AbcPreviews>
* L<Rss::Match::BbcSports>
* L<Rss::Match::Duplicates>

=cut

package Rss::Match::Category {
    use Method::Signatures;
    use List::MoreUtils qw( any );

=func match( $item, @categories )

Returns true if $item has a category which matches any of @categories. Categories can be specified as:
=for :list
* Category - this category, with any subcategory
* Category:subcategory - only this category with this subcategory
* :subcategory - any category with a matching subcategory

=cut

    func match ( $item, @bad_cats ) {
        my @categories = $item->find("category")->map( sub { $_->text } )->each;
        my @split_categories = map { ( / \A ( [^:]+ ) ( [:] .* ) \z /xms, $_ ) } @categories;
        my %cats = map { $_ => 1 } @split_categories;
        return List::MoreUtils::any { defined $_ } @cats{ @bad_cats };
    }
}

1;
