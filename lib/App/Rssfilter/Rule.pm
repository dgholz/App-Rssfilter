# ABSTRACT: match and filter RSS feeds

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

    # write modules with match and filter subs

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
        my ( $self, $mojo_dom_rss_item ) = @_;
        ...
    }

    package MyFilter::MakeMoreInteresting;

    sub filter {
        my ( $reason_for_match,
             $matched_mojo_dom_rss_item,
             @bracketed_args ) = @_;
        ...
    }

    package main;

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

    ### or with an App::Rssfilter feed or group

    use App::RssFilter::Feed;
    my $feed = App::RssFilter::Feed->new( 'examples' => 'http://example.org/e.g.rss' );
    $feed->add_rule( 'My::Matcher' => 'My::Filter' );
    # same as
    $feed->add_rule( App::Rssfilter::Rule->new( 'My::Matcher' => 'My::Filter' ) );
    $feed->update;

=head1 DESCRIPTION

This module will test all C<item> elements in a L<Mojo::DOM> object against a condition, and apply a action to those tiems where the condition is true.

It consumes the L<App::Rssfilter::Logger> role.

=cut

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

=attr logger

This is a object used for logging; it defaults to a L<Log::Any> object. It is provided by the L<App::Rssfilter::Logger> role.

=cut

=attr condition

This is the module, object, or coderef to use to match C<item> elements for filtering. Modules are passed as strings, and must contain a C<match> sub. Object must have a C<match> method.

=cut

    has condition => (
        is       => 'ro',
        required => 1,
    );

=attr _match

This is a coderef created from this rule's condition which will be used by L</match> to check RSS items. It is automatically coerced from the C<condition> attribute and cannot be passed to the constructor.

If this rule's condition is an object, C<_match> will store a wrapper which calls the C<match> method of the object.
If this rule's condition is a subref, C<_match> will store the same subref.

If this rule's condition is a string, it is treated as a namespace. If the string is not a fully-specified namespace, it will be changed to C<App::Rssfilter::Match::I<<string>>>; if you really want to use C<&TopLevelNamespace::match>, specify C<condition> as C<'::TopLevelNamespace'> (or directly as C<\&TopLevelNameSpace::match>). Additional arguments can be passed to the matcher by appending then to the string, separated by commas, surrounded by square brackets.

C<_match> will then be set to a wrapper:

=for :list
* If C<I<< <namespace> >>::new> exists, C<_match> will be set as if C<condition> had originally been the object returned from calling C<I<< <namespace> >>::new( @additional_arguments )>.
* Otherwise, C<_match> will store a wrapper which calls C<I<< <namespace> >>::match( $rss_item, @additional_arguments )>.

=cut

    has _match => (
        is       => 'lazy',
        required => 1,
        init_arg => undef,
        default  => method { $self->coerce_attr( attr => $self->condition, type => 'match' ) },
    );

=method match

    my $did_match = $self->match( $item_element_from_Mojo_DOM );

Returns the result of testing this rule's condition against C<$item>.

=cut

    method match( $item ) {
        return $self->_match->( $item );
    }

=attr condition_name

This is a nice name for the condition, which will be used as the reason for the match given to the action. Defaults to the class of the condition, or its value if it is a simple scalar, or C<unnamed RSS matcher> otherwise.

=cut

    has condition_name => (
        is => 'lazy',
        default => method { $self->nice_name_for( $self->condition, 'matcher' ) },
    );

=attr action

This is the module, object, or coderef to use to filter C<item> elements matched by this rule's condition. Modules are passed as strings, and must contain a C<filter> sub. Object must have a C<filter> method.

=cut

    has action => (
        is       => 'ro',
        required => 1,
    );

=attr _filter

This is a coderef created from this rule's action which will be used by L</filter> to check RSS items. It is automatically coerced from the C<action> attribute and cannot be passed to the constructor.

If this rule's action is an object, C<_filter> will store a wrapper which calls the C<filter> method of the object.
If this rule's action is a subref, C<_filter> will store the same subref.

If the rule's action is a string, it is treated as a namespace. If the string is not a fully-specified namespace, it will be changed to C<App::Rssfilter::filter::I<<string>>>; if you really want to use C<&TopLevelNamespace::filter>, specify C<action> as C<'::TopLevelNamespace'> (or directly as C<\&TopLevelNameSpace::filter>). Additional arguments can be passed to the filter by appending then to the string, separated by commas, surrounded by square brackets.

The filter will then be set to a wrapper:

=for :list
* If C<I<< <namespace> >>::new> exists, C<_filter> will be set as if C<action> had originally been the object returned from calling C<I<< <namespace> >>::new( @additional_arguments )>.
* Otherwise, C<_filter> will store a wrapper which calls C<I<< <namespace> >>::filter( $rss_item, @additional_arguments )>.

=cut

    has _filter => (
        is       => 'lazy',
        required => 1,
        init_arg => undef,
        default  => method { $self->coerce_attr( attr => $self->action, type => 'filter' ) },
    );

=method filter

    $self->filter( $item_element_from_Mojo_DOM );

Applies this rule's action to C<$item>.

=cut

    method filter( $item ) {
        $self->logger->debugf(
            'applying %s since %s matched %s',
                $self->action_name,
                $self->condition_name,
                $item->find('guid, link, title')->first->text
        );
        return $self->_filter->( $item, $self->condition_name );
    }

=attr action_name

This is a nice name for the action. Defaults to the class of the action, or its value if it is a simple scalar, or C<unnamed RSS filter> otherwise.

=cut

    has action_name => (
        is => 'lazy',
        default => method { $self->nice_name_for( $self->action, 'filter' ) },
    );

=method constrain

    my $count_of_filtered_items = $rule->constrain( $Mojo_DOM )

Gathers all child item elements of C<$Mojo_DOM> for which the condition is true, and applies the action to each. Returns the number of items that were matched (and filtered).

=cut

    method constrain( Mojo::DOM $Mojo_DOM ) {
        my $count = 0;
        $Mojo_DOM->find( 'item' )->grep( sub { $self->match( shift ) } )->each( sub { $self->filter( shift ); ++$count; } );
        return $count;
    }

    # internal helper methods

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

    method BUILD( $args ) {
        # validate coercion of condition & action
        $self->$_ for qw< _filter _match >;
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
}

1;
