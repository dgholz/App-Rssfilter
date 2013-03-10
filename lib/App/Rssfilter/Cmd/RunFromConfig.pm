# ABSTRACT: Runs App::Rssfilter with a specific config

use strict;
use warnings;
use feature qw( :5.14 );

package App::Rssfilter::Cmd::RunFromConfig {
    use App::Rssfilter::Cmd -command;
    use App::Rssfilter::Group;
    use YAML::XS;
    use Method::Signatures;
    use Cwd;
    use Path::Class qw<>;

    method usage_desc( $app ) {
        return $app->arg0 . ' %o';
    }
     
    method opt_spec( $app ) {
        return (
            [ 'config-file|f',  'config file for App::Rssfilter (searches for RssFilter.yaml if not set)', ],
        );
    }
     
    method validate_args( $opt, $args ) {
    }

    method find_config( :$file = 'Rssfilter.yaml', :$dir = cwd() ) {
        $dir = Path::Class::dir->new( $dir )->absolute;
        for( reverse $dir->dir_list ) {
            my $filename = $dir->file( $file );
            return $filename if -r $filename;
            last; # directory search later
            $dir = $dir->parent;
        }
        return $file;
    }

    method execute( $opt, $args ) {
        my $yaml_config = Path::Class::file( $opt->{'config-file'} // $self->find_config );
        App::Rssfilter::Group->from_hash( Load( scalar $yaml_config->slurp ) )->update();
    }
};

1;
