#!/bin/bash

export PERLBREW_ROOT=$HOME/perl5/perlbrew
export PERLBREW_HOME=$HOME/.perlbrew
source ~/perl5/perlbrew/etc/bashrc

perlbrew use perl-5.14.2@rss-dedupe
RSS_DEDUPE_DIR=`dirname "$( readlink -f "$BASH_SOURCE" )"`
mkdir -p "$RSS_DEDUPE_DIR/www"
cd "$RSS_DEDUPE_DIR/www"
perl -I "$RSS_DEDUPE_DIR/lib" "$RSS_DEDUPE_DIR/bin/rssfilter" $@ >> "$RSS_DEDUPE_DIR/log" 2>&1
