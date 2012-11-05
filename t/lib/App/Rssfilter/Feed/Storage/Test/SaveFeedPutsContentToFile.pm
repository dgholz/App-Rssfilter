use strict;
use warnings;
use feature qw< :5.14 >;

package App::Rssfilter::Feed::Storage::Test::SaveFeedPutsContentToFile {

    use Test::Routine;
    use Test::More;
    use Mojo::DOM;
    use namespace::autoclean;

    requires 'feed_storage';
    requires 'tempfile';

    test save_feed_puts_content_to_file => sub {
        my ( $self ) = @_;

        $self->feed_storage->save_feed( Mojo::DOM->new( '<well>I guess this is it</well>' ) );
        is(
            $self->tempfile->slurp,
            '<well>I guess this is it</well>',
            'save_feed writes passed DOM to underlying file'
        );
    };
}

1;