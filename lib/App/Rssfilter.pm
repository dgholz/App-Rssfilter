# ABSTRACT: Fetch and filter RSS feeds

=head1 SYNOPSIS

    use App::RssFilter;

    my $rssfilter = App::RssFilter->new;
    $rssfilter->add_group( 'hi' );
    my $hello_group = $rssfilter->add_group( 'hello' );

    my $dupe_rule = $rssfilter->group( 'hi' )->add_rule( Duplicate => 'DeleteItem' );
    $hello_group->add_rule( condition => 'Category[Politics]', action => 'MarkTitle' );
    $hello_group->add_rule( $dupe_rule );

    $rssfilter->group( 'hi' )->add_feed( WashPost => 'http://feeds.washingtonpost.com/rss/national' );
    $rssfilter->group( 'hi' )->add_feed( name => 'Pravda', url => 'http://english.pravda.ru/russia/export.xml' );

    $hello_group->add_feed( $rssfilter->group( 'hi' )->feed( 'WashPost' ) );

    $rssfilter->run;

=head1 DESCRIPTION

=cut



=head1 SEE ALSO

=for :list
* L<App::RssFilter::Group>
* L<App::RssFilter::Rule>
* L<App::RssFilter::Feed>

=cut



use strict;
use warnings;
use feature qw( :5.14 );

package App::Rssfilter;

use Carp;

sub run {
    my ( $class, $config, @requested_groups ) = @_;
    if ( not @requested_groups ) {
        @requested_groups = @ARGV;
    }

    my $rf = Rss::Filter->new;
    for my $group ( requested_groups_or_everything( $config, @requested_groups ) ) {
        $rf->update_group( $group );
    }
}

sub requested_groups_or_everything {
    my ( $config, @request ) = @_;
    my @groups = @{ ${ $config }{groups} };
    return @groups if not @request;
    my %groups_I_know_about = map { ${ $_ }{ group } => $_ } @groups;
    if ( my @unknown_groups  = grep { not exists $groups_I_know_about{ $_ } } @request ) {
        croak "don't know how to get groups: ". join(q{, }, @unknown_groups );
    }
    return @groups_I_know_about{ @request };
}

1;
