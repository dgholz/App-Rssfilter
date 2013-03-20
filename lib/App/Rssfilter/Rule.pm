# ABSTRACT: match and filter Rss items

=head1 SYNOPSIS

    use App::RssFilter::Rule;

    use Mojo::DOM;
    my $rss = Mojo::DOM->new( 'an RSS document' );

    my $delete_duplicates_rule = App::Rssfilter::Rule->new( Duplicate => 'DeleteItem' );

    # shorthand for
    $delete_duplicates_rule = App::Rssfilter::Rule->new(
        condition => 'App::Rssfilter::Match::Duplicate',
        action    => 'App::Rssfilter::Filter::DeleteItem',
    );

    # apply rule to RSS document
    $delete_duplicates_rule->constrain( $rss );

    # write modules and use them to match and filter
    {
        package MyMatcher::LevelOfInterest;
        
        sub new {
            my ( $class, @bracketed_args) = @_;
            if ( 'BORING' eq $bracket_args[0] ) {
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
                 @bracketed_args ) = @_;
            ...
        }
    }

    my $boring_made_interesting_rule = App::Rssfilter::Rule->new( 
        'MyMatcher::LevelOfInterest[BORING]'
            => 'MyFilter::MakeMoreInteresting[glitter,lasers]'
    );
    $boring_made_interesting_rule->constrain( $rss );

    my $interesting_with_decoration_rule = App::Rssfilter::Rule->new( 
        condition      => MyMatcher::LevelOfInterest->new('OUT_OF_SIGHT'),
        condition_name => 'ReallyInteresting', # instead of plain 'MyMatcher::LevelOfInterest'
        action         => 'MyFilter::MakeMoreInteresting[ascii_art]',
    );
    $interesting_with_decoration_rule->constrain( $rss );

    # or use anonymous subs
    my $space_the_final_frontier_rule = App::Rssfilter:Rule->new(
        condition => sub {
            my ( $item_to_match ) = @_;
            return $item_to_match->title->text =~ / \b space \b /ixms;
        },
        action => sub {
            my ( $reason_for_match, $matched_item ) = @_;
            my @to_check = ( $matched_item->tree );
            my %seen;
            while( my $elem = pop @to_check ) {
                next if 'ARRAY' ne ref $elem or $seen{ $elem }++;
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
    $space_the_final_frontier_rule->constrain( $rss );

    ### or with a App::Rssfilter feed or group

    use App::RssFilter::Feed;
    my $feed = App::RssFilter::Feed->new( 'examples' => 'http://example.org/e.g.rss' );
    $feed->add_rule( $_ ) for ( $rule1, $rule2, $rule3 );
    $feed->add_rule( 'My::Matcher' => 'My::Filter' );
    # same as
    $feed->add_rule( App::Rssfilter::Rule->new( 'My::Matcher' => 'My::Filter' ) );
    $feed->update;

=head1 DESCRIPTION

This module will test all C<item> elements in a L<Mojo::DOM> object against some condition, and apply some action to those tiems where the condition is true.

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

=attr condition

The C<match> option can be specified as a string, subref, or object.

If the C<match> option is specified as a string, then it wil be treated as a namespace. If the string is not a fully-specified namespace, it will be changed to 'App::Rssfilter::Match::<string>'; if you really want to use C<&TopLevelNamespace::match>, specify C<match> as '::TopLevelNamespace'.
You can specify additional arguments to be passed to the matcher by joining them with commas, surrounding them with square brackets, and appending them to the namespace string.
The matcher will then be set to a wrapper:

=for :list
* If the namespace has a constructor (a sub called C<new>), a new object will be created with the additional arguemnts passed to the contructor, and the wrapper will call the C<match> method of the object.
* Otherwise, the wrapper will call the C<match> sub in the namespace with the additional arguments.

If the C<match> option is specified as an object, the matcher will be set to a wrapper which calls the C<match> method of the object.
If the C<match> option is specified as a subref, the matcher will be set to that subref.

The matcher will be called as C<match( $Mojo_DOM, @additional_args)>, and the filter will be called as C<filter( $Mojo_DOM, $condition_name, @addditional_args)>.

=cut

    has condition => (
        is       => 'ro',
        required => 1,
    );

    has _match => (
        is       => 'ro',
        required => 1,
        init_arg => undef,
        default  => method { $self->coerce_attr( attr => $self->action, type => 'match' ) },
    );

=method match

    my $did_match = $self->match( $item_element_from_Mojo_DOM );

Returns the result of testing this rule's condition against C<$item>.

=cut

    method match( $item ) {
        return $self->_match->( $item );
    }


=attr condition_name

This is a nice name for the condition, which will be used as the reason for the match given to the action. Defaults to the class of the condition, or its value if it is a simple scalar.
The C<condition_name> option let you specify a string which will be passed to C<filter> when C<match> matches an item. It defaults to the string passed as C<match> to the constructor, or 'unnamed RSS matcher' otherwise.

=cut

    has condition_name => (
        is => 'ro',
        default => method { nice_name_for( $self->condition, 'match' ) },
    );

=attr action

The C<match> option can be specified as a string, subref, or object.

If the C<match> option is specified as a string, then it wil be treated as a namespace. If the string is not a fully-specified namespace, it will be changed to 'App::Rssfilter::Match::<string>'; if you really want to use C<&TopLevelNamespace::match>, specify C<match> as '::TopLevelNamespace'.
You can specify additional arguments to be passed to the matcher by joining them with commas, surrounding them with square brackets, and appending them to the namespace string.
The matcher will then be set to a wrapper:

=for :list
* If the namespace has a constructor (a sub called C<new>), a new object will be created with the additional arguemnts passed to the contructor, and the wrapper will call the C<match> method of the object.
* Otherwise, the wrapper will call the C<match> sub in the namespace with the additional arguments.

If the C<match> option is specified as an object, the matcher will be set to a wrapper which calls the C<match> method of the object.
If the C<match> option is specified as a subref, the matcher will be set to that subref.

The matcher will be called as C<match( $Mojo_DOM, @additional_args)>, and the filter will be called as C<filter( $Mojo_DOM, $condition_name, @addditional_args)>.

=cut

    has action => (
        is       => 'ro',
        required => 1,
    );

    has _filter => (
        is       => 'ro',
        required => 1,
        init_arg => undef,
        default  => method { $self->coerce_attr( attr => $self->action, type => 'filter' ) },
    );

=method filter

    $self->filter( $item_element_from_Mojo_DOM );

Applies this rule's action to C<$item>.

=cut

    method filter( $item ) {
        $self->logger->debugf( 'applying %s since %s matched %s', $self->action_name, $self->condition_name, $item->at('guid')->text );
        return $self->_filter->( $item, $self->condition_name );
    }

=attr action_name

This is a nice name for the action. Defaults to the class of the action, or its value if it is a simple scalar.

=cut

    has action_name => (
        is => 'ro',
        default => method { $self->nice_name_for( $self->action, 'filter' ) },
    );

    method nice_name_for( $attr, $type ) {
        given( ref $attr ) {
            when( 'CODE' ) { "unnamed RSS ${type}"; }
            when( q{}    ) { $attr }
            default        { $_ }
        }
    }

    method BUILDARGS( %args ) {
        if ( 1 == keys %args ) {
            @args{'condition','action'} = each %args;
            delete $args{ $args{ condition } };
        }
        return \%args;
    }

    method coerce_attr( :$attr, :$type ) {
        die "can't use an undefined value to $type RSS items" if not defined $attr;
        given( ref $attr ) {
            when( 'CODE' ) {
                return $attr;
            }
            when( q{} ) { # not a ref
                return $self->coerce_module_name_to_sub( module_name => $attr, type => $type );
            }
            default {
                if( my $method = $attr->can( $type ) ) {
                    return sub { $attr->$type( @_ ); }
                }
                else
                {
                    die "${_}::$type does not exist";
                }
            }
        }
    }

    method coerce_module_name_to_sub( :$module_name, :$type ) {
        my ($namespace, $additional_args) =
            $module_name =~ m/
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
            $namespace = join q{::}, qw< App Rssfilter >, ucfirst( $type ), $namespace;
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
        if( my $method = $invocant->can( $type ) ) {
            if( $invocant eq $namespace ) {
                return sub {
                    $method->( @_, @additional_args) ;
                };
            }
            else
            {
                return sub {
                    $invocant->$method( @_ );
                };
            }
        }
        else
        {
            die "${namespace}::$type does not exist";
        }
    }

=method constrain

    my $count_of_filtered_items = $rule->constrain( $Mojo_DOM )

Gathers all child item elements of C<$Mojo_DOM> for which the condition is true, and applies the action to each. Returns the number of items that were matched (and filtered).

=cut

    method constrain( Mojo::DOM $Mojo_DOM ) {
        my $count = 0;
        $Mojo_DOM->find( 'item' )->grep( sub { $self->match( shift ) } )->each( sub { $self->filter( shift ); ++$count; } );
        return $count;
    }
}

1;
