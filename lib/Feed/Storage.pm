use strict;
use warnings;
use feature qw( :5.14 );

package Feed::Storage {

    use File::Slurp;
    use Method::Signatures;
    use Moo;
    use Mojo::DOM;
    use Path::Class::File;

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

    method _build_filename {
        Path::Class::File->new( $self->group_name, $self->feed_name .'.rss' ) =~ tr/ /_/sr ;
    }

    method load_existing {
        $self->logger->debug( 'loading '. $self->filename );
        if( ! -e $self->filename ) {
            return Mojo::DOM->new;
        }
        return Mojo::DOM->new( scalar read_file( $self->filename ) );
    }

    method save_feed( $feed ) {
        $self->logger->debug( 'writing out new filtered feed to '. $self->filename );
        if( not -d $self->group_name ) {
            $self->logger->debug( 'no '. $self->group_name .' directory! making one' );
            mkdir $self->group_name;
        }
        write_file( $self->filename, $feed->to_xml )
    }
};

1;
