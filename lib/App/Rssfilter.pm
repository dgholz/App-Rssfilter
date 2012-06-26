#!/usr/bin/env perl

# ABSTRACT: Fetch and filter RSS feeds

use strict;
use warnings;
use feature qw( :5.14 );

package App::Rssfilter;

use Carp;
use Rss::Filter;

sub run {
    my ( $class, $config, @requested_groups ) = @_;
    if ( not @requested_groups ) {
        @requested_groups = @ARGV;
    }

    my $rf = Rss::Filter->new( config => $config );
    for my $group ( requested_groups_or_everything( $config, @requested_groups ) ) {
        $rf->update_group( $group );
    }
}

sub requested_groups_or_everything {
    my ( $config, @request ) = @_;
    my @groups = @{ $config->{groups} };
    return @groups if not @request;
    my %groups_I_know_about = map { $_->{ group } => $_ } @groups;
    if ( my @unknown_groups  = grep { not exists $groups_I_know_about{ $_ } } @request ) {
        croak "don't know how to get groups: ". join(q{, }, @unknown_groups );
    }
    return @groups_I_know_about{ @request };
}

1;
