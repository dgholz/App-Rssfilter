#!/bin/bash

source ~/perl5/perlbrew/etc/bashrc

RSS_DEDUPE_DIR=`dirname "$( readlink -f "$BASH_SOURCE" )"`
mkdir -p "$RSS_DEDUPE_DIR/www"
cd "$RSS_DEDUPE_DIR/www"
perl -I "$RSS_DEDUPE_DIR/lib" "$RSS_DEDUPE_DIR/bin/rssfilter" $@ >> "$RSS_DEDUPE_DIR/log" 2>&1
