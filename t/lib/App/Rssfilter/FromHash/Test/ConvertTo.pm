use strict;
use warnings;
use feature qw< :5.14 >;

package App::Rssfilter::FromHash::Test::ConvertTo {

    use Test::Routine;
    use Test::Exception;
    use namespace::autoclean;
    use Method::Signatures;

    requires 'convert_to';
    requires 'fake_class_name';
    requires 'results_of_convert_to';

    test call_convert_to => method {
        lives_ok(
            sub {
                my @results = $self->convert_to( $self->fake_class_name );
                push $self->results_of_convert_to, @results;
            },
            'can call convert_to without calamity'
        );
    };

}

1;
