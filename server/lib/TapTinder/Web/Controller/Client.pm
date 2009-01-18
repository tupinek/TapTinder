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

# TODO - temporary solution
# dbix-class bug, see commented code in Taptinder::DB::SchemaAdd
sub CreateMyResultSets {
    my ( $self, $c ) = @_;

    my $source = TapTinder::DB::Schema::job->result_source_instance;
    my $new_source = $source->new($source);
    $new_source->source_name('NotTestedJobs');

    $new_source->name(\<<'');
(
    select a_r.*
      from (
            select a_jp.job_id,
                   a_jp.jobp_id,
                   a_jp.rep_path_id,
                   r.rev_id,
                   r.rev_num,
                   a_jp.priority,
                   j.priority as jpriority
              from (
                    select distinct sa_jp.*
                      from (
                            ( select jp.jobp_id, mjc.priority, jp.rep_path_id, jp.job_id
                                from machine_job_conf mjc,
                                     rep_path rp,
                                     jobp jp
                               where mjc.machine_id = ?
                                 and rp.rep_id = mjc.rep_id
                                 and jp.rep_path_id = rp.rep_path_id
                            )
                            union all
                            ( select jp.jobp_id, mjc.priority, jp.rep_path_id, jp.job_id
                                from machine_job_conf mjc,
                                     jobp jp
                               where mjc.machine_id = ?
                                 and mjc.rep_path_id is not null
                                 and jp.rep_path_id = mjc.rep_path_id
                            )
                            union all
                            ( select jp.jobp_id, mjc.priority, jp.rep_path_id, jp.job_id
                                from machine_job_conf mjc,
                                     jobp jp
                               where mjc.machine_id = ?
                                 and mjc.job_id is not null
                                 and jp.job_id = mjc.job_id
                            )
                           ) sa_jp
                  ) a_jp,
                  rev_rep_path rrp,
                  rev r,
                  job j
            where rrp.rep_path_id = a_jp.rep_path_id
              and r.rev_id = rrp.rev_id
              and j.job_id = a_jp.job_id
            order by a_jp.priority, j.priority, r.rev_num desc, a_jp.jobp_id
          ) a_r
    where not exists (
            select 1
              from msjob msj,
                   msjobp msjp,
                   jobp jp
             where msj.msession_id = ?
               and msjp.msjob_id = msj.msjob_id
               and jp.jobp_id = msjp.jobp_id
               and jp.rep_path_id = a_r.rep_path_id
               and msjp.rev_id = a_r.rev_id
          )
)


    my $schema = $c->model('WebDB')->schema;
    $schema->register_source('NotTestedJobs' => $new_source);

    return 1;
}


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
        $data->{ag_err_msg} = "Error: Msession msession_id=$msession_id was aborted (abort_reason=$cols{abort_reason_id}).";
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
    my ( $self, $c, $data, $params, $key, $key_desc ) = @_;

    unless ( $params->{$key} ) {
        $data->{err} = 1;
        $data->{err_msg} = "Error: Parameter $key ($key_desc) required.";
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
        $data->{err} = 1;
        $data->{err_msg} = "Error: Create mslog entry failed."; # TODO
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

    $self->check_param( $c, $data, $params, 'crev', 'client code revision' ) || return 0;
    my $client_rev = $params->{crev};

    $self->check_param( $c, $data, $params, 'pid', 'client process ID' ) || return 0;
    my $pid = $params->{pid};

    my $msession_rs = $c->model('WebDB::msession')->create({
        machine_id  => $machine_id,
        client_rev  => $client_rev,
        pid         => $pid,
        start_time  => DateTime->now,
    });
    if ( ! $msession_rs ) {
        $data->{err} = 1;
        $data->{err_msg} = "Error: xxx"; # TODO
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

    $data->{msid} = $msession_id;
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
        $data->{err} = 1;
        $data->{err_msg} = "Error: ... (ret_val=$ret_val)."; # TODO
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

    return 1;
}


=head2 cmd_cget

Insert new row to msjob table if needed.

=cut

sub create_msjob {
    my ( $self, $c, $data, $machine_id, $msession_id ) = @_;

    $self->CreateMyResultSets( $c );

    my $plus_rows = [ qw/ job_id jobp_id rep_path_id rev_id rev_num priority jpriority /];

    my $search_conf = {
        'select' => $plus_rows,
        'as' => $plus_rows,
        bind  => [ $machine_id, $machine_id, $machine_id, $msession_id ],
    };

    my $rs = $c->model('WebDB')->schema->resultset( 'NotTestedJobs' )->search( {}, $search_conf );
    if (my $row = $rs->next) {
        my $row_data = { $row->get_columns };
        $self->dumper( $c, $row_data );
    }
    return 1;
}


=head2 cmd_cget

Get command to run on client. Insert new row to msjob_command table and new
row to msjob table if needed.

=cut

sub cmd_cget {
    my ( $self, $c, $data, $params ) = @_;

    # $params->{mid} - already checked
    my $machine_id = $params->{mid};
    # $params->{msid} - already checked
    my $msession_id = $params->{msid};

    my $start_new_job = 0;
    if ( ! $params->{mcid} ) {
         $start_new_job = 1;
    } else {
        # check if previous command wasn't last one in job
        # TODO
    }

    my $ret_val;
    if ( $start_new_job ) {
        my $ret_val = $self->create_msjob( $c, $data, $machine_id, $msession_id );
        unless ( $ret_val ) {
            $data->{err} = 1;
            $data->{err_msg} = "Error: ... (ret_val=$ret_val)."; # TODO
            return 0;
        }
    }

    # create mslog
    my $ret_code = $self->create_mslog(
        $c, $data, 'cget',
        $msession_id,
        4, # $msstatus_id, 4 .. running command
        1, # $attempt_number
        DateTime->now, # $change_time
        undef # $estimated_finish_time
    ) || return 0;

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
            $cmd_ret_code = $self->cmd_cget( $c, $data, $params );

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
