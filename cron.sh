#!/bin/bash

RSS_DEDUPE_DIR=`dirname "$( readlink -f "$BASH_SOURCE" )"`
$RSS_DEDUPE_DIR/strip_sports.pl >> $RSS_DEDUPE_DIR/log 2>&1
