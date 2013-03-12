# ABSTRACT: Apply a filter to matching RSS items

=head1 SYNOPSIS

    use App::RssFilter;

    my $rssfilter = App::RssFilter->new;

    $rssfilter->add_rule( Duplicate => 'DeleteItem' );
    # shorthand for
    $rssfilter->add_rule(
        match  => 'App::Rssfilter::Match::Duplicate',
        filter => 'App::Rssfilter::Filter::DeleteItem',
    );

    # write modules and use them to match and filter
    {
        package MyMatcher::LevelOfInterest;
        
        sub new {
            my ( $class, @additional_args_in_brackets) = @_;
            if ( 'BORING' eq $additional_args_in_brackets[0] ) {
                # turn on boredom detection circuits
                ...
            }
            ...
        }
        
        sub match {
            my ( $self, $mojo_dom ) = @_;
            ...
        }
    }
    {
        package MyFilter::MakeMoreInteresting;
        sub filter {
            my ( $reason_for_match,
                 $matched_mojo_dom,
                 @additional_args_in_brackets ) = @_;
            ...
        }
    }
    $rssfilter->add_rule(
        'MyMatcher::LevelOfInterest[BORING]'
            => 'MyFilter::MakeMoreInteresting[glitter,lasers]'
    );
    $rssfilter->add_rule(
        match      => MyMatcher::LevelOfInterest->new('OUT_OF_SIGHT'),
        match_name => 'ReallyInteresting',
        filter     => 'MyFilter::MakeMoreInteresting[ascii_art]'
    );

    # or use anonymous subs
    $rssfilter->add_rule(
        match => sub {
            my ( $item_to_match ) = @_;
            return $item_to_match->title->text =~ / \b space \b /ixms;
        },
        filter => sub {
            my ( $reason_for_match, $matched_item ) = @_;
            my @to_check = ( $matched_item->tree );
            my %seen;
            while( my $elem = pop @to_check ) {
                next if ref $elem ne 'ARRAY' or $seen{ $elem }++;
                if( $elem->[0] eq 'text' ) {
                    $elem->[1] =~ s/ \b space \b /\& (the final frontier)/xmsig;
                }
                else
                {
                    push @to_check, @{ $elem };
                }
            }
        },
    );

    # add groups, feeds, etc.

    $rssfilter->run;

    ### or standalone

    use App::Rssfilter::Rule;
    use My::Matcher;
    use My::Filter;
    use Mojo::DOM;

    my $feed = Mojo::DOM->new( 'an RSS document' );
    my $rule = App::Rssfilter::Rule->new( 'My::Matcher' => 'My::Filter' );
    $rule->constrain( $feed );

=head1 DESCRIPTION

This module will find all the C<item> elements in a L<Mojo::DOM> object and passes each one to a matcher. If the matcher returns true, the element will be passed to a filter.
=head1 SEE ALSO

=for :list
* L<App::Rssfilter::Match::AbcPreviews>
* L<App::Rssfilter::Match::BbcSports>
* L<App::Rssfilter::Match::Category>
* L<App::Rssfilter::Match::Duplicates>
* L<App::Rssfilter::Filter::MarkTitle>
* L<App::Rssfilter::Filter::DeleteItem>
* L<App::RssFilter::Group>
* L<App::RssFilter::Feed>
* L<App::RssFilter>

=cut

use strict;
use warnings;
use feature qw< :5.14 >;

package App::Rssfilter::Rule {
    use Moo;
    use Method::Signatures;
    use Module::Runtime qw<>;
    use Class::Inspector qw<>;
    with 'App::Rssfilter::Logger';

    has _match => (
        is       => 'ro',
        required => 1,
        init_arg => 'match',
        coerce   => sub { unshift @_, 'match'; goto &App::Rssfilter::Rule::coerce_match_or_filter_to_sub }
    );

    has _filter => (
        is       => 'ro',
        required => 1,
        init_arg => 'filter',
        coerce   => sub { unshift @_, 'filter'; goto &App::Rssfilter::Rule::coerce_match_or_filter_to_sub }
    );

    method BUILDARGS( %args ) {
        if ( 1 == keys %args ) {
            @args{'match','filter'} = each %args;
            delete $args{ $args{ match } };
        }
        my %nice_names;
        for my $name ( qw< match filter > ) {
            $nice_names{"${name}_name"} = do {
                given( ref $args{ $name } ) {
                    when( 'CODE' ) { "unnamed RSS ${name}er"; }
                    when( q{}    ) { $args{ $name } }
                    default        { $_ }
                }
            };
        }
        return { %nice_names, %args };
    }

    func coerce_match_or_filter_to_sub( $option_name, $value ) {
        die "can't use an undefined value to $option_name RSS items" if not defined $value;
        given( ref $value ) {
            when( 'CODE' ) {
                return $value;
            }
            when( q{} ) { # not a ref
                my ($namespace, $additional_args) =
                    $value =~ m/
                        \A
                        ( [^\[]+ ) # namespace
                        (?:        # followed by optional
                         \[
                           ( .* )    # additional arguments
                         \]          # in square brackets
                        )?         # optional, remember?
                        \z
                    /xms;
                my @additional_args = split q{,}, $additional_args // q{};
                if( $namespace !~ /::/xms ) {
                    $namespace = join q{::}, qw< App Rssfilter >, ucfirst( $option_name ), $namespace;
                }

                $namespace =~ s/\A :: //xms; # '::anything'->can() will die

                if( not Class::Inspector->loaded( $namespace ) ) {
                    Module::Runtime::require_module $namespace;
                }

                # create an object if we got an OO package
                my $invocant = $namespace;
                if( $namespace->can( 'new' ) ) {
                    $invocant = $namespace->new( @additional_args );
                }

                # return a wrapper
                if( my $method = $invocant->can( $option_name ) ) {
                    if( $invocant eq $namespace ) {
                        return sub {
                            $method->( @_, @additional_args) ;
                        };
                    }
                    else
                    {
                        return sub {
                            $invocant->$option_name( @_ );
                        };
                    }
                }
                else
                {
                    die "${namespace}::$option_name does not exist";
                }
            }
            default {
                if( my $method = $value->can( $option_name ) ) {
                    return sub { $value->$option_name( @_ ); }
                }
                else
                {
                    die "${_}::$option_name does not exist";
                }
            }
        }
    }

=method new( %options )
    my $rule = App::RssFilter::Rule->new(
        'My::Rss::Matcher' => 'My::Rss::Filter[with,some,arguments]'
    );

    my $rule = App::RssFilter::Rule->new(
        match       => 'My::Rss::Matcher',
        filter      => 'My::Rss::Filter[with,some,arguments]',
        match_name  => 'a better name than My::Rss::Matcher' # optional
    );

As a convenience, the constructor will interpret being called with a single key-value pair as equivalent to being called with C<match> set to the key, and C<filter> set to the value.

The C<match> option can be specified as a string, subref, or object.

If the C<match> option is specified as a string, then it wil be treated as a namespace. If the string is not a fully-specified namespace, it will be changed to 'App::Rssfilter::Match::<string>'; if you really want to use C<&TopLevelNamespace::match>, specify C<match> as '::TopLevelNamespace'.
You can specify additional arguments to be passed to the matcher by joining them with commas, surrounding them with square brackets, and appending them to the namespace string.
The matcher will then be set to a wrapper:

=for :list
* If the namespace has a constructor (a sub called C<new>), a new object will be created with the additional arguemnts passed to the contructor, and the wrapper will call the C<match> method of the object.
* Otherwise, the wrapper will call the C<match> sub in the namespace with the additional arguments.

If the C<match> option is specified as an object, the matcher will be set to a wrapper which calls the C<match> method of the object.
If the C<match> option is specified as a subref, the matcher will be set to that subref.

The C<filter> option behaves exactly as the C<match> option, except it will be set to a reference to the C<filter> sub in the namespace, if set to a string.

The matcher will be called as C<match( $Mojo_DOM, @additional_args)>, and the filter will be called as C<filter( $Mojo_DOM, $match_name, @addditional_args)>.

The C<match_name> option let you specify a string which will be passed to C<filter> when C<match> matches an item. It defaults to the string passed as C<match> to the constructor, or 'unnamed RSS matcher' otherwise.

=cut

=method match( $item )

Returns true if the matcher set in the constructor matches C<$item>.

=cut

    method match( $item ) {
        return $self->_match->( $item );
    }

=method filter( $item )

Passes C<$item> to the filter set in the constructor.

=cut

    method filter( $item ) {
        $self->logger->debugf( 'applying %s since %s matched %s', $self->filter_name, $self->match_name, $item->at('guid')->text );
        return $self->_filter->( $item, $self->match_name );
    }

=method filter_name()

Returns a nice name for the filter. Will default to the class of the filter, or its value if it is a simple scalar.

=cut

    has filter_name => (
        is => 'ro',
        required => 1,
    );

=method match_name()

Returns a nice name for the matcher. C<match_name> will be passed as the second argument to the filter. Will default to the class of the matcher, or its value if it is a simple scalar.

=cut

    has match_name => (
        is => 'ro',
        required => 1,
    );

=method constrain( $Mojo_DOM )

Finds all C<item> child elements in C<$Mojo_DOM>, gathers those with are matched by the matcher, and passes each one to the filter. Returns the number of items that were matched (and filtered).

=cut

    method constrain( $Mojo_DOM ) {
        my $count = 0;
        $Mojo_DOM->find( 'item' )->grep( sub { $self->match( shift ) } )->each( sub { $self->filter( shift ); ++$count; } );
        return $count;
    }
}

1;
