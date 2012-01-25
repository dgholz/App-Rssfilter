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

Log::Log4perl->easy_init( { level => $DEBUG } );

my $config = Load(<<"End_Of_Config");
filter:
- OmitSports
- OmitPreviews
groups:
- group: ABC
  feeds:
  - Bega 2550:      http://www.abc.net.au/news/feed/8706/rss.xml
  - South East NSW: http://www.abc.net.au/local/rss/southeastnsw/all.xml
  - NSW:            http://www.abc.net.au/news/feed/52498/rss.xml
  - Business:       http://www.abc.net.au/news/feed/51892/rss.xml
  - Top Stories:    http://www.abc.net.au/news/feed/45910/rss.xml
End_Of_Config

sub filter_items {
    my ( $feed_dom, @filters ) = @_;
    my %memo;
    @memo{ @filters } = map { Filter->can( $_ ) } @filters;
    @filters = grep { defined $memo{ $_ } } @filters;
    $feed_dom->find('item')->each(
        sub {
            my ($item) = @_;
            if ( my $filter = first { $memo{$_}->($item) } @filters ) {
                DEBUG( "$filter matched ", $item->guid->text );
                $item->title->replace_content(uc($filter) ." - ".$item->title->content_xml);
            }
        }
    );
    return $feed_dom;
}

package Filter {
    use List::MoreUtils;
    sub OmitCategory {
        my ( $item, @bad_cats ) = @_;
        my %cats =
          map { $_ => 1 } $item->find("category")->map( sub { $_->text =~ s/:.*$//r } )->each;
        return List::MoreUtils::any { defined $_ } @cats{@bad_cats};
    }

    sub OmitSports {
        push @_, qw( Sport );
        return &OmitCategory;
    }

    sub OmitPreviews {
        my ( $item ) = @_;
        return $item->guid->text =~ / preview /xms;
    }

    my %prev;
    sub OmitDupes {
        my ( $item ) = @_;
        return 1 < ++$prev{ $item->guid->text };
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
    return DateTime::Format::Strptime->new( pattern => "%a, %d %b %Y %T %z")->parse_datetime( shift )->set_time_zone("GMT")->strftime( "%a, %d %b %Y %T GMT" );
}


for my $group ( @{ $config->{groups} } ) {
    my $group_name = $group->{group};
    DEBUG( "filtering feeds in $group_name" );
    my @filters = map { @{ $_ // [] } } $config->{filter}, $group->{filter};
    push @filters, q{OmitDupes};
    if( not -d $group_name ) {
        DEBUG( "no $group_name directory! making one" );
        mkdir $group_name;
    }
    foreach my $feed ( @{ $group->{feeds} } ) {
        my ( $feed_name, $feed_url ) = each $feed;
        my ( $filename ) = map { tr/ /_/sr } Path::Class::File->new( $group_name, ( $feed_name . q{.rss} ) );
        my $old = load_existing( $filename );
        my $last_update = $old->find( 'rss channel pubDate' )->text || 'Thu, 01 Jan 1970 00:00:00 GMT';
        DEBUG( 'last update was ', $last_update );
        my $new = g( $feed_url, { 'If-Modified-Since' => to_http_date( $last_update ) } );
        if ( $new->code == 200 ) {
            DEBUG( "found a newer feed!" );
            DEBUG( "filtering $feed_name" );
            $new = filter_items( $new->dom, @filters );
            DEBUG( "collecting guids from old feed" );
            DEBUG( "writing out new filtered feed to $filename" );
            write_file( $filename, { binmode => ':utf8' }, $new->to_xml );
        }
        $old->find('item')->map( \&Filter::OmitDupes );
    }
}
