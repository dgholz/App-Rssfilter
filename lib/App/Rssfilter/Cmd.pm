# ABSTRACT: App::Rssfilter's App::Cmd

use strict;
use warnings;

package App::Rssfilter::Cmd;

use constant plugin_search_path => __PACKAGE__;
use constant default_command => 'runfromconfig';
use App::Cmd::Setup -app;

1;
