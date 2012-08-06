use Test::Most;
use Rss::Filter;

use Test::MockObject::Extends;

my $rf = Rss::Filter->new;
use Log::Log4perl qw< :levels >;
$rf->logger->level( $OFF );


Test::MockObject::Extends->new( $rf );
$rf->set_true( 'update_feed' );

my $fake_group = {
  group => 'El Pollo del Mar',
  feeds => [
    { q{L'Idiot}   => 'http://chic.kn/' },
    { pointy_birds => 'http://an.oi/nt' },
  ],
};
$rf->update_group( $fake_group );

my ( $name, $args );
( $name, $args ) = $rf->next_call;

is(
    $name,
    'update_feed',
    'update_group calls update feed ...'
);

is(
    $args->[1],
    $fake_group,
    '... with the given group ...'
);

is_deeply(
    $args->[2],
    { q{L'Idiot}   => 'http://chic.kn/' },
    '... and the first feeds of the group ...'
);

( $name, $args ) = $rf->next_call;
is(
    $name,
    'update_feed',
    '... followed by calling update_feed again ...'
);

is(
    $args->[1],
    $fake_group,
    '... with the given group ...'
);

is_deeply(
    $args->[2],
    { pointy_birds => 'http://an.oi/nt' },
    '... and the second feed of the group ...'
);

( $name, $args ) = $rf->next_call;
is(
    $name,
    undef,
    q{... and that's all folks}
);

done_testing;
