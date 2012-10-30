use strict;
use warnings;
use feature qw< :5.14 >;

package App::Rssfilter::Feed::Test::AddedRule {

    use Test::Routine;
    use Test::More;
    use namespace::autoclean;

    requires 'mock_rule';
    requires 'feed';

    test added_rule => sub {
        my ( $self ) = @_;
        my $pre_add_mock_rule_count =
            grep { $self->mock_rule eq $_ } @{ $self->feed->rules };

        is(
            $self->feed->add_rule( $self->mock_rule ),
            $self->feed,
            'adding rule to feed returns the feed object (for chaining)'
        );

        my $mock_rule_count = 
            grep { $self->mock_rule eq $_ } @{ $self->feed->rules };
        is(
            $mock_rule_count - $pre_add_mock_rule_count,
            1,
            q{rule has been added to the feed's list of rules}
        );
    };

    test created_and_added_rule => sub {
        my ( $self ) = @_;
        my $match  = sub {};
        my $filter = sub {};
        $self->feed->add_rule( match => $match, filter => $filter );

        my $created_rule = $self->feed->rules->[-1];
        is( $created_rule->_match,  $match,  'add_rule passed options ...' );
        is( $created_rule->_filter, $filter, '... to App::Rssfilter::Rule->new()' );

    };

}

1;
