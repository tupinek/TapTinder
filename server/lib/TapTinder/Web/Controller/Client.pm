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

=head2 dump_rs

Dump result set.

=cut

sub dump_rs {
    my ( $self, $c, $rs ) = @_;

    while ( my $row = $rs->next ) {
        my $row_data = { $row->get_columns };
        $self->dumper( $c, $row_data );
    }
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
    my $msession_id = $msession_rs->get_column('msession_id');

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
        $data->{err_msg} = "Error: cmd_destroy ... (ret_val=$ret_val)."; # TODO
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


=head2 get_new_job

Return new job description for client.

=cut

sub get_new_job {
    my ( $self, $c, $data, $machine_id, $msession_id ) = @_;

    my $plus_rows = [ qw/ job_id jobp_id rep_path_id rev_id rev_num priority jpriority /];
    my $search_conf = {
        'select' => $plus_rows,
        'as'     => $plus_rows,
        'bind'   => [ $machine_id, $machine_id, $machine_id, $machine_id ],
    };

    my $rs = $c->model('WebDB')->schema->resultset( 'NotTestedJobs' )->search( {}, $search_conf );

    # TODO - new job not found

    my $row = $rs->next;
    return undef unless $row;
    my $row_data = { $row->get_columns };
    #$self->dumper( $c, $row_data );
    return $row_data;
}


=head2 create_msjob

Insert new row to msjob table.

=cut

sub create_msjob {
    my ( $self, $c, $data, $msession_id, $job_id ) = @_;

    my $new_rs = $c->model('WebDB::msjob')->create({
        msession_id => $msession_id,
        job_id      => $job_id,
        start_time  => DateTime->now,
        end_time    => undef,
        pid         => undef,
    });
    if ( ! $new_rs ) {
        $data->{err} = 1;
        $data->{err_msg} = "Error: xxx"; # TODO
        return undef;
    }
    my $msjob_id = $new_rs->get_column('msjob_id');
    return $msjob_id;
}


=head2 create_msjobp

Insert new row to msjobp table.

=cut

sub create_msjobp {
    my ( $self, $c, $data, $msjob_id, $jobp_id, $rev_id, $patch_id ) = @_;

    my $new_rs = $c->model('WebDB::msjobp')->create({
        msjob_id    => $msjob_id,
        jobp_id     => $jobp_id,
        rev_id      => $rev_id,
        patch_id    => $patch_id,
        start_time  => DateTime->now,
        end_time    => undef,
    });
    if ( ! $new_rs ) {
        $data->{err} = 1;
        $data->{err_msg} = "Error: xxx"; # TODO
        return undef;
    }
    my $msjobp_id = $new_rs->get_column('msjobp_id');
    return $msjobp_id;
}


=head2 create_msjobp_cmd

Insert new row to msjobp_cmd table.

=cut

sub create_msjobp_cmd {
    my ( $self, $c, $data, $msjobp_id, $jobp_cmd_id ) = @_;

    my $new_rs = $c->model('WebDB::msjobp_cmd')->create({
        msjobp_id   => $msjobp_id,
        jobp_cmd_id => $jobp_cmd_id,
        status_id   => 1, # created
        pid         => undef,
        start_time  => DateTime->now,
        end_time    => undef,
        output_id   => undef,
    });
    if ( ! $new_rs ) {
        $data->{err} = 1;
        $data->{err_msg} = "Error: xxx"; # TODO
        return undef;
    }
    my $msjobp_cmd_id = $new_rs->get_column('msjobp_cmd_id');
    return $msjobp_cmd_id;
}



=head2 get_next_cmd

Get next cmd info.

=cut

sub get_next_cmd {
    my ( $self, $c, $data, $job_id, $rep_path_id, $jobp_order, $jobp_cmd_order ) = @_;

    my $plus_rows = [ qw/ jobp_id jobp_cmd_id /];
    my $search_conf = {
        'select' => $plus_rows,
        'as'     => $plus_rows,
        'bind'   => [
            $job_id,
            $rep_path_id,
            $jobp_cmd_order, $jobp_cmd_order,
            $jobp_order, $jobp_order,
        ],
    };

    my $rs = $c->model('WebDB')->schema->resultset( 'NextJobCmd' )->search( {}, $search_conf );

    my $row = $rs->next;
    return undef unless $row;

    my $row_data = { $row->get_columns };
    #$self->dumper( $c, $row_data );
    #TODO, if jobp_cmd_id changed, then
    return $row_data;
}


=head2 get_next_cmd_mcid

Get next cmd info for previous $msjobp_cmd_id.

=cut

sub get_next_cmd_pmcid {
    my ( $self, $c, $data, $msession_id, $msjobp_cmd_id ) = @_;

    my $rs = $c->model('WebDB::msjobp_cmd')->search( {
        'msjobp_cmd_id' => $msjobp_cmd_id,
        'msjob_id.msession_id' => $msession_id,
    }, {
        select => [ 'msjobp_id.msjobp_id', 'jobp_id.job_id', 'jobp_id.jobp_id', 'jobp_id.rep_path_id', 'jobp_id.order', 'jobp_cmd_id.order', ],
        as => [ 'msjobp_id', 'job_id', 'jobp_id', 'rep_path_id', 'jobp_order', 'jobp_cmd_order', ],
        join => [ { 'msjobp_id' => [ 'msjob_id', 'jobp_id', ] }, 'jobp_cmd_id', ],
    } );
    #$self->dump_rs( $c, $rs );

    my $row = $rs->next;
    if ( !$row ) {
        $data->{err} = 1;
        $data->{err_msg} = "Error: Machine session job part command id (msjobp_cmd_id=$msjobp_cmd_id) not found.";
        return 0;
    }

    my $prev_data = { $row->get_columns() };

    my $next_cmd = $self->get_next_cmd(
        $c, $data,
        $prev_data->{job_id}, $prev_data->{rep_path_id}, $prev_data->{jobp_order}, $prev_data->{jobp_cmd_order}
    );
    # TODO, get rev_id, ...

    return {
        'new' => $next_cmd,
        'prev' => $prev_data,
    };
}


=head2 start_new_job

Get new job and insert new rows to apropriate tables.

=cut

sub start_new_job {
    my ( $self, $c, $data, $machine_id, $msession_id ) = @_;

    my $new_job = $self->get_new_job( $c, $data, $machine_id, $msession_id );
    return $new_job unless $new_job; # undef isn't error

    my $job_id = $new_job->{job_id};
    my $rep_path_id = $new_job->{rep_path_id};
    my $rev_id = $new_job->{rev_id};
    my $patch_id = undef; # TODO, patch testing not implemented yet

    # TODO, use SQL with jobp.order=1, jobp_cmd.order=1
    my $next_cmd = $self->get_next_cmd( $c, $data, $job_id, $rep_path_id, undef, undef );
    return $next_cmd unless $next_cmd; # undef isn't error

    my $jobp_id = $next_cmd->{jobp_id};
    my $jobp_cmd_id = $next_cmd->{jobp_cmd_id};

    my $msjob_id = $self->create_msjob( $c, $data, $msession_id, $job_id );
    return 0 unless defined $msjob_id;

    my $msjobp_id = $self->create_msjobp( $c, $data, $msjob_id, $jobp_id, $rev_id, $patch_id );
    return 0 unless defined $msjobp_id;

    my $msjobp_cmd_id = $self->create_msjobp_cmd( $c, $data, $msjobp_id, $jobp_cmd_id );
    return 0 unless defined $msjobp_cmd_id;

    $self->dumper( $c, "job_id: $job_id, rev_id: $rev_id, patch_id: $patch_id");
    $self->dumper( $c, "jobp_id: $jobp_id, jobp_cmd_id: $jobp_cmd_id");
    $self->dumper( $c, "msjob_id: $msjob_id, msjobp_id: $msjobp_id, msjobp_cmd_id: $msjobp_cmd_id" );

    $data->{job_id} = $job_id;
    $data->{rev_id} = $rev_id;
    $data->{patch_id} = $patch_id;
    $data->{jobp_id} = $jobp_id;
    $data->{jobp_cmd_id} = $jobp_cmd_id;
    $data->{msjob_id} = $msjob_id;
    $data->{msjobp_id} = $msjobp_id;
    $data->{msjobp_cmd_id} = $msjobp_cmd_id;
    # TODO, rep_path.name, ....
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
    # TODO - is_numeric?
    my $attempt_number = $params->{an};

    my $start_new_job = 0;
    if ( ! $params->{pmcid} ) {
         $start_new_job = 1;
    } else {
        # check if previous command wasn't last one in job
        my $cmds_data = $self->get_next_cmd_pmcid( $c, $data, $msession_id, $params->{pmcid} );
        if ( $cmds_data && $cmds_data->{new}->{jobp_cmd_id} ) {
            my $jobp_cmd_id = $cmds_data->{new}->{jobp_cmd_id};

            my $msjobp_id = $cmds_data->{prev}->{msjobp_id};
            if ( $jobp_cmd_id != $cmds_data->{prev}->{jobp_cmd_id} ) {
                # TODO
                #my $msjob_id = $cmds_data->{prev}->{msjob_id};
                #$msjobp_id = $self->create_msjobp( $c, $data, $msjob_id, $jobp_id, $rev_id, $patch_id );
                #return 0 unless defined $msjobp_id;
                #$data->{msjobp_id} = $msjobp_id;
            }

            my $msjobp_cmd_id = $self->create_msjobp_cmd( $c, $data, $msjobp_id, $jobp_cmd_id );
            return 0 unless defined $msjobp_cmd_id;


            $self->dumper( $c, "jobp_cmd_id: $jobp_cmd_id, msjobp_cmd_id: $msjobp_cmd_id" );
            $data->{msjobp_cmd_id} = $msjobp_cmd_id;
        } else {
            $start_new_job = 1;
        }
    }

    my $ret_val;
    if ( $start_new_job ) {
        my $ret_val = $self->start_new_job( $c, $data, $machine_id, $msession_id );
        unless ( defined $ret_val ) {
            # create mslog
            my $ret_code = $self->create_mslog(
                $c, $data, 'cget',
                $msession_id,
                3, # $msstatus_id, 3 .. waiting for new job
                $attempt_number,
                DateTime->now, # $change_time
                undef # $estimated_finish_time
            ) || return 0;
            return 1;
        }
        unless ( $ret_val ) {
            $data->{err} = 1;
            $data->{err_msg} = "Error: cmd_get ... (ret_val=$ret_val)."; # TODO
            return 0;
        }
    }

    # create mslog
    my $ret_code = $self->create_mslog(
        $c, $data, 'cget',
        $msession_id,
        4, # $msstatus_id, 4 .. running command
        $attempt_number,
        DateTime->now, # $change_time
        undef # $estimated_finish_time
    ) || return 0;

    return 1;
}


=head2 get_msjobp_cmd_info

Return row with msjobp_id and msjob_id for $msession_id and $msjobp_cmd_id.

=cut

sub get_msjobp_cmd_info {
    my ( $self, $c, $data, $msession_id, $msjobp_cmd_id ) = @_;

    my $rs = $c->model('WebDB::msjobp_cmd')->search( {
        'me.msjobp_cmd_id' => $msjobp_cmd_id,
        'msjob_id.msession_id' => $msession_id,
    }, {
        select => [ 'msjobp_id.msjobp_id', 'msjob_id.msjob_id', ],
        as => [ 'msjobp_id', 'msjob_id' ],
        join => { 'msjobp_id' => 'msjob_id' },
    } );

    my $row = $rs->next;
    if ( !$row ) {
        $data->{err} = 1;
        $data->{err_msg} = "Error: Machine session job part command id (msession_id=$msession_id, msjobp_cmd_id=$msjobp_cmd_id) not found.";
        return 0;
    }
    my $row_data = { $row->get_columns() };
    return $row_data;
}


=head2 cmd_sset

Set msjobp_cmd.status_id.

=cut

sub cmd_sset {
    my ( $self, $c, $data, $params, $upload ) = @_;

    # $params->{mid} - already checked
    my $machine_id = $params->{mid};
    # $params->{msid} - already checked
    my $msession_id = $params->{msid};
    # TODO - is_numeric?
    my $msjobp_cmd_id = $params->{mcid};
    # TODO is valid status_id?
    my $cmd_status_id = $params->{csid};

    my $msjob_info = $self->get_msjobp_cmd_info( $c, $data, $msession_id, $msjobp_cmd_id );
    return 0 unless $msjob_info;

    my $msjobp_cmd_rs = $c->model('WebDB::msjobp_cmd')->search( {
        msjobp_cmd_id => $msjobp_cmd_id,
    } );
    my $to_set = {
        status_id => $cmd_status_id,
    };
    if ( $params->{etime} ) {
        # TODO validate params
        my $end_time = $params->{etime};
        my $outfile = $c->request->upload('outf');
        #$self->dumper( $c, $c->request );
        unless ( $outfile ) {
            $data->{err} = 1;
            $data->{err_msg} = "Error: cmd_sset upload file failed ... ."; # TODO
            return 0;
        }

        my $output_file_id = 1;
        $to_set->{end_time} = DateTime->from_epoch( epoch => $end_time );
        #$to_set->{output_id} = $output_file_id;
    }
    my $ret_val = $msjobp_cmd_rs->update( $to_set );

    unless ( $ret_val ) {
        $data->{err} = 1;
        $data->{err_msg} = "Error: cmd_sset update ... (ret_val=$ret_val)."; # TODO
        return 0;
    }

    return 1;
}


=head2 cmd_alog

Add row to mslog table.

=cut

sub cmd_alog {
    my ( $self, $c, $data, $params ) = @_;
    return 1;
}


=head2 process_action

Process all params but 'ot'.

=cut

sub process_action {
    my ( $self, $c, $action ) = @_;

    my $params = $c->request->params;
    my $data : Stashed = {};

    $data->{is_debug} = 1 if $c->log->is_debug;

    if ( $params->{ot} eq 'html' && $c->log->is_debug ) {
        my $ot : Stashed = '';
        $self->dumper( $c, $params );

        # [% dumper(data) | html %]
        $c->stash->{dumper} = sub { DBIx::Dumper::Dumper( $_[0] ); };
    }

    my $param_msid_checks;
         if ( $action eq 'mscreate' )   { $param_msid_checks = 0;   # msession create
    } elsif ( $action eq 'msdestroy' )  { $param_msid_checks = 1;   # msession destroy
    } elsif ( $action eq 'cget' )       { $param_msid_checks = 1;   # get command
    } elsif ( $action eq 'sset' )       { $param_msid_checks = 1;   # set status
    } elsif ( $action eq 'rset' )       { $param_msid_checks = 1;   # set results
    # debug commands
    } elsif ( $action eq 'login' )      { $param_msid_checks = 0;   # login
    } elsif ( $action eq 'alog' )       { $param_msid_checks = 1;   # add mslog
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
            $cmd_ret_code = $self->cmd_sset( $c, $data, $params, $c->request->upload );

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

    $self->process_action( $c, $action );

    my $params = $c->request->params;
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
