#!/usr/bin/env perl

use strict;
use warnings;
use List::MoreUtils;
use 5.010;
use ojo;

my @feeds = qw( http://www.abc.net.au/news/feed/45910/rss.xml );
my @bad_cats = qw( Sport );

foreach my $feed ( map { g( $_ ) } @feeds ) {
    my @will_delete;
    foreach my $item ( map { $_->dom->find("item")->each } $feed ) {
        my %cats = map { $_ => 1 } $item->find("category")->map( sub { $_->text } )->each;
        if( List::MoreUtils::any { defined $_ } @cats{ @bad_cats } ) {
            say "DELETEING ", $item->at("description")->text;
            $item->tree->[3] = $item->tree;
            $item->replace("");
            use Data::Dumper;
            print Dumper $item;
        }
    }
    say $feed->dom->to_xml;
}
