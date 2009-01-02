package TapTinder::Web::Controller::Client;

use strict;
use warnings;
use base 'Catalyst::Controller::BindLex';

use DBIx::Dumper qw/Dumper dump_row/;
use Digest::MD5 qw(md5);

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
    my ( $self, $c, $data, $machine_id, $passwd ) = @_;

    my $passwd_md5 = substr( md5($passwd), -8); # TODO - refactor to own module
    my $rs = $c->model('WebDB::machine')->search(
        {
            machine_id => $machine_id,
            passwd => $passwd_md5,
        }
    );
    my $row = $rs->next;
    if ( !$row ) {
        $data->{login_ok} = 0;
        $data->{login_msg} = 'Error: Bad login or password.';
        return 0;
    }

    $self->dumper( $c, { $row->get_columns() } );
    $data->{login_ok} = 1;
    $data->{login_msg} = 'Ok.';
    return 1;
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

    $self->access_allowed( $c, $data, $params->{mid}, $params->{pass} ) || return;

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
