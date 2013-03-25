# ABSTRACT: a role for creating App::Rssfilter objects from a configuration hash

=head1 SYNOPSIS

    {
        package Cool::Name;
        use Role::Tiny::With;
        with 'App::Rssfilter::FromHash';

        sub new { ... }
        sub add_group { ... }
        sub add_feed { ... }
        sub add_rule { ... }
    };


    my $cool_name = Cool::Name->from_hash(
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

=head1 DESCRIPTION

This role will extend its receiving class with a L</from_hash> method. It requires that the receiver has C<add_group>, C<add_feed>, and C<add_rule> methods.

=cut

use strict;
use warnings;
use feature qw( :5.14 );

package App::Rssfilter::FromHash {

    use Moo::Role; # test harness uses Test::Routine, which wants a Moose-y role, son no Role::Tiny
    use Method::Signatures;
    use Scalar::Util qw< blessed >;

    requires 'add_feed';
    requires 'add_rule';
    requires 'add_group';

=method from_hash

    my $receiver_instance = Receiver::Class->from_hash( %config );

Create a new instance of the receiving class, then walk the hash to create subgroups and add feeds or rules to it (or its subgroups).

The hash may have four elements:

=for :list
* C<group>  - name of this group, used when storing its feeds
* C<groups> - arrayref of hashrefs for subgroups, same schema as the original hash
* C<feeds>  - arrayref of feeds to fetch
* C<rules>  - arrayref of rules to apply

Bare scalars in C<feeds> will be collected into key-value pairs; everything else will be mapped onto the receivers C<add_feed>. Likewise for C<rules>.

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

=method split_for_ctor

    my @arguments_for_ctor_in_arrayrefs = $receiving_instance->split_for_ctor( @args );

B<INTERNAL>

Returns the contents of C<args> partitioned into arrayrefs, whose contents are suitable arguments for a L<Moose>-y constructor. Collects bare scalars in C<@args> with their following element into key-value pairs; arrayrefs & hashrefs are dereferenced; everthing else is taken as-is.

=cut

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
