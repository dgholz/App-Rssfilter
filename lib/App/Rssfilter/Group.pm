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

A group runs the same rules over many feeds. Use a group when:

=for :list
* you have a rule which keeps track of items seen (e.g. L<Duplicates|App::Rssfilter::Match::Duplicates>) and you wish it to retain state over muplitple feeds
* you wish to apply the same rules configuration to multiple feeds

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

This is the an instance of a feed storage implementation for feeds to use when they are updated. The default value is a freshly-instance of L<App::Rssfilter::Feed::Storage>. The default is not used when updating subgroups; see L<update > for more details.

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

=method add_group( $group | %group_options )

Adds the L<App::Rssfilter::group> $group (or creates a new App::RssFilter::group instance from the passed parameters) to the list of subgroups for this group.

=cut

    method add_group( $group, @group_options ) {
        use Scalar::Util qw< blessed >;
        if ( ! blessed( $group ) or ! $group->isa( 'App::Rssfilter::Group' ) ) {
            unshift @group_options, $group; # restore original @_
            $group = App::Rssfilter::Group->new( @group_options );
        }

        push $self->groups, $group;
        return $self;
    }

=attr rules

This is an arrayref of rules to apply to the feeds in this group (and subgroups).

=cut

    has rules => (
        is => 'ro',
        default => sub { [] },
    );

=method add_rule( $rule | %rule_options )

Adds the L<App::Rssfilter::Rule> $rule (or creates a new App::RssFilter::Rule instance from the passed parameters) to the rules for this group.

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

=attr feeds

This is an arrayref of feeds.

=cut

    has feeds => (
        is => 'ro',
        default => sub { [] },
    );

=method add_feed( $feed | %feed_options )

Takes the existing L<App::Rssfilter::Feed> $feed (or creates a new App::RssFilter::Feed instance from the passed parameters) and adds it to the feeds for this group.

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

=method update( rules => $rules, storage => $storage )

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

