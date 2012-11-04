use strict;
use warnings;
use feature qw( :5.14 );

package App::Rssfilter::Feed::Storage::Tester {

    use Test::Most;

    use App::Rssfilter::Feed::Storage;
    use File::Temp;
    use Path::Class;
    use Mojo::DOM;
    use Moo;

    has feed_storage => (
        is => 'lazy',
        default => sub {
            my ( $self ) = @_;
            App::Rssfilter::Feed::Storage->new(
                group_name => $self->group_name,
                feed_name  => $self->feed_name,
            );
        },
    );

    has group_name => (
        is => 'lazy',
        default => sub {
            my ( $self ) = @_;
            $self->tempdir;
        },
    );

    has feed_name => (
        is => 'lazy',
        default => sub {
            my ( $self ) = @_;
            $self->tempfile->basename =~ s/ [.] rss \z //xmsr;
        },
    );

    has tempdir => (
        is => 'ro',
        default => sub {
            File::Temp->newdir;
        },
    );

    has tempfile => (
        is => 'lazy',
        default => sub {
            my ( $self ) = @_;
            File::Temp->new( DIR => $self->tempdir, SUFFIX => '.rss' );
        },
    );

    around tempfile => sub {
        my ( $orig, @args ) = @_;
        Path::Class::File->new( $orig->( @args )->filename );
    };

=begin

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

    my $updated_timestamp = time + 100;
    utime 0, $updated_timestamp, $tmp;

    is(
        str2time( $feed->last_modified ),
        $updated_timestamp,
        'last_modified is cleared when content is saved'
    );

    utime 0, $updated_timestamp + 100, $tmp;

    is(
        str2time( $feed->last_modified ),
        $updated_timestamp,
        'last_modified does not change when content has not been saved or loaded'
    );

    $feed->load_existing;

    is(
        str2time( $feed->last_modified ),
        $updated_timestamp + 100,
        'last_modified is cleared when conent is loaded'
    );


    $tmp->dir->rmtree;
    $feed->save_feed( Mojo::DOM->new( '<make>noise, a phone call</make>' ) );
    is(
        $tmp->slurp,
        '<make>noise, a phone call</make>',
        'save_feed creates a directory if it doesn\'t exist'
    );

=cut

}

1;
