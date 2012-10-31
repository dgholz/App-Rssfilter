use strict;
use warnings;
use feature qw( :5.14 );

# ABSTRACT: load and save RSS feeds as files

=head1 SYNOPSIS

    use Feed::Storage;

    my $fs = Feed::Storage->new( group_name => 'BBC', feed_name => 'London' );

    print 'last update of feed was ', $fs->last_modified, "\n";
    print 'what we got last time: ', $fs->load_existing, "\n";

    $fs->save_feed( Mojo::DOM->new("<hi><hello/></hi>");
    print 'now it is: ', $fs->load_existing, "\n";

=head1 DESCRIPTION

This module saves and loads RSS feeds to and from files, where the file name is based on a group and feed name. L<Rss::Filter> will use this class for storing & retreiving feeds, unless constructed with a compatible alternative.

=cut

package Feed::Storage {

    use Method::Signatures;
    use Moo;
    use Mojo::DOM;
    use Path::Class::File;
    use HTTP::Date;

=method new

    my $fs = Feed::Storage->new( group_name => 'BBC', feed_name => 'London' );

The constructer has two required named parameters: a name for the group the feed belongs to, and the name for the feed. These are used as the directory and filename (respectively) for the feed.

=cut

    has logger => (
        is => 'lazy',
    );

    method _build_logger {
        use Log::Log4perl qw< :levels >;
        Log::Log4perl->easy_init( { level => $DEBUG } );
        Log::Log4perl->get_logger( ref $self );
    }

=method group_name

    print $fs->group_name, "\n";

Returns the group name of the feed, as passed to the constructor.

=cut

    has group_name => (
         is => 'ro',
         required => 1,
    );

=method feed_name

    print $fs->feed_name, "\n";

Returns the name of the feed, as passed to the constructor.

=cut

    has feed_name => (
         is => 'ro',
         required => 1,
    );

    has _file_path => (
        is => 'lazy',
        init_arg => undef,
    );

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

    method _build__file_path {
        Path::Class::File->new( map { tr/ /_/sr } $self->group_name, $self->feed_name .'.rss' );
    }


=method load_existing

    print $fs->load_existing;

Returns a L<Mojo::DOM> object initialised with the content of the previously-saved feed. If the feed has never been saved, returns a L<Mojo::DOM> object initialised with an empty string.

=cut

    method load_existing {
        $self->logger->debug( 'loading '. $self->_file_path );
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
        $self->logger->debug( 'writing out new filtered feed to '. $self->_file_path );
        my $target_dir = $self->_file_path->dir;
        if( not defined $target_dir->stat ) {
            $self->logger->debug( "no $target_dir directory! making one" );
            $target_dir->mkpath;
        }
        $self->_file_path->spew( $feed->to_xml );
        $self->_clear_last_modified;
    }

};

1;
