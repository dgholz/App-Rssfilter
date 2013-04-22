# ABSTRACT: create App::Rssfilter objects from YAML configuration

use strict;
use warnings;

=head1 SYNOPSIS

    {
        package Cool::Name;
        use Role::Tiny::With;
        with 'App::Rssfilter::FromYaml';

        sub new { ... }
        sub add_group { ... }
        sub add_feed { ... }
        sub add_rule { ... }
    };


    my $cool_name = Cool::Name->from_yaml(<<"End_Of_Yaml");
    name: some group

    rules:
    # add_rule will be called with ...
    - keyvalue_pair: some value
    # then ...
    - this_hashref: of options
      with_multiple: keys and values

    feeds:
    # same as rules above
    # mix elements as you please
    - keyword_pair_for_first_feed: and value
    - keyword_pair_for_second_feed: with different value
    - feed_option1: more key-value pairs
      feed_option2: which will be passed as arguments
      feed_option3: for the third call to add_feed

    groups:

    - name: a subgroup
    - # subgroups can have their own feeds, rules, and subgroups
    - feeds:
      - ...
    - rules:
      - ...
    - groups:
      - ...

    - name: 'another subgroup',
    - feeds:
      - ...
    - rules:
      - ...
    - groups:
      - ...
    End_Of_Yaml

=head1 DESCRIPTION

This role will extend its receiving class with a L</from_yaml> method. It requires that the receiver has C<add_group>, C<add_feed>, and C<add_rule> methods, and accepts a C<name> attribute to its constructor.

=cut

package App::Rssfilter::FromYaml;

use Moo::Role;
use Method::Signatures;
use YAML::XS;
requires 'from_hash';

=method from_yaml

    my $receiver_instance = Receiver::Class->from_yaml( $config );

Create a new instance of the receiving class (using the top-level C<name> in C<$config> as its name), then create subgroups and add feeds or rules to it (or its subgroups).

C<$config> may have four keys:

=for :list
* C<name>   - name of this group
* C<groups> - list of associative arrays for subgroups, same schema as the original config
* C<feeds>  - list of feeds to fetch
* C<rules>  - list of rules to apply

=cut

method from_yaml( $config ) {
    $self->from_hash( Load( $config ) );
}

1;
