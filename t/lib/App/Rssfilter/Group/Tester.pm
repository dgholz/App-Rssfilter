package App::Rssfilter::Group::Tester {
    use Moo;
    use App::Rssfilter::Group;
    use Test::MockObject;

    has group => (
        is => 'lazy',
        default => sub {
            my ( $self ) = @_;
            App::Rssfilter::Group->new;
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
}

1;
