# ABSTRACT: adds a logger to a class

=head1 SYNOPSIS

    package Foo;
    use Moo; # or Role::Tiny::With;
    with 'App::Rssfilter::Logger';

    package main;

    my $foo = Foo->new;
    $foo->logger->debug( 'logging to my fresh new foo' );

=head1 DESCRIPTION

C<App::Rssfilter::Logger> is a role that can be composed into any class, and adds a C<logger> attribute which can be used to log to a L<Log::Any::Adapter>.

=cut

=head1 SEE ALSO

=for :list
* L<Log::Any>
* L<Log::Any::Adapter>

=cut

use strict;
use warnings;
use feature qw( :5.14 );

package App::Rssfilter::Logger {

    use Moo::Role;
    use Log::Any;

=attr logger

    $receiver->logger->debug( 'cutting down trees' );

This is a L<Log::Any> object.

=cut

    has 'logger' => (
        is => 'lazy',
        default => sub { Log::Any->get_logger() },
    );

};

1;
