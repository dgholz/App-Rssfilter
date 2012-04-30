#!/usr/bin/env perl

# ABSTRACT: Fetch and filter RSS feeds

use strict;
use warnings;
use feature qw( :5.14 );

package App::Rssfilter {

use Carp::Always;
use Carp;
use Rss::Filter;
use Log::Log4perl qw( :easy );
Log::Log4perl->easy_init( { level => $DEBUG } );

my $config;

    sub run {
        my $class;
        ( $class, $config ) = @_;

        for my $group ( requested_groups_or_everything() ) {
            Rss::Filter::update_group( $config, $group );
        }
    }

    sub requested_groups_or_everything {
        my @request = @_;
        @request = @ARGV if not @request;
        my @groups = @{ $config->{groups} };
        return @groups if not @request;
        my %groups_I_know_about = map { $_->{ group } => $_ } @groups;
        if ( my @unknown_groups  = grep { not exists $groups_I_know_about{ $_ } } @request ) {
            croak "don't know how to get groups: ". join(q{, }, @unknown_groups );
        }
        my @known_groups = grep { defined } @groups_I_know_about{ @request };
        return @known_groups ? @known_groups : @groups;
    }

}

1;
