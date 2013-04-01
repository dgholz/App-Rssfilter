use strict;
use warnings;
use feature qw( :5.14 );

# ABSTRACT: remove a Mojo::DOM element from its parent element

=head1 SYNOPSIS

    use App::Rssfilter;
    use YAML::XS;

    App::Rssfilter->run( Load(<<"End_of_Config") );
    groups:
    - group: YoyoDyne
      match:
      - Duplicates
      ifMatched: DeleteItem
      feeds:
      - YoyoDyne News:    http://yoyodyne.com/news.rss
      - YoyoDyne Stories: http://yoyodyne.com/stories.rss
    End_of_Config

    # or manually

    use Mojo::DOM;
    use App::Rssfilter::Filter::DeleteItem;

    my $rss = Mojo::DOM->new( <<"End_of_RSS" );
<?xml version="1.0" encoding="UTF-8"?>
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
            App::Rssfilter::Filter::DeleteItem::filter( $item, 'manual match' );
          }
        }
    );

    print $rss;
    # <?xml version="1.0" encoding="UTF-8"?>
    #  <rss>
    #    <channel>
    #      <item>hi</item>
    #    </channel>
    #  </rss>

=head1 DESCRIPTION

L<App::Rssfilter::Filter::DeleteItem> will remove a L<Mojo::DOM> element from its parent element.

You should use this module by specifying it as a group's 'ifMatched' action in your L<App::Rssfilter> configuration.

=head1 SEE ALSO

=for :list
* L<App::Rssfilter>
* L<App::Rssfilter::Filter::MarkTitle>

=cut

package App::Rssfilter::Filter::DeleteItem {
    use Method::Signatures;

=func filter

   App::Rssfilter::Filter::DeleteItem::filter( $item, $matcher );

Removes C<$item> from its parent and discards it. C<$matcher> is an optional string specifying the condition which caused $item to be removed, and is ignored--it exists solely so that L<App::Rssfilter::Rule/constrain> can set it to the name of the condition causing the match.

=cut

    func filter ( $item, $matcher = 'no reason' ) {
        $item->replace(q{});
    }
}

1;
