use strict;
use warnings;

# ABSTRACT: remove an RSS item from its channel

=head1 SYNOPSIS

    use App::Rssfilter::Filter::MarkTitle;

    use Mojo::DOM;
    my $rss = Mojo::DOM->new( <<"End_of_RSS" );
<?xml version="1.0" encoding="UTF-8"?>
<rss>
  <channel>
    <item><title>it's hi time</title><description>hi</description></item>
    <item><title>here we are again</title><description>hello</description></item>
  </channel>
</rss>
End_of_RSS

    $rss->find( 'item' )->each(
        sub {
          my $item = shift;
          if( $item =~ /hello/ ) {
            App::Rssfilter::Filter::DeleteItem::filter( $item );
          }
        }
    );

    # or with an App::Rssfilter::Rule

    use App::Rssfilter::Rule;
    App::Rssfilter::Rule->new(
        condition => sub { shift =~ m/hello/xms },
        action    => 'DeleteItem',
    )->constrain( $rss );

    # either way
    print $rss->to_string;

    # <?xml version="1.0" encoding="UTF-8"?>
    # <rss>
    #   <channel>
    #     <item><title>it&#39;s hi time</title>hi</item>
    #   </channel>
    # </rss>

=head1 DESCRIPTION

This module will remove an RSS item from its channel. Actually, it will remove any L<Mojo::DOM> element from its parent. Use L<App::Rssfilter::Filter::MarkTitle> for a non-destructive filter.

=head1 SEE ALSO

=for :list
* L<App::Rssfilter>
* L<App::Rssfilter::Rule>

=cut

package App::Rssfilter::Filter::DeleteItem;

use Method::Signatures;

=func filter

    App::Rssfilter::Filter::DeleteItem::filter( $item, $matcher );

Removes C<$item> from its parent and discards it.

C<$matcher> is an optional string specifying the condition which caused C<$item> to be removed, and is ignored; it exists solely so that L<App::Rssfilter::Rule/constrain> can set it to the name of the condition causing the match.

=cut

func filter ( $item, $matcher = 'no reason' ) {
    $item->replace(q{});
}
1;
