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

    has _file_path => (
        is => 'lazy',
        init_arg => undef,
    );

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

    method load_existing {
        $self->logger->debug( 'loading '. $self->_file_path );
        my $stat = $self->_file_path->stat;

        return Mojo::DOM->new if not defined $stat;

        $self->_clear_last_modified;
        return Mojo::DOM->new( scalar $self->_file_path->slurp );
    }

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
