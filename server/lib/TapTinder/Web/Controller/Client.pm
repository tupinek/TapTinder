package TapTinder::Web::Controller::Client;

use strict;
use warnings;
use base 'Catalyst::Controller::BindLex';

use DBIx::Dumper qw/Dumper dump_row/;

=head1 NAME

TapTinder::Web::Controller::Client - Catalyst Controller

=head1 DESCRIPTION

Catalyst controller for TapTinder client services.

=head1 METHODS

=cut

=head2 index

=cut


sub dadd {
    my $self = shift;
    my $c = shift;
    my $str = shift;
    $c->stash->{ot} .= $str;
}


sub dumper {
    my $self = shift;
    my $c = shift;
    $c->stash->{ot} .= Dumper( @_ );
}


sub access_allowed {
    my ( $self, $data, $user_id, $passwd ) = @_;

    $data->{login_ok} = 1;

    $data->{login_ok} = 0;
    $data->{login_msg} = 'Ok.';
}


sub process_action {
    my ( $self, $c, $action, $params ) = @_;

    my $data : Stashed = {};

    $data->{is_debug} = 1 if $c->log->is_debug;

    if ( $params->{ot} eq 'html' && $c->log->is_debug ) {
        my $ot : Stashed = '';
        $self->dumper( $c, $params );

        # [% dumper(data) | html %]
        $c->stash->{dumper} = sub { Dumper( $_[0] ); };
    }

    $self->access_allowed( $data, $params->{uid}, $params->{pass} ) || return;

    return;
}


sub index : Path  {
    my ( $self, $c, $action, @args ) = @_;

    my $params = $c->request->params;
    $self->process_action( $c, $action, $params );

    if ( $params->{ot} eq 'html' ) {
        return;
    }
    $c->forward('TapTinder::Web::View::JSON');
}


=head1 SEE ALSO

L<TapTinder::Web>, L<Catalyst::Controller>

=head1 AUTHOR

Michal Jurosz <mj@mj41.cz>

=head1 LICENSE

This file is part of TapTinder. See L<TapTinder> license.

=cut


1;
