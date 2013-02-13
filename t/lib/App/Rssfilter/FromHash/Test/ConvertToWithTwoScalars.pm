use strict;
use warnings;
use feature qw< :5.14 >;

package App::Rssfilter::FromHash::Test::ConvertToWithTwoScalars {

    use Test::Routine;
    use Test::More;
    use namespace::autoclean;
    use Method::Signatures;
    use Test::MockObject;

    requires 'convert_to';
    requires 'fake_class';
    requires 'results_of_convert_to';

    around 'convert_to' => func( $orig, $self, $class_name, @args ) {
        my @results = $orig->( $self, $class_name, lol => 'wut', @args );
        shift @results;
        return @results;
    };

    test convert_to_with_two_scalars => method {
        my ( $name, $args ) = $self->fake_class->next_call;
        is(
            $name,
            'ctor',
            'ctor called ...'
        );

        is_deeply(
            [ @{ $args }[1,2] ],
            [ qw< lol wut > ],
            '... with the first two values passed to convert_to'
        );
    };

}

1;
