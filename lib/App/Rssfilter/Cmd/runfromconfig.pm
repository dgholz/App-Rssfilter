# ABSTRACT: fetch feeds and constrain with rules, all from a config file

=head1 SYNOPSIS

    rssfilter runfromconfig [ --config-file|-f Rssfilter.yaml ] [ --log|-v ]

This command reads a configuration file in YAML format, and updates all of the groups in the file. The YAML should describe a hash whose schema matches that described in L<App::Rssfilter::FromHash/from_hash>.

=cut

use strict;
use warnings;

package App::Rssfilter::Cmd::runfromconfig;

use App::Rssfilter::Cmd -command;
use App::Rssfilter;
use Method::Signatures;
use Cwd;
use Path::Class qw<>;
use Log::Any::Adapter;

method usage_desc( $app ) {
    return $app->arg0 . ' %o';
}

=head1 OPTIONS

=head2 -f, --config-file

Path to config file; default is C<Rssfilter.yaml> in the current directory.

=head2 -v, --log

Turns on logging; default is off.

=cut

method opt_spec( $app ) {
    return (
        [ 'config-file|f:s',  'config file for App::Rssfilter (searches for RssFilter.yaml if not set)', ],
        [ 'log|v',  'turn logging on' ],
    );
}

method validate_args( $opt, $args ) { }

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
    my $yaml_config = Path::Class::file( $opt->config_file // $self->find_config );
    Log::Any::Adapter->set( 'Stdout' ) if $opt->log;
    App::Rssfilter->from_yaml( scalar $yaml_config->slurp )->update();
}

1;
