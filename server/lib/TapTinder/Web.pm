package TapTinder::Web;

use strict;
use warnings;

use Data::Dumper;

use Catalyst::Runtime '5.70';

use Catalyst qw/
    StackTrace

    Config::Multi
    Static::Simple

    Session
    Session::Store::FastMmap
    Session::State::Cookie
/;


our $VERSION = '0.03';

# Note that settings in web_*.yml take precedence over this.
# Thus configuration details given here can function as a default
# configuration, with a external configuration file acting
# as an override for local deployment.

__PACKAGE__->config(
    'Plugin::Config::Multi' => {
         dir => __PACKAGE__->path_to('./conf'),
         prefix => '',
         app_name => 'web',
         extension => 'yml',
     }
);


__PACKAGE__->setup;


=head1 NAME

TapTinder::Web - TapTinder web application

=head1 SYNOPSIS

See L<TapTinder::Web>

=head1 DESCRIPTION

TapTinder web base class based on Catalyst::Runtime.

=head1 SEE ALSO

L<TapTinder>, L<Catalyst::Runtime>

=head1 AUTHOR

Michal Jurosz <mj@mj41.cz>

=head1 LICENSE

This file is part of TapTinder. See L<TapTinder> license.

=cut


1;
