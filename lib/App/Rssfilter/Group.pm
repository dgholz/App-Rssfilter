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

    method BUILDARGS( @options ) {
        if( 1 == @options ) {
            unshift @options, 'name';
        }
        return { @options };
    }

=method new( %options )

=cut

=method name()

Returns the name passed to the constructor, or '.' if no name passed.

=cut

    has name => (
        is => 'ro',
        default => sub { '.' },
    );

=method storage()

Returns the L<App::Rssfilter::Feed::Storage> instance passed to the constructor, or a suitable default.

=cut

    has storage => (
        is => 'ro',
        default => method { App::Rssfilter::Feed::Storage->new( groups => [ $self->name ] ) },
    );

=method groups()

Returns an array reference to the list of subgroups.

=cut

    has groups => (
        is => 'ro',
        default => sub { [] },
    );

=method add_group( $group | %group_options )

Adds the L<App::Rssfilter::group> $group (or creates a new App::RssFilter::group instance from the passed parameters) to the groups.

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

=method update( storage => $storage )

Recursively calls update() on the feeds and groups attatched to this group. C<$storage> is a L<App::Rssfilter::Feed::Storage> for children to use when loading or saving feeds. If it is not specified, it is set to the storage argument passed to the constructor.

=cut

    method update( :$storage = $self->storage ) {
        my $child_storage = $self->storage->path_push( $self->name );
        $_->update( storage => $child_storage ) for @{ $self->groups };
        $_->update( storage => $child_storage ) for @{ $self->feeds };
    }

}

1;

=head1 SEE ALSO

=for :list
* L<App::RssFilter::Rule>
* L<App::RssFilter::Feed>
* L<App::RssFilter>

=cut

