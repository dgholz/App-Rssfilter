# ABSTRACT: Apply the same Rules to many Feeds

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

This module groups together feeds so that the same rules will be used to constrain them.

Use a group to:

=for :list
* allow a rule which retains state (e.g. L<Duplicates|App::Rssfilter::Match::Duplicates>) to constrain over multiple feeds
* apply the same rules configuration to multiple feeds

=cut

use strict;
use warnings;
use feature qw< :5.14 >;

package App::Rssfilter::Group {
    use Moo;
    with 'App::Rssfilter::Logger';
    use Method::Signatures;

    method BUILDARGS( @options ) {
        if( 1 == @options ) {
            unshift @options, 'name';
        }
        return { @options };
    }

=attr name

This is the name of the group. Group names are used when storing a feed so that feeds from the same group are kept together. The default value is '.' (a single period).

=cut

    has name => (
        is => 'ro',
        default => sub { '.' },
    );

=attr storage

This is the an instance of a feed storage implementation for feeds to use when they are updated. The default value is a freshly-instance of L<App::Rssfilter::Feed::Storage>. The default is not used when updating subgroups; see L</update> for more details.

=cut

    has storage => (
        is => 'ro',
        default => method { App::Rssfilter::Feed::Storage->new },
    );

=attr groups

This is an arrayref of subgroups attatched to this group.

=cut

    has groups => (
        is => 'ro',
        default => sub { [] },
    );

=method add_group

    $group = $group->add_group( $app_rssfilter_group | %group_options );

Adds $app_rssfilter_group (or creates a new App::RssFilter::Group instance from the C<%group_options>) to the list of subgroups for this group. Returns this group (for chaining).

=cut

    method add_group( $app_rssfilter_group, @group_options ) {
        use Scalar::Util qw< blessed >;
        if ( ! blessed( $app_rssfilter_group ) or ! $app_rssfilter_group->isa( 'App::Rssfilter::Group' ) ) {
            unshift @group_options, $app_rssfilter_group; # restore original @_
            $app_rssfilter_group = App::Rssfilter::Group->new( @group_options );
        }

        push $self->groups, $app_rssfilter_group;
        return $self;
    }

=attr rules

This is an arrayref of rules to apply to the feeds in this group (and subgroups).

=cut

    has rules => (
        is => 'ro',
        default => sub { [] },
    );

=method add_rule

    $group = $group->add_rule( $app_rssfilter_rule | %rule_options )

Adds $app_rssfilter_rule (or creates a new App::RssFilter::Rule instance from the C<%rule_options>) to the list of rules for this group. Returns this group (for chaining). 

=cut

    method add_rule( $app_rssfilter_rule, @rule_options ) {
        use Scalar::Util qw< blessed >;
        if ( ! blessed( $app_rssfilter_rule ) or ! $app_rssfilter_rule->isa( 'App::Rssfilter::Rule' ) ) {
            unshift @rule_options, $app_rssfilter_rule; # restore original @_
            use App::Rssfilter::Rule;
            $app_rssfilter_rule = App::Rssfilter::Rule->new( @rule_options );
        }

        push $self->rules, $app_rssfilter_rule;
        return $self;
    }

=attr feeds

This is an arrayref of feeds.

=cut

    has feeds => (
        is => 'ro',
        default => sub { [] },
    );

=method add_feed

    $group = $group->add_feed( $app_rssfilter_feed | %feed_options );

Adds $app_rssfilter_feed (or creates a new App::RssFilter::Feed instance from the C<%feed_options>) to the list of feeds for this group. Returns this group (for chaining).

=cut

    method add_feed( $app_rssfilter_feed, @feed_options ) {
        use Scalar::Util qw< blessed >;
        if ( ! blessed( $app_rssfilter_feed ) or ! $app_rssfilter_feed->isa( 'App::Rssfilter::Feed' ) ) {
            unshift @feed_options, $app_rssfilter_feed; # restore original @_
            use App::Rssfilter::Feed;
            $app_rssfilter_feed = App::Rssfilter::Feed->new( @feed_options );
        }

        push $self->feeds, $app_rssfilter_feed;
        return $app_rssfilter_feed;
    }

=method update

    $group->update( rules => $rules, storage => $storage );

Recursively calls C<update> on the feeds and subgroups of this group.

C<$rules> is an arrayref of additional rules to constrain the feed and groups, in addition to the group's current list of rules.

C<$storage> is a feed storage instance for children to use when loading or saving feeds. It defaults to this group's C<storage>. The group's C<name> is appended to the current path of C<$storage> before feeds and subgroups use it for updating.

=cut

    method update( ArrayRef :$rules = [], :$storage = $self->storage ) {
        my $child_storage = $storage->path_push( $self->name );
        my @rules = map { @{ $_ } } $rules, $self->rules;
        $self->logger->debugf( 'filtering feeds in %s', $self->name );
        $_->update( rules => \@rules, storage => $child_storage ) for @{ $self->groups };
        $_->update( rules => \@rules, storage => $child_storage ) for @{ $self->feeds };
    }

}

1;

=head1 SEE ALSO

=for :list
* L<App::RssFilter::Rule>
* L<App::RssFilter::Feed>
* L<App::RssFilter>

=cut

