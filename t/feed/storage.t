use strict;
use warnings;
use feature qw( :5.14 );

use Test::Most;

use Feed::Storage;
use File::Temp qw< tempfile >;
use Path::Class;
use Mojo::DOM;
use Log::Log4perl qw< :levels >;

my $feed;

$feed = Feed::Storage->new(
    group_name => 'hi',
    feed_name  => 'hello',
);
$feed->logger->level( $OFF );

is(
    $feed->filename,
    Path::Class::File->new( 'hi', 'hello.rss' ),
    'sets filename from group & feed name'
);

$feed = Feed::Storage->new(
    group_name => 'a bean',
    feed_name  => 'lima bean',
);
$feed->logger->level( $OFF );

is(
    $feed->filename,
    Path::Class::File->new( 'a_bean', 'lima_bean.rss' ),
    'replaces spaces with underscores'
);

throws_ok(
    sub { $feed->load_existing( qw< one > ) },
    qr/too many arguments/,
    'throws error when given a filename to load'
);

is(
    $feed->load_existing,
    Mojo::DOM->new,
    'returns empty DOM if filename referes to a non-existant file'
);

my $tmp_dir = File::Temp->newdir;
my ($fh, $filename) = tempfile( DIR => $tmp_dir );
my $tmp = Path::Class::File->new( $filename );
$feed = Feed::Storage->new(
    group_name => undef,
    feed_name  => undef,
    filename   => $tmp,
);
$feed->logger->level( $OFF );
$tmp->spew('<surprise>your favourite bean</surprise>');

is(
    $feed->load_existing,
    Mojo::DOM->new( '<surprise>your favourite bean</surprise>'),
    'load_existing returns DOM representation of existing content if filname refers to a existing file'
);

throws_ok(
    sub { $feed->save_feed },
    qr/missing required argument/,
    'throws error when not given a feed to save'
);

throws_ok(
    sub { $feed->save_feed( qw< one two > ) },
    qr/too many arguments/,
    'throws error when given more than one feed to save'
);

$feed->save_feed( Mojo::DOM->new( '<well>I guess this is it</well>' ) );
is(
    $tmp->slurp,
    '<well>I guess this is it</well>',
    'save_feed writes passed DOM to file referred to by filename'
);

$tmp->dir->rmtree;
$feed->save_feed( Mojo::DOM->new( '<make>noise, a phone call</make>' ) );
is(
    $tmp->slurp,
    '<make>noise, a phone call</make>',
    'save_feed creates a directory if it doesn\'t exist'
);

done_testing;
