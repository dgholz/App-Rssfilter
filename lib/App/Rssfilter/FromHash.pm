# ABSTRACT: Create an App::Rssfilter object from a hash

=head1 SYNOPSIS

    use App::RssFilter;

    my $rssfilter = App::RssFilter->from_hash(
        groups => [
            {
                group => 'hi',
                rules => [
                    Duplicates => 'DeleteItem',
                ],
                feeds => [
                    WashPost => 'http://feeds.washingtonpost.com/rss/national',
                    {
                        name => 'Pravda',
                        url  => 'http://english.pravda.ru/russia/export.xml',
                    },
                ],
            },
            {
                group => 'hello',
                rules => [
                    {
                        match => 'Category[Politics]',
                        filter => 'MarkTitle'
                    },
                ],
            },
        ],
    );
    $rssfilter->group('hello')->add_feed( $rssfilter->group('hi')->feed('WashPost') );
    $rssfilter->group('hello')->add_rule( $rssfilter->group('hi')->rules[0] );

=head1 DESCRIPTION

Creates an instance of L<App::Rssfilter::Group> and adds the groups, feeds, and rules specified in the hash to it. The created Group will store any filtered feeds in the current directory, or in subdirectories corresponding to the sub-groups.

C<App::Rssfilter::FromHash> is a role that can be composed into any class which provides C<add_feed>, C<add_rule>, and C<add_group> methods.

=cut

=head1 SEE ALSO

=for :list
* L<App::RssFilter>
* L<App::RssFilter::FromYaml>
* L<App::RssFilter::FromJson>

=cut

use strict;
use warnings;
use feature qw( :5.14 );

package App::Rssfilter::FromHash {

    use Moo::Role;
    use Method::Signatures;
    use Scalar::Util qw< blessed >;

    requires 'add_feed';
    requires 'add_rule';
    requires 'add_group';

=method from_hash( %hash )

Create a new L<App::Rssfilter::Group>, then walk the hash to create additional Groups, Feeds, or Rules & add them to the Group, sub-Groups, etc.

The hash may have four elements:
=for :list
* C<groups> - arrayref of hashrefs for subgroups, same schema as the original hash
* C<group>  - name of this group, used when storing its feeds
* C<feeds>  - arrayref of feeds to fetch, contents should be valid L<App::Rssfilter::Feed> ctor arguments.
* C<rules>  - arrayref of rules to apply, contents should be valid L<App::Rssfilter::Rule> ctor arguments.

=cut

    method from_hash( $config_ref, @config ) {
        if ( 'HASH' ne ref $config_ref ) {
            unshift @config, $config_ref;
            $config_ref = {};
        }
        $self->_from_hash( %{ $config_ref }, @config );
    }

    method _from_hash( %config ) {
        my $group = $self->new( name => $config{group} );

        map { $group->add_feed( @{ $_ } ) } $self->split_for_ctor( @{ $config{feeds} } );
        map { $group->add_rule( @{ $_ } ) } $self->split_for_ctor( @{ $config{rules} } );

        for my $subgroup ( @{ $config{groups} } ) {
            $group->add_group( $self->_from_hash( %{ $subgroup } ) );
        }

        return $group;
    }

    method split_for_ctor( @list ) {
        my @results;
        while( @list ) {
            push @results, do {
                given( shift @list ) {
                    [ %{ $_ } ] when 'HASH'  eq ref $_;
                    [ @{ $_ } ] when 'ARRAY' eq ref $_;
                    # squash 'Argument "foo" isn't numeric in smart match'
                    [ $_ ]      when '' ne ref $_;
                    default { [ $_ => shift @list ] };
                }
            };
        }
        return @results;
    }

};

1;
