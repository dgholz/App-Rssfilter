# ABSTRACT: match a BBC sport RSS item

use strict;
use warnings;

=head1 SYNOPSIS

    use App::Rssfilter::Match::BbcSports;

    use Mojo::DOM;
    my $rss = Mojo::DOM->new( <<"End_of_RSS" );
<?xml version="1.0" encoding="UTF-8"?>
<rss>
  <channel>
    <item>
      <guid>http://www.bbc.co.uk/sport/some_article</guid>
      <description>here is an article about a sporting event</description>
    </item>
    <item>
      <guid>http://www.bbc.co.uk/tech/new_rss_tool_changes_how_we_read_news</guid>
      <description>here is an article about an rss tool</description>
    </item>
  </channel>
</rss>
End_of_RSS

    print $_, "\n" for $rss->find( 'item' )->grep( \&App::Rssfilter::Match::BbcSports::match );

    # or with an App::Rssfilter::Rule

    use App::Rssfilter::Rule;
    App::Rssfilter::Rule->new(
        condition => 'BbcSports',
        action    => sub { print shift->to_xml, "\n" },
    )->constrain( $rss );

    # either way, prints
    
    # <item>
    #   <guid>http://www.bbc.co.uk/tech/new_rss_tool_changes_how_we_read_news</guid>
    #   <description>here is an article about an rss tool</description>
    # </item>

=head1 DESCRIPTION

This module will match items from BBC RSS feeds which are about sporting events.

=head1 SEE ALSO

=for :list
* L<App::Rssfilter>
* L<App::Rssfilter::Rule>

=cut

package App::Rssfilter::Match::BbcSports;
use Method::Signatures;

=func match

    my $item_is_BBC_sport = App::Rssfilter::Match::BbcSports::match( $item );

Returns true if ther GUID of C<$item> looks like a BBC sport GUID (like C<http://www.bbc.co.uk/sport>).

=cut

func match ( $item ) {
    return $item->guid->text =~ qr{ www [.] bbc [.] co [.] uk / sport [1]? / }xms;
}

1;
