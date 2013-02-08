use strict;
use warnings;
use feature qw( :5.14 );

# ABSTRACT: load and save RSS feeds as files

=head1 SYNOPSIS

    use App::Rssfilter::Feed::Storage;

    my $fs = App::Rssfilter::Feed::Storage->new(
        path => 'BBC',
        name => 'London',
    );

    print 'last update of feed was ', $fs->last_modified, "\n";
    print 'what we got last time: ', $fs->load_existing, "\n";

    $fs->save_feed( Mojo::DOM->new( "<hi><hello/></hi>" ) );
    print 'now it is: ', $fs->load_existing, "\n";

=head1 DESCRIPTION

This module saves and loads RSS feeds to and from files, where the file name is based on a group and feed name. L<Rss::Filter> will use this class for storing & retreiving feeds, unless constructed with a compatible alternative.

=cut

package App::Rssfilter::Feed::Storage {

    use Method::Signatures;
    use Moo;
    use Mojo::DOM;
    use Path::Class::File;
    use Path::Class::Dir;
    use HTTP::Date;

=method new

    my $fs = App::Rssfilter::Feed::Storage->new(
        path => 'BBC',
        name => 'London',
    );

The constructer has two required named parameters: a path specifying where the feed should be located, and the name for the feed. These are used as the directory path and filename (respectively) for the feed.

The path parameter may be a string specifying an absolute or relative directory path, or an array ref of directory names which will be joined to form a directory path.

=cut

=method path

    print $fs->path, "\n";

Returns the path to feed, as passed to the constructor.

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

=method path_push( @paths )

    my $new_fs = $fs->path_push( 'list', 'of', 'paths' )

Returns a new App::Rssfilter::Feed::Storage object whose path has had C<@paths> appended to it.

=cut

    method path_push( @_ ) {
        return App::Rssfilter::Feed::Storage->new(
            path => $self->path->subdir( @_ ),
            name => $self->name,
        );
    }

=method name

    print $fs->name, "\n";

Returns the name of the feed, as passed to the constructor.

=cut

    has name => (
         is => 'ro',
    );

=method set_name( $new_name )

    my $new_fs = $fs->set_name( 'formally known as App::Rssfilter::Feed::Storage' );

Returns this object if its name is already C<$new_name>, else returns a clone of this object with its name set to C<$name>.

=cut

    method set_name( $new_name ) {
        no warnings 'uninitialized';
        print "$new_name ". $self->name, "\n";
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

=method last_modified

    print $fs->last_modified, "\n";

Returns the time of the last modification as a HTTP date string suitable for use in a 'Last-Modified' header. If the feed has never been saved, returns 'Thu, 01 Jan 1970 00:00:00 GMT'.

=cut

    has last_modified => (
        is => 'lazy',
        clearer => '_clear_last_modified',
    );

    method _build_last_modified {
        if ( my $stat = $self->_file_path->stat ) {
            return time2str $stat->mtime;
        }
        return time2str 0;
    }

=method load_existing

    print $fs->load_existing;

Returns a L<Mojo::DOM> object initialised with the content of the previously-saved feed. If the feed has never been saved, returns a L<Mojo::DOM> object initialised with an empty string.

=cut

    method load_existing {
        my $stat = $self->_file_path->stat;

        return Mojo::DOM->new if not defined $stat;

        $self->_clear_last_modified;
        return Mojo::DOM->new( scalar $self->_file_path->slurp );
    }

=method save_feed( $dom )

    $fs->save_feed( Mojo::DOM->new( '<rss> ... </rss>' ) );

Saves a L<Mojo::DOM> object (or anything with a C<to_xml> method). C<last_modified()> is updated.

=cut

    method save_feed( $feed ) {
        my $target_dir = $self->_file_path->dir;
        if( not defined $target_dir->stat ) {
            $target_dir->mkpath;
        }
        $self->_file_path->spew( $feed->to_xml );
        $self->_clear_last_modified;
    }

};

1;
