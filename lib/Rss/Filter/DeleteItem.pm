use strict;
use warnings;
use feature qw( :5.14 );

# ABSTRACT: removes a Mojo::DOM element from its parent element

=head1 SYNOPSIS

  use App::rssfilter;
  use YAML::XS;

  App::Rssfilter->run( Load(<<"End_of_Config") );
  groups:
  - group: YoyoDyne
    match:
    - Duplicates
    ifMatched: Rss::Filter::DeleteItem
    feeds:
    - YoyoDyne News:    http://yoyodyne.com/news.rss
    - YoyoDyne Stories: http://yoyodyne.com/stories.rss
  End_of_Config

  # or manually

  use Mojo::DOM;
  use Rss::Filter::DeleteItem;

  my $rss = Mojo::DOM->new( <<"End_of_RSS" );
  <rss>
    <channel>
      <item>hi</item>
      <item>hello</item>
    </channel>
  </rss>
  End_of_RSS

  $rss->find( 'item' )->each(
      sub {
        my $item = shift;
        if( $item =~ /hello/ ) {
          Rss::Filter::DeleteItem::filter( $item, 'manual match' );
        }
      }
  );

  print $rss;
  # "<rss><channel><item>hi</item></channel></rss>"

=head1 DESCRIPTION

L<Rss::Filter::DeleteItem> will remove an element from its parent element. You should specify this module in your configuration passed to L<App::Rssfilter>.

=head1 SEE ALSO

=for :list
* L<App::Rssfilter>
* L<Rss::Filter::MarkTitle>

=cut

package Rss::Filter::DeleteItem {
    use Method::Signatures;

=func filter

Removes element from its parent. The second arguemnt specifies what caused the item to be removed, and is ignored.

=cut
    func filter ( $item, $matcher ) {
        $item->replace(q{});
    }
}

1;
