use strict;
use warnings;
# ABSTRACT: remove clutter from your news feeds

=head1 SYNOPSIS

    $ rssfilter runfromconfig Rssfilter.yaml

OR

    use Role::Tiny;
    use YAML::XS;

    my $rssfilter = Role::Tiny->create_class_with_roles( 'App::Rssfilter::Group', 'App::Rssfilter::FromHash');
    $rssfilter->from_hash( Load( <<"End_Of_Config" ) )->update();
    name: My Feeds
    rules:
    - Duplicates: DeleteItem
    groups:
    - name: News
      feeds:
      - Cool News: http://cool.net/latest.rss
      - Hot News: http://hot.com/top-stories.rss
      rules:
      - Category[Examples]: MarkTitle[IGNORE THESE]
    - name: Posts
      feeds:
      - Fence Blog: http://fence.com/entries.rss
      - The Mail Man: http://mail.org/posts.rss
      rules:
      - MyCustomMatcher: DeleteItem
    End_Of_Config

=head1 DESCRIPTION

App::Rssfilter downloads RSS feeds and then applies rules to remove duplicate items, mark the titles of certain types of items, and more!

=head1 EXTENDING



=head1 SEE ALSO

=for :list
* L<Yahoo Pipes|http://pipes.yahoo.com/pipes/>

=cut

package App::Rssfilter {
    use Moo;
    extends 'App::Rssfilter::Group';
};

1;
