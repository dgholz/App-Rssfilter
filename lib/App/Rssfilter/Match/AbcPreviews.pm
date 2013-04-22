# ABSTRACT: match an ABC preview RSS item

use strict;
use warnings;

=head1 SYNOPSIS

    use App::Rssfilter::Match::AbcPreviews;
    
    use Mojo::DOM;
    my $rss = Mojo::DOM->new( <<"End_of_RSS" );
<rss>
  <channel>
    <item>
      <guid>http://www.abc.net.au/preview/some_article</guid>
      <description>here is an article which is in preview mode</description>
    </item>
    <item>
      <guid>http://www.abc.net.au/entertainment/new-preview-of-movie</guid>
      <description>here is an article about a preview of a movie</description>
    </item>
  </channel>
</rss>
End_of_RSS

    print $_, "\n" for $rss->find( 'item' )->grep( \&App::Rssfilter::Match::AbcPreviews::match );

    # or with an App::Rssfilter::Rule

    use App::Rssfilter::Rule;
    App::Rssfilter::Rule->new(
        condition => 'AbcPreviews',
        action    => sub { print shift->to_xml, "\n" },
    )->constrain( $rss );

    # either way, prints

    # <item>
    #   <guid>http://www.abc.net.au/preview/some_article</guid>
    #   <description>here is an article which is in preview mode</description>
    # </item>

=head1 DESCRIPTION

This module will match an RSS item if its GUID contains 'C<preview>', unless 'C<preview>' is also in the title of the item. The Australian Broadcasting Corporation RSS feeds occasionally include items whose GUIDS contain 'C<preview>' and link to non-existent pages, so this matcher was created to find them.

=head1 SEE ALSO

=for :list
* L<App::Rssfilter>
* L<App::Rssfilter::Rule>

=cut

package App::Rssfilter::Match::AbcPreviews;
use Method::Signatures;

=func match

    my $item_is_preview = App::Rssfilter::Match::AbcPreviews::match( $item );

Returns true if C<$item> contains 'C<preview>' in its GUID and not in its title.

=cut

func match ( $item ) {
    return $item->guid->text =~ / [^-] preview /xms and $item->title->text !~ / preview /ixms;
}

1;
