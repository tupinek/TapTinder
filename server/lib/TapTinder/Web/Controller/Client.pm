package TapTinder::Web::Controller::Client;

use strict;
use warnings;
use base 'Catalyst::Controller::BindLex';

use DBIx::Dumper qw/Dumper dump_row/;
use Digest::MD5 qw(md5);
use DateTime;

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
    return unless $c->log->is_debug;
    $c->stash->{ot} .= Dumper( @_ );
}


sub login_ok {
    my ( $self, $c, $data, $machine_id, $passwd ) = @_;

    my $passwd_md5 = substr( md5($passwd), -8); # TODO - refactor to own module
    my $rs = $c->model('WebDB::machine')->search( {
        machine_id => $machine_id,
        passwd => $passwd_md5,
    } );
    my $row = $rs->next;
    if ( !$row ) {
        $data->{ag_err} = 1;
        $data->{ag_err_msg} = "Error: Bad login or password.";
        return 0;
    }

    #$self->dumper( $c, { $row->get_columns() } );
    return 1;
}


sub msession_ok {
    my ( $self, $c, $data, $machine_id, $msession_id ) = @_;

    my $rs = $c->model('WebDB::msession')->search( {
        msession_id => $msession_id,
    } );
    my $row = $rs->next;
    if ( !$row ) {
        $data->{ag_err} = 1;
        $data->{ag_err_msg} = "Error: Msession (msession_id=$msession_id) not found.";
        return 0;
    }

    my %cols = $row->get_columns();
    if ( $cols{machine_id} != $machine_id ) {
        $data->{ag_err} = 1;
        $data->{ag_err_msg} = "Error: Msession msession_id=$msession_id is not machine_id=$machine_id session.";
        return 0;
    }

    if ( $cols{abort_reason_id} ) {
        $data->{ag_err} = 1;
        $data->{ag_err_msg} = "Error: Msession msession_id=$msession_id was aborted.";
        $data->{ag_err_msesion_abort_reason_id} = $cols{abort_reason_id};
        return 0;
    }

    if ( $cols{end_time} ) {
        $data->{ag_err} = 1;
        $data->{ag_err_msg} = "Error: Msession msession_id=$msession_id already ended.";
        return 0;
    }

    return 1;
}


sub access_allowed {
    my ( $self, $c, $data, $params, $param_msid_checks ) = @_;

    unless ( $params->{mid} ) {
        $data->{ag_err} = 1;
        $data->{ag_err_msg} = "Error: Parameter mid (machine.machine_id) required.";
        return 0;
    }
    my $machine_id = $params->{mid};

    unless ( $params->{pass} ) {
        $data->{ag_err} = 1;
        $data->{ag_err_msg} = "Error: Parameter pass (machine.passwd) required.";
        return 0;
    }
    my $passwd = $params->{pass};

    my $login_ok = $self->login_ok( $c, $data, $machine_id, $passwd );
    return 0 unless $login_ok;


    if ( $param_msid_checks && not $params->{msid} ) {
        $data->{ag_err} = 1;
        $data->{ag_err_msg} = "Error: Parameter msid (msession.msession_id) required.";
        return 0;
    }
    my $msession_id = $params->{msid};

    if ( $msession_id ) {
        my $login_ok = $self->msession_ok( $c, $data, $machine_id, $msession_id );
        return 0 unless $login_ok;
    }

    $data->{ag_err} = 0;
    return 1;
}


sub check_param {
    my ( $self, $c, $data, $params, $action, $key, $key_desc ) = @_;

    unless ( $params->{$key} ) {
        $data->{$action . '_err'} = 1;
        $data->{$action . '_err_msg'} = "Error: Parameter $key ($key_desc) required.";
        return 0;
    }
    return 1;
}


sub cmd_mscreate {
    my ( $self, $c, $data, $params ) = @_;

    # $params->{mid} - already checked
    my $machine_id = $params->{mid};

    $self->check_param( $c, $data, $params, 'mscreate', 'crev', 'client code revision' ) || return 0;
    my $client_rev = $params->{crev};

    $self->check_param( $c, $data, $params, 'mscreate', 'pid', 'client process ID' ) || return 0;
    my $pid = $params->{pid};

    my $msession_rs = $c->model('WebDB::msession')->create({
        machine_id  => $machine_id,
        client_rev  => $client_rev,
        pid         => $pid,
        start_time  => DateTime->now,
    });
    if ( ! $msession_rs ) {
        $data->{mscreate_err} = 1;
        $data->{mscreate_err_msg} = "Error: xxx"; # TODO
        return 1;
    }

    my %cols = $msession_rs->get_columns();
    $data->{mscreate_msid} = $cols{msession_id};
    $data->{mscreate_err} = 0;
    return 1;
}


sub cmd_msdestroy {
    my ( $self, $c, $data, $params ) = @_;

    # $params->{msid} - already checked
    my $msession_id = $params->{msid};

    my $abort_reason_id = 5; # iterrupted by user

    my $msession_rs = $c->model('WebDB::msession')->search( {
        msession_id => $msession_id,
    } );

    my $ret_val = $msession_rs->update( {
        end_time => DateTime->now,
        abort_reason_id => $abort_reason_id,
    } );

    unless ( $ret_val ) {
        $data->{msdestroy_err} = 1;
        $data->{msdestroy_err_msg} = "Error: ... (ret_val=$ret_val)."; # TODO
        return 1;
    }
    $data->{msdestroy_err} = 0;
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

    my $param_msid_checks;
         if ( $action eq 'login' )      { $param_msid_checks = 0;
    } elsif ( $action eq 'mscreate' )   { $param_msid_checks = 0;
    } elsif ( $action eq 'msdestroy' )  { $param_msid_checks = 1;
    } elsif ( $action eq 'cget' )       { $param_msid_checks = 1;
    } elsif ( $action eq 'sset' )       { $param_msid_checks = 1;
    } elsif ( $action eq 'rset' )       { $param_msid_checks = 1;
    } else {
        $data->{err} = 1;
        $data->{err_msg} = "Error: Unknow action '$action'.";
        return 0;
    }

    my $access_ok = $self->access_allowed( $c, $data, $params, $param_msid_checks );

    my $cmd_ret_code = undef;
    if ( $access_ok ) {
        if ( $action eq 'mscreate' ) {
            $cmd_ret_code = $self->cmd_mscreate( $c, $data, $params );

        } elsif ( $action eq 'msdestroy' ) {
            $cmd_ret_code = $self->cmd_msdestroy( $c, $data, $params );

        } elsif ( $action eq 'cget' ) {

        } elsif ( $action eq 'sset' ) {

        } elsif ( $action eq 'rset' ) {

        }
    }

    return 1;
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
