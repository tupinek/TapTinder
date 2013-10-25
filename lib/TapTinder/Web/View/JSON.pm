package TapTinder::Web::View::JSON;

# ABSTRACT: TapTinder JSON site view.

use base 'Catalyst::View::JSON';
use strict;

=head1 SYNOPSIS

See L<TapTinder::Web>

=head1 DESCRIPTION

TapTinder JSON Site View.

=cut

__PACKAGE__->config({
    #allow_callback  => 1,    # defaults to 0
    #callback_param  => 'cb', # defaults to 'callback'
    expose_stash    => [ qw(data ot) ], # defaults to everything
    #no_x_json_header => 1,
});


1;
