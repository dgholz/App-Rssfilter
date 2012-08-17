use strict;
use warnings;
use feature qw( :5.14 );
use Rss::Match::Category;

# ABSTRACT: match an RSS item categorised as 'Sport'

=head1 SYNOPSIS

    use App::Rssfilter;
    use YAML::XS;

    App::Rssfilter->run( Load(<<"End_of_Config") );
    groups:
    - group: ABC
      match:
      - AbcSport
      ifMatched: DeleteItem
      feeds:
      - Top Stories: http://www.abc.net.au/news/feed/45910/rss.xml
    End_of_Config

    # or manually

    use Mojo::DOM;
    use Rss::Match::AbcSport;

    my $rss = Mojo::DOM->new( <<"End_of_RSS" );
    <rss>
      <channel>
        <item>
          <title>Jumping jackrabbit smash long jump record</title>
          <category>Sport</category>
        </item>
        <item>
          <title>Online poll proves programmers cool, successful</title>
          <category>Internet</category>
        </item>
      </channel>
    </rss>
    End_of_RSS

    $rss->find( 'item' )->each(
        sub {
          my $item = shift;
          if( Rss::Match::AbcSport::match( $item ) ) {
            say $item->title->text, " is a sport article";
          }
        }
    );

    # prints
    # Jumping jackrabbit smash long jump record is a sport article

=head1 DESCRIPTION

L<Rss::Match::AbcSport> will match a Mojo::DOM element if it categorised as 'Sport'.

You should use this module by specifying it under a group's 'match' section in your L<App::Rssfilter> configuration.

=head1 SEE ALSO

=for :list
* L<App::Rssfilter>
* L<Rss::Match::AbcPreviews>
* L<Rss::Match::BbcSports>
* L<Rss::Match::Category>
* L<Rss::Match::Duplicates>

=cut

package Rss::Match::AbcSport {
    use Method::Signatures;

=func match( $item )

Returns true if $item has a category of 'Sport' or 'Sport:<any subcategory>'.

=cut

    func match ( $item ) {
        return Rss::Match::Category::match( $item, 'Sport' );
    }

}

1;
