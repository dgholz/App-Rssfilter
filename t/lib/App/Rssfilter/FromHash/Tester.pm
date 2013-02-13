package App::Rssfilter::FromHash::Tester {

    use Moose;
    with 'App::Rssfilter::FromHash';
    use Method::Signatures;

    method add_feed( @_ ) {
    }

    method add_rule( @_ ) {
    }

    method add_group( @_ ) {
    }

    has fake_class_name => (
        is => 'ro',
        default => sub { 'fake_class'; },
    );

    has fake_class => (
        is => 'ro',
        default => method {
            my $name = $self->fake_class_name;
            my $fake_class = Test::MockObject->new();
            $fake_class->set_always( ctor => $fake_class );
            $fake_class->fake_module( $name, new => method( @_ ) { $fake_class->ctor( @_ ) } );
            return $fake_class;
        },
    );

    has results_of_convert_to => (
        is => 'rw',
        default => sub { [ ] },
    );

}

1;
