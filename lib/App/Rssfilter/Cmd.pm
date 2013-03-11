# ABSTRACT: command-line application class for App::Rssfilter

use strict;
use warnings;
use feature qw< :5.14 >;

package App::Rssfilter::Cmd {
    use constant plugin_search_path => __PACKAGE__;
    use constant default_command => 'runfromconfig';
    use App::Cmd::Setup -app;
};

1;
