# ABSTRACT: Adds a logger to a class

=head1 SYNOPSIS

    {
        package Foo;
        use Moo; # or Role::Tiny::With;
        with 'App::Rssfilter::Logger';
    }

    my $foo = Foo->new;
    $foo->logger->debug( 'logger to my fresh new foo' );

=head1 DESCRIPTION

C<App::Rssfilter::Logger> is a role that can be composed into any class, and adds a C<logger> method which logs to L<Log::Any::Adapter>.

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

=method log()

Returns a L<Log::Any> object.

=cut

    has 'logger' => (
        is => 'lazy',
        default => sub { Log::Any->get_logger() },
    );

};

1;
