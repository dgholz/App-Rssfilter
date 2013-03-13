use strict;
use warnings;
use feature qw( :5.14 );

# ABSTRACT: match an article which has been seen before

=head1 SYNOPSIS

    use App::Rssfilter;
    use YAML::XS;

    App::Rssfilter->run( Load(<<"End_of_Config") );
    groups:
    - group: ABC
      match:
      - Duplicates
      ifMatched: DeleteItem
      feeds:
      - NSW: http://www.abc.net.au/news/feed/52498/rss.xml
      - Top Stories: http://www.abc.net.au/news/feed/45910/rss.xml
    End_of_Config

    # or manually

    use Mojo::DOM;
    use App::Rssfilter::Match::Duplicates;

    my $first_rss = Mojo::DOM->new( <<"End_of_RSS" );
<?xml version="1.0" encoding="UTF-8"?>
<rss>
  <channel>
    <item>
      <link>http://rss.slashdot.org/~r/Slashdot/slashdot/~6/gu7UEWn8onK/is-typing-tiring-your-toes</link>
      <description>type with toes for tighter tarsals</description>
    </item>
    <item>
      <link>http://rss.slashdot.org/~r/Slashdot/slashdot/~9/lloek9InU2p/new-planet-discovered-on-far-side-of-sun</link>
      <description>vulcan is here</description>
    </item>
  </channel>
</rss>
    End_of_RSS

    my $second_rss = Mojo::DOM->new( <<"End_of_RSS" );
<?xml version="1.0" encoding="UTF-8"?>
<rss>
  <channel>
    <item>
      <link>http://rss.slashdot.org/~r/Slashdot/slashdot/~3/mnej39gJa9E/new-rocket-to-visit-mars-in-60-days</link>
      <description>setting a new speed record</description>
    </item>
    <item>
      <link>http://rss.slashdot.org/~r/Slashdot/slashdot/~9/lloek9InU2p/new-planet-discovered-on-far-side-of-sun</link>
      <description>vulcan is here</description>
    </item>
  </channel>
</rss>
    End_of_RSS

    $first_rss->find( 'item' )->each(
        sub {
          my $item = shift;
          if( App::Rssfilter::Match::Duplicates::match( $item ) ) {
            say $item->link->text, " is a duplicate article";
          }
        }
    );

    $second_rss->find( 'item' )->each(
        sub {
          my $item = shift;
          if( App::Rssfilter::Match::Duplicates::match( $item ) ) {
            say $item->link->text, " is a duplicate article";
          }
        }
    );

    # prints
    # http://rss.slashdot.org/~r/Slashdot/slashdot/~9/lloek9InU2p/new-planet-discovered-on-far-side-of-sun is a duplicate article

=head1 DESCRIPTION

L<App::Rssfilter::Match::Duplicates> will record the GUID and link of a Mojo::DOM element, and then match the element if either the GUID or link have previously been recorded.

You should use this module by specifying it under a group's 'match' section in your L<App::Rssfilter> configuration.

=head1 SEE ALSO

=for :list
* L<App::Rssfilter>
* L<App::Rssfilter::Match::AbcPreviews>
* L<App::Rssfilter::Match::BbcSports>
* L<App::Rssfilter::Match::Category>

=cut

package App::Rssfilter::Match::Duplicates {
    use Method::Signatures;
    use Try::Tiny;

=func match( $item )

Returns true if $item has a guid or link which matches a guid of link of an item previously processed. Query strings in the link of the $item will be ignore for the purposes of matching a previous link.

=cut

    func match ( $item ) {
        state %prev;
        my $link = try { $item->guid->text =~ s/ [?] .* \z //xmsr } || "";
        my $url  = try { $item->link->text =~ s/ [?] .* \z //xmsr } || "";
        my @matchables = grep { $_ ne "" } $link, $url;
        my $res  = grep { defined } @prev{ @matchables };
        @prev{ @matchables } = ( 1 ) x @matchables;
        return 0 < $res;
    }
}

1;
