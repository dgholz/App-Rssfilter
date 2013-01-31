# ABSTRACT: Get the latest or previous version of an RSS feed

=head1 SYNOPSIS

    use App::Rssfilter;

    my $group = App::RssFilter::Group->new( 'Tubular' );
    $group->add_feed( RadName => 'http://r.a.d.i.c.al/feed.rss' )
                        ->add_rule( 'A Matcher' => 'A Filter' )
                        ->add_rule( 'Another Matcher' => 'Another Filter' );

    $group->update;

    # shorthand for
    my $feed = $group->add_feed(
        name => 'RadName'
        url  => 'http://r.a.d.i.c.al/feed.rss',
    );
    my $rule = App::RssFilter::Rule->new( 
        match  => 'A Matcher',
        filter => 'A Filter',
    );
    $feed->add_rule( $rule );
    $feed->add_rule(
        match  => 'Another Matcher',
        filter => 'Another Filter',
    );

    $feed->update;

    ### or standalone

    App::Rssfilter::Feed->new( 'filename' => 'http://get.your.files/here.rss' )
        ->add_rule( 'Category[clogging]' => 'DeleteItem' )
        ->update;

=head1 DESCRIPTION

This module updates an RSS feed by fetching the latest version of it from a URL and applying a list of L<App::Rssfilter::Rules|App::Rssfilter::Rule> to it before saving it.

=cut

use strict;
use warnings;
use feature qw< :5.14 >;

package App::Rssfilter::Feed {
    use Moo;
    use Method::Signatures;

    has name => (
        is => 'ro',
        required => 1,
    );

    has url => (
        is => 'ro',
        required => 1,
    );

    has rules => (
        is => 'ro',
        default => sub { [] },
    );

    has user_agent => (
        is => 'ro',
        default => sub { use Mojo::UserAgent; Mojo::UserAgent->new },
    );

    has storage => (
        is => 'lazy',
        default => method {
            use App::Rssfilter::Feed::Storage;
            App::Rssfilter::Feed::Storage->new(
                name  => $self->name,
            );
        },
    );

    method BUILDARGS( %options ) {
        if( 1 == keys %options ) {
            @options{ 'name', 'url' } = each %options;
            delete $options{ $options{ name } };
        }
        return { %options };
    }

=method new( %options )
 
    my $feed = App::Rssfilter::Feed->new(
        'Where is My Feed' => 'http://where.is/my_feed.rss',
    );

    my $feed = App::Rssfilter::Feed->new(
        name       => 'Where is My Feed',
        url        => 'http://where.is/my_feed.rss',
        rules      => [ $a_rule, $another_rule, $etc ],
        user_agent => Mojo::UserAgent->new,
        storage    => App::Rssfilter::Feed::Storage->new( feed_name => 'Where is My Feed' ),
    );

This creates a new feed object. It accepts a hash (or hashref) of options:

=over 4

=item * name

B<Required>

The name of the feed. It will be used to save and load the feed to and from storage.

=item * url

B<Required>

The URL to fetch the feed from.

=item * rules

A arrayref of rules to apply to this feed when it is updated. Defaults to the empty list.

=item * user_agent

Defaults to a new instance of L<Mojo::UserAgent>.

=item * storage

Object to use when loading/saving the feed. Defaults to a new instance of L<App::Rssfilter::Feed::Storage>.

=back

As a convenience, the constructor will interpret being called with a single key-value pair as equivalent to being called with C<name> set to the key, and C<url> set to the value.

=cut

=method add_rule( $rule | %rule_parameters )

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

=method rules()

Returns an array reference to the list of rules which will be applied to the feed.

=cut

=method update( rules => $rules, storage => $storage )

This method will:

=for :list
* download the RSS feed from the URL, if it is newer than the previously-saved version
* apply the rules to the new RSS feed
* save the new RSS feed
* apply the rules to the old RSS feed

The old feed has rules applied to it so that any group-wide rules will always see all of the latest items, even if a feed does not have a newer version available. 

The parameters are optional. If C<rules> is specified, they will be added to the feed's rules for this update only. If C<storage> is specified, it will used instead of the feed's storage to load/save feed content.

=cut

    method update( ArrayRef :$rules = [], :$storage = $self->storage ) {
        $storage = $storage->set_name( $self->name );
        my $old = $storage->load_existing;

        my $headers = {};
        if( defined( my $last_modified = $storage->last_modified ) ) {
            ${ $headers }{ 'If-Modified-Since' } = $last_modified;
        }

        my $latest = $self->user_agent->get(
            $self->url,
            $headers
        );

        my @rules = @{ $rules };
        push @rules, @{ $self->rules };

        if ( 200 == $latest->res->code ) {
            my $new = $latest->res->dom;
            for my $rule ( @rules ) {
                $rule->constrain( $new );
            }
            $storage->save_feed( $new );
        }

        if ( defined $old ) {
            $old = Mojo::DOM->new( $old );
            for my $rule ( @rules ) {
                $rule->constrain( $old );
            }
        }
    }

}

1;

=head1 SEE ALSO

=for :list
* L<App::RssFilter::Feed::Storage>
* L<App::RssFilter::Group>
* L<App::RssFilter::Rule>
* L<App::RssFilter>

=cut

