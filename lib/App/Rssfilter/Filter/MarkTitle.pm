use strict;
use warnings;

# ABSTRACT: add some text to the title of an RSS item

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
            App::Rssfilter::Filter::MarkTitle::filter( $item, 'HELLO' );
          }
        }
    );

    # or with an App::Rssfilter::Rule

    use App::Rssfilter::Rule;
    App::Rssfilter::Rule->new(
        condition => sub { shift =~ m/hello/xms },
        action    => 'MarkTitle[HELLO]',
    )->constrain( $rss );

    # either way
    print $rss->to_xml;

    # <?xml version="1.0" encoding="UTF-8"?>
    # <rss>
    #   <channel>
    #     <item><title>it&#39;s hi time</title><description>hi</description></item>
    #     <item><title>HELLO - here we are again</title><description>hello</description></item>
    #   </channel>
    # </rss>

=head1 DESCRIPTION

This module will add some uppercase text to the title of a L<Mojo::DOM> element. Use this module instead of L<App::Rssfilter::Filter::DeleteItem> when you wish to verify that your matchers are working correctly, as MarkTitle will simply mark the title of matched items with a specific string, or the name of the matching module.

=head1 SEE ALSO

=for :list
* L<App::Rssfilter>
* L<App::Rssfilter::Rule>

=cut

package App::Rssfilter::Filter::MarkTitle;

use Method::Signatures;

=func filter

    App::Rssfilter::Filter::filter( $item, $matcher, $explicit_prefix )

Prefixes C<$item>'s title with C<$explicit_prefix> (or, if not specified, C<$matcher>) in uppercase. When called from L<App::Rssfilter::Rule/constrain>, C<$matcher> will be set to the nice name of the rule's condition, and C<$explicit_prefix> will be the first bracketed argument.

=cut

func filter ( $item, $matcher, $explicit_prefix = $matcher ) {
    $item->title->replace_content(uc($explicit_prefix) ." - ".$item->title->content_xml);
}
1;
