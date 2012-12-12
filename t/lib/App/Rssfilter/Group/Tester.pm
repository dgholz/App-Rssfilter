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
            );
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

    has group_name => (
        is => 'ro',
        default => sub { undef; }, # same as if no default
    );
}

1;
