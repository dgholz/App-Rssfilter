use strict;
use warnings;
use feature qw< :5.14 >;

package App::Rssfilter::Feed::Storage::Test::LastModifiedComesFromFile {

    use Test::Routine;
    use Test::More;
    use namespace::autoclean;

    requires 'feed_storage';
    requires 'tempfile';

    test last_modified_comes_from_file => sub {
        my ( $self ) = @_;

        use HTTP::Date;
        is(
            $self->feed_storage->last_modified,
            time2str( $self->tempfile->stat->mtime ),
            'last_modified returns the last time the underlying file was modified'
        );
    };

}

1;
