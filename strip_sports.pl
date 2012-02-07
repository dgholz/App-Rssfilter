#!/usr/bin/env perl

use strict;
use warnings;
use feature qw( :5.14 );
use ojo;
use List::Util qw( first );
use List::MoreUtils;
use File::Slurp;
use Path::Class::File qw( file );
use Log::Log4perl qw( :easy );
use YAML::Any;
use DateTime::Format::Strptime;
use Try::Tiny;
use Carp::Always;
use Carp;

Log::Log4perl->easy_init( { level => $DEBUG } );

my $config = Load(<<"End_Of_Config");
groups:
- group: ABC
  filter:
  - MatchAbcSports
  - MatchAbcPreviews
  ifFilterMatched: DeleteItem
  feeds:
  - Bega 2550:      http://www.abc.net.au/news/feed/8706/rss.xml
  - South East NSW: http://www.abc.net.au/local/rss/southeastnsw/all.xml
  - NSW:            http://www.abc.net.au/news/feed/52498/rss.xml
  - Business:       http://www.abc.net.au/news/feed/51892/rss.xml
  - Top Stories:    http://www.abc.net.au/news/feed/45910/rss.xml
- group: BBC
  filter:
  - MatchBbcSports
  ifFilterMatched: MarkTitle
  feeds:
  - Edinburgh East and Fife: http://feeds.bbci.co.uk/news/scotland/edinburgh_east_and_fife/rss.xml
End_Of_Config

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

sub filter_items {
    my ( $feed_dom, $match_cb, @filters ) = @_;
    my %memo;
    @memo{ @filters } = map { Filter->can( $_ ) } @filters;
    @filters = grep { defined $memo{ $_ } } @filters;
    $feed_dom->find('item')->each(
        sub {
            my ($item) = @_;
            if ( my $filter = first { $memo{$_}->($item) } @filters ) {
                DEBUG( "will $match_cb since $filter matched ", $item->guid->text );
                Filter->can( $match_cb )->( $item, $filter );
            }
        }
    );
    return $feed_dom;
}

package Filter {
    use List::MoreUtils;
    sub MatchAbcCategory {
        my ( $item, @bad_cats ) = @_;
        my %cats =
          map { $_ => 1 } $item->find("category")->map( sub { $_->text =~ s/:.*$//r } )->each;
        return List::MoreUtils::any { defined $_ } @cats{@bad_cats};
    }

    sub MatchAbcSports {
        push @_, qw( Sport );
        return &MatchAbcCategory;
    }

    sub MatchAbcPreviews {
        my ( $item ) = @_;
        return $item->guid->text =~ / preview /xms;
    }

    sub MatchBbcSports {
        my ( $item ) = @_;
        return $item->guid->text =~ qr{ www [.] bbc [.] co [.] uk / sport [1]? / }xms;
    }

    sub MatchDupes {
        my ( $item ) = @_;
        state %prev;
        my $link = $item->guid->text;
        my $url  = $item->link->text =~ s/ [?] .* \z//xmsr;
        my $res  = grep { defined } @prev{ $link, $url };
        @prev{ $link, $url } = ( 1, 1 );
        return 0 < $res;
    }

    sub MarkTitle {
        my ( $item, $filter ) = @_;
        $item->title->replace_content(uc($filter) ." - ".$item->title->content_xml);
    }

    sub DeleteItem {
        my ( $item, $filter ) = @_;
        $item->replace(q{});
    }

};

sub load_existing {
    my ( $filename ) = @_;
    DEBUG( "loading $filename ..." );
    if( ! -e $filename ) {
        return Mojo::DOM->new;
    }
    return Mojo::DOM->new( scalar read_file( $filename ) );
}

sub to_http_date {
    my ( $datetime_str ) = @_;
    my $datetime;
try {
        $datetime = DateTime::Format::Strptime->new( on_error => 'croak', pattern => "%a, %d %b %Y %T %z")->parse_datetime( $datetime_str );
} catch {
        $datetime = DateTime::Format::Strptime->new( on_error => 'croak', pattern => "%a, %d %b %Y %T %Z")->parse_datetime( $datetime_str );
};
    return $datetime->set_time_zone("GMT")->strftime( "%a, %d %b %Y %T %Z" );
}

sub update_group {
    my ( $group ) = @_;
    my $group_name = $group->{group};
    DEBUG( "filtering feeds in $group_name" );
    my @filters = map { @{ $_ // [] } } $group->{filter}, $config->{filter};
    push @filters, q{MatchDupes};
    my $matching_filter_cb = first { defined } map { $_->{ifFilterMatched} } $group, $config;
    $matching_filter_cb //= q{MarkTitle};
    if( not -d $group_name ) {
        DEBUG( "no $group_name directory! making one" );
        mkdir $group_name;
    }
    foreach my $feed ( @{ $group->{feeds} } ) {
        update_feed( $group, $feed, $matching_filter_cb, @filters );
    }
}

sub update_feed {
    my ( $group, $feed, $matching_filter_cb, @filters ) = @_;
    my ( $feed_name, $feed_url ) = each $feed;
    my ( $filename ) = map { tr/ /_/sr } Path::Class::File->new( $group->{name}, ( $feed_name . q{.rss} ) );
    my $old = load_existing( $filename );
    my $last_modified = 'Thu, 01 Jan 1970 00:00:00 +0000';
    if ( my $last_update = try { $old->at( 'rss > channel > lastBuildDate, pubDate' ) } ) {
        $last_modified = $last_update->text || $last_modified;
    }
    DEBUG( 'last update was ', $last_modified );
    my $new = g( $feed_url, { 'If-Modified-Since' => to_http_date( $last_modified ) } );
    if ( $new->code == 200 ) {
        DEBUG( "found a newer feed! ", $new->dom->at('rss > channel > lastBuildDate, pubDate')->text );
        DEBUG( "filtering $feed_name" );
        $new = filter_items( $new->dom, $matching_filter_cb, @filters );
        DEBUG( "collecting guids from old feed" );
        DEBUG( "writing out new filtered feed to $filename" );
        write_file( $filename, { binmode => ':utf8' }, $new->to_xml );
    }
}

for my $group ( requested_groups_or_everything() ) {
    update_group( $group );
}
