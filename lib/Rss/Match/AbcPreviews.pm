use strict;
use warnings;
use feature qw( :5.14 );

# ABSTRACT: match an ABC preview article

=head1 SYNOPSIS

    use App::Rssfilter;
    use YAML::XS;

    App::Rssfilter->run( Load(<<"End_of_Config") );
    groups:
    - group: ABC
      match:
      - AbcPreviews
      ifMatched: DeleteItem
      feeds:
      - Top Stories: http://www.abc.net.au/news/feed/45910/rss.xml
    End_of_Config

    # or manually

    use Mojo::DOM;
    use Rss::Match::AbcPreviews;

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

    $rss->find( 'item' )->each(
        sub {
          my $item = shift;
          if( Rss::Match::AbcPreviews::match( $item ) ) {
            say $item->guid->text, " is a preview article";
          }
        }
    );

    # prints
    # http://www.abc.net.au/preview/some_article is a preview article

=head1 DESCRIPTION

L<Rss::Match::AbcPreviews> will match a Mojo::DOM element if its GUID contains 'preview' (unless it is also in the title of the item). The Australian Broadcasting Corporation occasionally include links to preview articles in their feeds, which link to non-existent pages.

You should use this module by specifying it under a group's 'match' section in your L<App::Rssfilter> configuration.

=head1 SEE ALSO

=for :list
* L<App::Rssfilter>
* L<Rss::Match::AbcSport>
* L<Rss::Match::BbcSports>
* L<Rss::Match::Category>
* L<Rss::Match::Duplicates>

=cut

package Rss::Match::AbcPreviews {
    use Method::Signatures;

=func match( $item )

Returns true if $item contains 'preview' in its GUID and not in its title.

=cut

    func match ( $item ) {
        return $item->guid->text =~ / [^-] preview /xms and $item->title->text !~ / preview /ixms;
    }
}

1;
