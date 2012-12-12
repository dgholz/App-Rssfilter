# ABSTRACT: Apply the same Rules to a collection of RSS Feeds

=head1 SYNOPSIS

    use App::RssFilter::Group;

    my $new_group = App::RssFilter::Group->new( name => 'news' );
    $news_group->add_group( 'USA' );
    my $uk_news_group = $news_group->add_group( 'UK' );

    my $dupe_rule = $news_group->group( 'USA' )->add_rule( Duplicate => 'DeleteItem' );
    $uk_news_group->add_rule( match => 'Category[Politics]', filter => 'MarkTitle' );
    $uk_news_group->add_rule( $dupe_rule );

    $news_group->group( 'USA' )->add_feed( WashPost => 'http://feeds.washingtonpost.com/rss/national' );
    $news_group->group( 'USA' )->add_feed( name => 'NYTimes', url => 'http://www.nytimes.com/services/xml/rss/nyt/HomePage.xml' );

    $uk_news_group->add_feed( $news_group->group( 'USA' )->feed( 'WashPost' ) );

    $news_group->update;

=head1 DESCRIPTION

=cut

use strict;
use warnings;
use feature qw< :5.14 >;

package App::Rssfilter::Group {
    use Moo;
    use Method::Signatures;

=method name()

Returns the name passed to the constructor, or '.' if no name passed.

=cut

    has name => (
        is => 'ro',
        default => sub { '.' },
    );

=method rules()

Returns an array reference to the list of rules which will be applied to the feeds in this group (and subgroups).

=cut

    has rules => (
        is => 'ro',
        default => sub { [] },
    );

=method add_rule( $rule | %rule_options )

Adds the L<App::Rssfilter::Rule> $rule (or creates a new App::RssFilter::Rule instance from the passed parameters) to the rules.

=cut

    method add_rule( $rule, @rule_options ) {
        use Scalar::Util qw< blessed >;
        if ( ! blessed( $rule ) or ! $rule->isa( 'App::Rssfilter::Rule' ) ) {
            unshift @rule_options, $rule; # restore original @_
            use App::Rssfilter::Rule;
            $rule = App::Rssfilter::Rule->new( @rule_options );
        }

        push $self->rules, $rule;
        return $self;
    }

=method feeds()

Returns an array reference to the list of feeds within this group.

=cut

    has feeds => (
        is => 'ro',
        default => sub { [] },
    );

=method add_feed( $feed | %feed_options )

Takes the existing L<App::Rssfilter::Feed> $feed (or creates a new App::RssFilter::Feed instance from the passed parameters) and adds it to the group.

=cut

    method add_feed( $feed, @feed_options ) {
        use Scalar::Util qw< blessed >;
        if ( ! blessed( $feed ) or ! $feed->isa( 'App::Rssfilter::Feed' ) ) {
            unshift @feed_options, $feed; # restore original @_
            use App::Rssfilter::Feed;
            $feed = App::Rssfilter::Feed->new( @feed_options );
        }

        push $self->feeds, $feed;
        return $feed;
    }

}

1;

=head1 SEE ALSO

=for :list
* L<App::RssFilter::Rule>
* L<App::RssFilter::Feed>
* L<App::RssFilter>

=cut

