use strict;
use warnings;
use feature qw< :5.14 >;

package App::Rssfilter::Feed::Test::ExistingFeedNotReplaced {

    use Test::Routine;
    use Test::More;
    use namespace::autoclean;
    use Method::Signatures;

    requires 'mock_storage';

    test existing_feed_not_replaced => method {
        ok(
            !$self->mock_storage->called( 'save_feed' ),
            'did not attempt to save a new feed over the existing feed'
        );
    };

}

1;
