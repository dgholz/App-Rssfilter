use strict;
use warnings;
use feature qw( :5.14 );

package Feed::Storage {

    use Method::Signatures;
    use Moo;
    use Mojo::DOM;
    use Path::Class::File;
    use HTTP::Date;

    has logger => (
        is => 'lazy',
    );

    method _build_logger {
        use Log::Log4perl qw< :levels >;
        Log::Log4perl->easy_init( { level => $DEBUG } );
        Log::Log4perl->get_logger( ref $self );
    }

    has group_name => (
         is => 'ro',
         required => 1,
    );

    has feed_name => (
         is => 'ro',
         required => 1,
    );

    has filename => (
        is => 'lazy',
    );

    has last_modified => (
        is => 'rwp',
        default => sub { time2str 0 },
    );

    method _build_filename {
        Path::Class::File->new( map { tr/ /_/sr } $self->group_name, $self->feed_name .'.rss' );
    }

    method load_existing {
        $self->logger->debug( 'loading '. $self->filename );
        my $stat = $self->filename->stat;

        return Mojo::DOM->new if not defined $stat;

        $self->_set_last_modified( time2str $stat->mtime );
        return Mojo::DOM->new( scalar $self->filename->slurp );
    }

    method save_feed( $feed ) {
        $self->logger->debug( 'writing out new filtered feed to '. $self->filename );
        my $target_dir = $self->filename->dir;
        if( not defined $target_dir->stat ) {
            $self->logger->debug( "no $target_dir directory! making one" );
            $target_dir->mkpath;
        }
        $self->filename->spew( $feed->to_xml );
    }

};

1;
