#!/usr/bin/env perl

use strict;
use warnings;
use local::lib qw( . );
use 5.010;
use ojo;
use List::MoreUtils;
use File::Slurp;

my @feeds = qw( http://www.abc.net.au/news/feed/45910/rss.xml );

sub filter_items {
    my ( $feed, @filters ) = @_;
    $feed->find('item')->each(
        sub {
            my ($item) = @_;
            say $item->link;
            if ( List::MoreUtils::any { $_->($item) } @filters ) {
                $item->replace('');
                return;
            }
        }
    );
}

sub omit_categories {
    my ( $item, @bad_cats ) = @_;
    my %cats =
      map { $_ => 1 } $item->find("category")->map( sub { $_->text } )->each;
    return List::MoreUtils::any { defined $_ } @cats{@bad_cats};
}

sub omit_sports {
    push @_, qw( Sport );
    return &omit_categories;
}

sub omit_previews {
    my ($item) = @_;
    return $item->guid->text =~ / preview /xms;
}

Mojo::Collection->new( map { g($_)->dom } @feeds )->each(
    sub {
        filter_items( $_, \&omit_sports, \&omit_previews );
        say $_->to_xml;
    }
);
