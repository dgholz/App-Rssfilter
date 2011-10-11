#!/usr/bin/env perl

use strict;
use warnings;
use local::lib qw( . );
use v5.12;
use ojo;
use List::MoreUtils;
use File::Slurp;
use Path::Class::File qw( file );

my @feeds = qw( http://www.abc.net.au/news/feed/45910/rss.xml );

my $config = {
    groups => {
        ABC => {
            feeds => [
                {
                    name => 'Bega 2550',
                    url  => 'http://www.abc.net.au/news/feed/8706/rss.xml',
                },
                {
                    name => 'South East NSW',
                    url  => 'http://www.abc.net.au/local/rss/southeastnsw/all.xml',
                },
                {
                    name => 'NSW',
                    url  => 'http://www.abc.net.au/news/feed/52498/rss.xml',
                },
                {
                    name => 'Business',
                    url  => 'http://www.abc.net.au/news/feed/51892/rss.xml',
                },
                {
                    name => 'Top Stories',
                    url  => 'http://www.abc.net.au/news/feed/45910/rss.xml',
                },
            ],
            filters => [ \&omit_sports, \&omit_previews ],
        },
    },
};


sub filter_items {
    my ( $feed, @filters ) = @_;
    $feed->find('item')->each(
        sub {
            my ($item) = @_;
            if ( List::MoreUtils::any { $_->($item) } @filters ) {
                $item->replace('');
                return;
            }
        }
    );
    return $feed;
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
    my ( $item ) = @_;
    return $item->guid->text =~ / preview /xms;
}

sub omit_dupes {
    my ( $item, $prev ) = @_;
    return 1 < ++$prev->{ $item->guid->text };
}

sub load_existing {
    my ( $group_name, $feed ) = @_;
    $feed->{filename} //= Path::Class::File->new( $group_name, ( $feed->{name} . q{.rss} ) );
    $feed->{filename} =~ tr/ /_/;
    if( ! -e $feed->{filename} ) {
        write_file( $feed->{filename}, '' );
    }
    return Mojo::DOM->new( scalar read_file( $feed->{filename} ) );
}

while( my ( $name, $group ) = each $config->{groups} ) {
    my %link;
    my @filters = map { @{ $_ // [] } } $config->{filter}, $group->{filter};
    push @filters,  sub { push @_, %link; return &omit_dupes; };
    if( not -d $name ) {
        mkdir $name;
    }
    foreach my $feed ( @{ $group->{feeds} } ) {
        my @feed_filters =  map { @{ $_ // [] } } $feed->{filter}, \@filters;
        my $old = load_existing( $name, $feed );
        my $new = g( $feed->{url} )->dom;
        next if $new->find( 'rss channel pubDate' ) eq $old->find( 'rss channel pubDate' );
        $new = filter_items( $new, @filters );
        $old->find('item')->map( sub { omit_dupes( $_, \%link ) } );
        write_file( $feed->{filename}, $new->to_xml );
    }
}
