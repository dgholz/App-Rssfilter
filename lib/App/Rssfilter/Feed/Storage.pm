use strict;
use warnings;

# ABSTRACT: load and save RSS feeds as files

=head1 SYNOPSIS

    use App::Rssfilter::Feed::Storage;

    my $fs = App::Rssfilter::Feed::Storage->new(
        path => 'Hi-type feeds',
        name => 'Hello',
    );

    print 'last update of feed was ', $fs->last_modified, "\n";
    print 'what we got last time: ', $fs->load_existing, "\n";

    $fs->save_feed( Mojo::DOM->new( "<hi>hello</hi>" ) );
    print 'now it is: ', $fs->load_existing, "\n";

=head1 DESCRIPTION

This module saves and loads RSS feeds to and from files, where the file name is based on a group and feed name. It is the default implementation used by L<App::Rssfilter::Feed> for storing & retreiving feeds.

It consumes the L<App::Rssfilter::Logger> role.

=cut

package App::Rssfilter::Feed::Storage;

use Method::Signatures;
use Moo;
with 'App::Rssfilter::Logger';
use Mojo::DOM;
use Path::Class::File 0.26;
use Path::Class::Dir;
use HTTP::Date;

=attr logger

This is a object used for logging; it defaults to a L<Log::Any> object. It is provided by the L<App::Rssfilter::Logger> role.

=cut

=attr path

This is the directory path to the stored feed file. If not specified, the current working directory will be used. It is coerced into a L<Path::Class::Dir> object, if it is a string specifying an absolute or relative directory path, or an array or arrayref of directory names (which will be joined to form a directory path).

=cut

has path => (
     is => 'ro',
     default => sub { Path::Class::Dir->new() },
     coerce => sub {
         return $_[0] if 'Path::Class::Dir' eq ref $_[0];
         if ( 1 == @_  && 'Array' eq ref $_[0] ) {
             @_ = @{ $_[0] };
         }
         Path::Class::Dir->new( @_ )
     },
);

=method path_push

    my $new_fs = $fs->path_push( @paths );

Returns a clone of this object whose path has had C<@paths> appended to it.

=cut

method path_push( @paths ) {
    return App::Rssfilter::Feed::Storage->new(
        path => $self->path->subdir( @paths ),
        name => $self->name,
    );
}

=attr name

This is the name of the feed, and will be used as the filename to store the feed under.

=cut

has name => (
     is => 'ro',
);

=method set_name

    my $new_fs = $fs->set_name( $new_name );

Returns this object if its name is already C<$new_name>, else returns a clone of this object with its name set to C<$name>.

=cut

method set_name( $new_name ) {
    return $self if defined($self->name) && defined($new_name) ? $self->name eq $new_name : ! defined($self->name) && ! defined($new_name);
    return App::Rssfilter::Feed::Storage->new(
        name => $new_name,
        path => $self->path,
    );
}

has _file_path => (
    is => 'lazy',
    init_arg => undef,
);

method _build__file_path {
    die "no name" if not defined $self->name;
    die "no path" if not defined $self->path;
    $self->path->file( $self->name .'.rss' );
}

=attr last_modified

This is the last time the stored RSS feed was saved, as a HTTP date string suitable for use in a C<Last-Modified> header. If the feed has never been saved, returns C<Thu, 01 Jan 1970 00:00:00 GMT>. It cannot be set from the constructor.

=cut

has last_modified => (
    is => 'lazy',
    init_arg => undef,
    clearer => '_clear_last_modified',
);

method _build_last_modified {
    if ( my $stat = $self->_file_path->stat ) {
        return time2str $stat->mtime;
    }
    return time2str 0;
}

=method load_existing

    print $fs->load_existing->to_string;

Returns a L<Mojo::DOM> object initialised with the content of the previously-saved feed. If the feed has never been saved, returns a L<Mojo::DOM> object initialised with an empty string.

=cut

method load_existing {
    $self->logger->debugf( 'loading '. $self->_file_path );
    my $stat = $self->_file_path->stat;

    return Mojo::DOM->new if not defined $stat;

    $self->_clear_last_modified;
    return Mojo::DOM->new( scalar $self->_file_path->slurp );
}

=method save_feed

    $fs->save_feed( Mojo::DOM->new( '<rss> ... </rss>' ) );

Saves a L<Mojo::DOM> object (or anything with a C<to_string> method), and updates C<last_modified()>.

=cut

method save_feed( $feed ) {
    $self->logger->debugf( 'writing out new filtered feed to '. $self->_file_path );
    my $target_dir = $self->_file_path->dir;
    if( not defined $target_dir->stat ) {
        $self->logger->debug( "no $target_dir directory! making one" );
        $target_dir->mkpath;
    }
    $self->_file_path->spew( $feed->to_string );
    $self->_clear_last_modified;
}

1;
