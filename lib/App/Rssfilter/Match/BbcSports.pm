use strict;
use warnings;
use feature qw( :5.14 );

# ABSTRACT: match a BBC sport article

=head1 SYNOPSIS

    use App::Rssfilter;
    use YAML::XS;

    App::Rssfilter->run( Load(<<"End_of_Config") );
    groups:
    - group: BBC
      match:
      - BbcSports
      ifMatched: DeleteItem
      feeds:
      - Front Page: http://newsrss.bbc.co.uk/rss/sportonline_uk_edition/front_page/rss.xml
    End_of_Config

    # or manually

    use Mojo::DOM;
    use App::Rssfilter::Match::BbcSports;

    my $rss = Mojo::DOM->new( <<"End_of_RSS" );
<?xml version="1.0" encoding="UTF-8"?>
<rss>
  <channel>
    <item>
      <title>Jumping jackrabbit shames long jump record</title>
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
          if( App::Rssfilter::Match::BbcSports::match( $item ) ) {
            say $item->title->text, " is a sport article";
          }
        }
    );

    # prints
    # Jumping jackrabbit smashes long jump record is a sport article

=head1 DESCRIPTION

L<App::Rssfilter::Match::BBcSports> will match an item if it is tagged as belonging to the 'Sport' category.

You should use this module by specifying it under a group's 'match' section in your L<App::Rssfilter> configuration.

=head1 SEE ALSO

=for :list
* L<App::Rssfilter>
* L<App::Rssfilter::Match::AbcPreviews>
* L<App::Rssfilter::Match::Category>
* L<App::Rssfilter::Match::Duplicates>

=cut

package App::Rssfilter::Match::BbcSports {
    use Method::Signatures;

=func match( $item )

Returns true if $item has a GUID which looks like a BBC sport GUID e.g. http://www.bbc.co.uk/sport.

=cut

    func match ( $item ) {
        return $item->guid->text =~ qr{ www [.] bbc [.] co [.] uk / sport [1]? / }xms;
    }
}

1;
