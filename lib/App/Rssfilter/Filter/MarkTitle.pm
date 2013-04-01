use strict;
use warnings;
use feature qw( :5.14 );

# ABSTRACT: add some text to the title element of an RSS item

=head1 SYNOPSIS

    use App::Rssfilter;
    use YAML::XS;

    App::Rssfilter->run( Load(<<"End_of_Config") );
    groups:
    - group: YoyoDyne
      match:
      - Duplicates
      ifMatched: MarkTitle
      feeds:
      - YoyoDyne News:    http://yoyodyne.com/news.rss
      - YoyoDyne Stories: http://yoyodyne.com/stories.rss
    End_of_Config

    # or manually

    use Mojo::DOM;
    use App::Rssfilter::Filter::MarkTitle;

    my $rss = Mojo::DOM->new( <<"End_of_RSS" );
<?xml version="1.0" encoding="UTF-8"?>
<rss>
  <channel>
    <item><title>it's hi time</title>hi</item>
    <item><title>here we are again</title>hello</item>
  </channel>
</rss>
    End_of_RSS

    $rss->find( 'item' )->each(
        sub {
          my $item = shift;
          if( $item =~ /hello/ ) {
            App::Rssfilter::Filter::MarkTitle::filter( $item, 'manual match' );
          }
        }
    );

    print $rss;
    # <?xml version="1.0" encoding="UTF-8"?>
    # <rss>
    #   <channel>
    #     <item><title>it's hi time</title>hi</item>
    #     <item><title>MANUAL MATCH - here we are again</title>hello</item>
    #   </channel>
    # </rss>

=head1 DESCRIPTION

L<App::Rssfilter::Filter::MarkTitle> will add some uppercase text to the title of a L<Mojo::DOM> element. Use this module instead of L<App::Rssfilter::Filter::DeleteItem> when you wish to verify that your matchers are working correctly, as MarkTitle will simply mark the title of matched items with the name of the matching module.

You should use this module by specifying it as a group's 'ifMatched' action in your L<App::Rssfilter> configuration.

=head1 SEE ALSO

=for :list
* L<App::Rssfilter>
* L<App::Rssfilter::Filter::DeleteItem>

=cut

package App::Rssfilter::Filter::MarkTitle {
    use Method::Signatures;

=func filter

    App::Rssfilter::Filter::filter( $item, $matcher, $explicit_prefix )

Prefixes C<$item>'s title with C<$explicit_prefix> (or, if not specified, C<$matcher>) in uppercase. When called from L<App::Rssfilter::Rule/constrain>, C<$matcher> will be set to the nice name of the rule's condition, and C<$explicit_prefix> will be the first bracketed argument.

=cut

    func filter ( $item, $matcher, $explicit_prefix = $matcher ) {
        $item->title->replace_content(uc($explicit_prefix) ." - ".$item->title->content_xml);
    }
}

1;
