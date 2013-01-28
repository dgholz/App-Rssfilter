package App::Rssfilter::Group::Tester {
    use Moo;
    use App::Rssfilter::Group;
    use Test::MockObject;

    has group => (
        is => 'lazy',
        default => sub {
            my ( $self ) = @_;
            App::Rssfilter::Group->new(
                name => $self->group_name,
                storage => $self->mock_storage,
            );
        },
    );

    has mock_storage => (
        is => 'ro',
        default => sub {
            my $mock_storage = Test::MockObject->new;
            $mock_storage->set_isa( 'App::Rssfilter::Feed::Storage' );
            return $mock_storage;
        },
    );

    has mock_rule => (
        is => 'ro',
        default => sub {
            my $mock_rule = Test::MockObject->new;
            $mock_rule->set_isa( 'App::Rssfilter::Rule' );
            return $mock_rule;
        },
    );

    has mock_feed => (
        is => 'ro',
        default => sub {
            my $mock_feed = Test::MockObject->new;
            $mock_feed->set_isa( 'App::Rssfilter::Feed' );
            $mock_feed->set_always( 'name', 'Mock Feed' );
            $mock_feed->set_always( 'url',  'http://example.com/mock.rss' );
            $mock_feed->set_true( 'update' );
            return $mock_feed;
        },
    );

    has mock_group => (
        is => 'ro',
        default => sub {
            my $mock_group = Test::MockObject->new;
            $mock_group->set_isa( 'App::Rssfilter::Group' );
            return $mock_group;
        },
    );

    has group_name => (
        is => 'ro',
        default => sub { undef; }, # same as if no default
    );
}

1;
