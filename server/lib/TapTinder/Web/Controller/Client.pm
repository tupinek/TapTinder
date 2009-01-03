package TapTinder::Web::Controller::Client;

use strict;
use warnings;
use base 'TapTinder::Web::ControllerBase';

use Digest::MD5 qw(md5);
use DateTime;

=head1 NAME

TapTinder::Web::Controller::Client - Catalyst Controller

=head1 DESCRIPTION

Catalyst controller for TapTinder client services.

=head1 METHODS

=head2 login_ok

Check and log login params - machine_id and password.

=cut

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


=head2 msession_ok

Check msession_id param.

=cut

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


=head2 access_allowed

Default method for all actions. Do base checks (L<login_ok|login_ok>, L<msession_ok|msession_ok>);

=cut

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


=head2 check_param

Method checks mandatory param. Sets error message if value is empty.

=cut

sub check_param {
    my ( $self, $c, $data, $action_name, $params, $key, $key_desc ) = @_;

    unless ( $params->{$key} ) {
        $data->{$action_name . '_err'} = 1;
        $data->{$action_name . '_err_msg'} = "Error: Parameter $key ($key_desc) required.";
        return 0;
    }
    return 1;
}


=head2 create_mslog

Create new machine session log (mslog) entry.

=cut

sub create_mslog {
    my (
        $self, $c, $data, $action_name,
        $msession_id, $msstatus_id,
        $attempt_number, $change_time, $estimated_finish_time
    ) = @_;

    my $rs = $c->model('WebDB::mslog')->create({
        msession_id             => $msession_id,
        msstatus_id             => $msstatus_id,
        attempt_number          => $attempt_number,
        change_time             => $change_time,
        estimated_finish_time   => $estimated_finish_time,
    });
    unless ( $rs ) {
        $data->{$action_name.'_err'} = 1;
        $data->{$action_name.'_err_msg'} = "Error: Create mslog entry failed."; # TODO
        return 0;
    }
    return 1;
}


=head2 cmd_mscreate

Create new machine session (msession).

=cut

sub cmd_mscreate {
    my ( $self, $c, $data, $params ) = @_;

    # $params->{mid} - already checked
    my $machine_id = $params->{mid};

    $self->check_param( $c, $data,'mscreate', $params, 'crev', 'client code revision' ) || return 0;
    my $client_rev = $params->{crev};

    $self->check_param( $c, $data, 'mscreate', $params, 'pid', 'client process ID' ) || return 0;
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
        return 0;
    }
    my %cols = $msession_rs->get_columns();
    my $msession_id = $cols{msession_id};

    # create mslog
    my $ret_code = $self->create_mslog(
        $c, $data, 'mscreate',
        $msession_id,
        2, # $msstatus_id, 2 .. msession just created
        1, # $attempt_number
        DateTime->now, # $change_time
        undef # $estimated_finish_time
    ) || return 0;

    $data->{mscreate_msid} = $msession_id;
    $data->{mscreate_err} = 0;
    return 1;
}


=head2 cmd_msdestroy

Destroy machine session (msession).

=cut

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
        return 0;
    }

    # TODO
    # * check msjob, ...

    # create mslog
    my $ret_code = $self->create_mslog(
        $c, $data, 'msdestroy',
        $msession_id,
        6, # $msstatus_id, 6 .. stop by user
        1, # $attempt_number
        DateTime->now, # $change_time
        undef # $estimated_finish_time
    ) || return 0;

    $data->{msdestroy_err} = 0;
    return 1;
}


=head2 process_action

Process all params but 'ot'.

=cut

sub process_action {
    my ( $self, $c, $action, $params ) = @_;

    my $data : Stashed = {};

    $data->{is_debug} = 1 if $c->log->is_debug;

    if ( $params->{ot} eq 'html' && $c->log->is_debug ) {
        my $ot : Stashed = '';
        $self->dumper( $c, $params );

        # [% dumper(data) | html %]
        $c->stash->{dumper} = sub { DBIx::Dumper::Dumper( $_[0] ); };
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


=head2 index

Use params:

ot - output type, allowed 'html' and 'json', default 'json'

=cut


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
