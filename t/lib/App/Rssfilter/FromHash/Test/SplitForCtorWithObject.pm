use strict;
use warnings;
use feature qw< :5.14 >;

package App::Rssfilter::FromHash::Test::ConvertToWithObject {

    use Test::Routine;
    use Test::More;
    use namespace::autoclean;
    use Method::Signatures;

    requires 'convert_to';
    requires 'fake_class';
    requires 'fake_class_name';
    requires 'results_of_convert_to';

    has mock_object => (
        is => 'ro',
        default => method {
            my $mock_object = Test::MockObject->new();
            $mock_object->set_isa( $self->fake_class_name );
            return $mock_object;
        },
    );

    around 'convert_to' => func( $orig, $self, $class_name, @args ) {
        my @results = $orig->( $self, $class_name, $self->mock_object, @args );
        return @results;
    };

    test convert_to_with_object => method {
        is_deeply(
            [ $self->results_of_convert_to->[0] ],
            [ $self->mock_object ],
            'returned the already-constructed object',
        );
    };

}

1;
