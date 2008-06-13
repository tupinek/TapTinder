package TapTinder::Web::View::TT;

use strict;
use base 'Catalyst::View::TT';

=head1 NAME

TapTinder::Web::View::TT - TapTinder TTSite View

=head1 SYNOPSIS

See L<TapTinder::Web>

=head1 DESCRIPTION

TapTinder TTSite View.

=cut

__PACKAGE__->config({
    CATALYST_VAR => 'c',
    INCLUDE_PATH => [
        TapTinder::Web->path_to( 'root', 'src' ),
        TapTinder::Web->path_to( 'root', 'lib' )
    ],
    PRE_PROCESS  => 'config/main',
    WRAPPER      => 'site/wrapper',
    ERROR        => 'error.tt2',
    TIMER        => 0,
    TEMPLATE_EXTENSION => '.tt2',
    #COMPILE_DIR => '/tmp/taptinder/cache',
});


=head1 AUTHOR

Michal Jurosz <mj@mj41.cz>

=head1 LICENSE

This file is part of TapTinder. See L<TapTinder> license.

=cut


1;
