# ABSTRACT: match an RSS item by category

use strict;
use warnings;

=head1 SYNOPSIS

    use App::Rssfilter::Match::Category;

    use Mojo::DOM;
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

    print $_, "\n" for $rss->find( 'item' )->grep(
        sub {
            App::Rssfilter::Match::Category::match( shift, 'Sport' ) ) {
        }
    );

    # or with an App::Rssfilter::Rule

    use App::Rssfilter::Rule;
    App::Rssfilter::Rule->new(
        condition => 'Category[Sport]',
        action    => sub { print shift->to_string, "\n" },
    )->constrain( $rss );

    # either way, prints

    # <item>
    #   <title>Jumping jackrabbit smash long jump record</title>
    #   <category>Sport:leporine</category>
    # </item>

=head1 DESCRIPTION

This module will match an RSS item if it has one or more specific category.

=head1 SEE ALSO

=for :list
* L<App::Rssfilter>
* L<App::Rssfilter::Rule>

=cut

package App::Rssfilter::Match::Category;

use Method::Signatures;
use List::MoreUtils qw( any );

=func match

    my $item_has_category = App::Rssfilter::Match::Category::match( $item, @categories );

Returns true if C<$item> has a category which matches any of C<@categories>. Since some RSS feeds specify categories & subcategories as 'C<main category:subcategory>', elements of C<@categories> can be:

=for :list
* C<category> - this category, with any subcategory
* C<category:subcategory> - only this category with this subcategory
* C<:subcategory> - any category with a matching subcategory

=cut

func match ( $item, @bad_cats ) {
    my @categories = $item->find("category")->map( sub { $_->text } )->each;
    my @split_categories = map { ( / \A ( [^:]+ ) ( [:] .* ) \z /xms, $_ ) } @categories;
    my %cats = map { $_ => 1 } @split_categories;
    return List::MoreUtils::any { defined $_ } @cats{ @bad_cats };
}

1;
