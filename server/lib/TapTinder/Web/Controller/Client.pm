package TapTinder::Web::Controller::Client;

use strict;
use warnings;
use base 'TapTinder::Web::ControllerBase';

use Digest::MD5 qw(md5);
use DateTime;
use File::Spec;
use File::Copy;

use constant SUPPORRTED_REVISION => 257;


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


=head2 check_client_rev

Check if client revision is supported by server.

=cut

sub check_client_rev {
    my ( $self, $c, $data, $client_rev ) = @_;

    if ( $client_rev < SUPPORRTED_REVISION ) {
        $data->{err} = 1;
        $data->{err_msg} = "Error: Your client (revision $client_rev) is not supported. Revision >= " . SUPPORRTED_REVISION . " required.";
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
        $data->{err_msg} = "Error: Create mslog entry failed (action=$action_name)."; # TODO
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
    $self->check_client_rev( $c, $data, $client_rev ) || return 0;

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
        7, # $msstatus_id, 7 .. stop by user
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

    my $plus_rows = [ qw/ jobp_id jobp_cmd_id cmd_name /];
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
    my $cmd_name = $next_cmd->{cmd_name};

    my $msjob_id = $self->create_msjob( $c, $data, $msession_id, $job_id );
    return 0 unless defined $msjob_id;

    my $msjobp_id = $self->create_msjobp( $c, $data, $msjob_id, $jobp_id, $rev_id, $patch_id );
    return 0 unless defined $msjobp_id;

    my $msjobp_cmd_id = $self->create_msjobp_cmd( $c, $data, $msjobp_id, $jobp_cmd_id );
    return 0 unless defined $msjobp_cmd_id;

    $self->dumper( $c, "job_id: $job_id, rev_id: $rev_id, patch_id: $patch_id");
    $self->dumper( $c, "jobp_id: $jobp_id, jobp_cmd_id: $jobp_cmd_id");
    $self->dumper( $c, "msjob_id: $msjob_id, msjobp_id: $msjobp_id, msjobp_cmd_id: $msjobp_cmd_id" );

    # need to be in sync with cmd_cget
    $data->{msjob_id} = $msjob_id;
    $data->{rep_path_id} = $rep_path_id;
    $data->{patch_id} = $patch_id;
    $data->{msjobp_id} = $msjobp_id;
    $data->{rev_id} = $rev_id;
    $data->{msjobp_cmd_id} = $msjobp_cmd_id;
    $data->{cmd_name} = $cmd_name;
    return 1;
}


=head2 get_rep_path_newest_rev_id

Return newest rev_id for rep_path_id found.

=cut

sub get_rep_path_newest_rev_id {
    my ( $self, $c, $data, $rep_path_id ) = @_;

    # TODO - optimize to limit 1
    my $rs = $c->model('WebDB::rev_rep_path')->search( {
        'me.rep_path_id' => $rep_path_id,
    }, {
        select => [ 'rev_id' ],
        as => [ 'rev_id.rev_id',  ],
        join => [ 'rev_id' ],
        order_by => [ 'rev_num' ],
    } );
    my $row = $rs->next;
    if ( !$row ) {
        $data->{err} = 1;
        $data->{err_msg} = "Error: Rev_rep_path id (rep_path_id=$rep_path_id) not found.";
        return 0;
    }
    my $row_data = { $row->get_columns() };
    return $row_data->{rev_id};
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
        # pmcid - previous msjobp_cmd_id
        my $cmds_data = $self->get_next_cmd_pmcid( $c, $data, $msession_id, $params->{pmcid} );
        # next command in job found (in same jop part or new job part)
        if ( $cmds_data && $cmds_data->{new}->{jobp_cmd_id} ) {
            my $jobp_cmd_id = $cmds_data->{new}->{jobp_cmd_id};
            my $cmd_name = $cmds_data->{new}->{cmd_name};

            # use old msjobp_id or create new
            my $msjobp_id;
            # job part id can be same as prev or newly selected
            my $jobp_id = $cmds_data->{new}->{jobp_id};
            if ( $jobp_id == $cmds_data->{prev}->{jobp_id} ) {
                $msjobp_id = $cmds_data->{prev}->{msjobp_id};

            # if job part id is new, than we shoul create new msjobp_id
            } else {
                my $msjob_id = $cmds_data->{prev}->{msjob_id};
                my $patch_id = undef; # TODO

                # find new rev_id
                my $rep_path_id = $cmds_data->{prev}->{rep_path_id};
                my $rev_id = $self->get_rep_path_newest_rev_id( $c, $data, $rep_path_id );

                $msjobp_id = $self->create_msjobp( $c, $data, $msjob_id, $jobp_id, $rev_id, $patch_id );
                return 0 unless defined $msjobp_id;

                # need to be in sync with start_new_job
                $data->{msjob_id} = $msjob_id;
                $data->{rep_path_id} = $rep_path_id;
                $data->{patch_id} = $patch_id;
                $data->{msjobp_id} = $msjobp_id;
                $data->{rev_id} = $rev_id;
            }

            my $msjobp_cmd_id = $self->create_msjobp_cmd( $c, $data, $msjobp_id, $jobp_cmd_id );
            return 0 unless defined $msjobp_cmd_id;

            #$self->dumper( $c, "jobp_cmd_id: $jobp_cmd_id, msjobp_id: $msjobp_id, msjobp_cmd_id: $msjobp_cmd_id" );
            $data->{msjobp_cmd_id} = $msjobp_cmd_id;
            $data->{cmd_name} = $cmd_name;

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
        5, # $msstatus_id, 5 .. running command
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
        select => [ 'msjobp_id.msjobp_id', 'msjob_id.msjob_id', 'jobp_id.rep_path_id', ],
        as => [ 'msjobp_id', 'msjob_id', 'rep_path_id', ],
        join => { 'msjobp_id' => [ 'msjob_id', 'jobp_id', ] },
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


=head2 get_fspath_info

Select fspath info for fsfile_type_id and rep_path_id.

=cut

sub get_fspath_info {
    my ( $self, $c, $data, $fsfile_type_id, $rep_path_id ) = @_;

    my $rs = $c->model('WebDB::fspath_select')->search( {
        'me.fsfile_type_id' => $fsfile_type_id,
        'me.rep_path_id'    => $rep_path_id,
    }, {
        select => [ 'fspath_id.fspath_id', 'fspath_id.path', 'fspath_id.name',  ],
        as => [ 'fspath_id', 'path', 'name',  ],
        join => [ 'fspath_id' ],
    } );
    my $row = $rs->next;
    if ( !$row ) {
        $data->{err} = 1;
        $data->{err_msg} = "Error: Fspath id (fsfile_type_id=$fsfile_type_id, rep_path_id=$rep_path_id) not found.";
        return 0;
    }
    my $row_data = { $row->get_columns() };
    return $row_data;
}


=head2 move_uploaded_file

Create new machine session log (mslog) entry.

=cut

sub move_uploaded_file {
    my ( $self, $c, $data, $upload_req, $fspath_id, $fspath, $file_name  ) = @_;

    my $old_path = $upload_req->tempname;
    my $new_path = File::Spec->catfile( $fspath, $file_name );
    unless ( move( $old_path, $new_path ) ) {
        $data->{err} = 1;
        $data->{err_msg} = "Error: Move file failed ( '$old_path', '$new_path' ):\n$!";
        return 0;
    }

    my $size = $upload_req->size(); # in bytes
    my $created = DateTime->now;

    my $fsfile_rs = $c->model('WebDB::fsfile')->create({
        fspath_id   => $fspath_id,
        name        => $file_name,
        size        => $size,
        created     => $created,
        deleted     => undef,
    });
    unless ( $fsfile_rs ) {
        $data->{err} = 1;
        $data->{err_msg} = "Error: Create fsfile entry failed."; # TODO
        return 0;
    }
    my $fsfile_id = $fsfile_rs->get_column('fsfile_id');
    return $fsfile_id;
}


=head2 uploaded_file_found

Do all around file uploading.

=cut

sub uploaded_file_found {
    my ( $self, $c, $data, $input_name, $rep_path_id, $msjobp_cmd_id ) = @_;

    # TODO validate params

    my $output_file_upload_req = $c->request->upload( $input_name );
    #$self->dumper( $c, $c->request->uploads );
    unless ( $output_file_upload_req ) {
        $data->{err} = 1;
        $data->{err_msg} = "Error: cmd_sset upload output file failed ... ."; # TODO
        return 0;
    }

    my $file_name = undef;
    my $fsfile_type_id = undef;
    if ( $input_name eq 'output_file' ) {
        $fsfile_type_id = 1; # command output
        $file_name = $msjobp_cmd_id . '.txt';

    } elsif ( $input_name eq 'outdata_file' ) {
        $fsfile_type_id = 2; # command outdata
        $file_name = $msjobp_cmd_id . '.tar.gz';

    } else {
        $data->{err} = 1;
        $data->{err_msg} = "Error: Upload output file failed. Unknown input_name '$input_name'."; # TODO
        return 0;
    }

    my $fspath_info = $self->get_fspath_info( $c, $data, $fsfile_type_id, $rep_path_id );
    return 0 unless $fspath_info;
    #$self->dumper( $c, $fspath_info );

    my $fsfile_id = $self->move_uploaded_file(
        $c,
        $data,
        $output_file_upload_req,    # $upload_req
        $fspath_info->{fspath_id},  # $fspath_id
        $fspath_info->{path},       # $fspath
        $file_name
    );
    return 0 unless $fsfile_id;
    return $fsfile_id;
}


=head2 update_msjobp_cmd

Update row with $msjobp_cmd_id in msjobp_cmd table. New values are in $to_set hash ref.

=cut


sub update_msjobp_cmd {
    my ( $self, $c, $data, $msjobp_cmd_id, $to_set ) = @_;

    my $msjobp_cmd_rs = $c->model('WebDB::msjobp_cmd')->search( {
        msjobp_cmd_id => $msjobp_cmd_id,
    } );

    my $ret_val = $msjobp_cmd_rs->update( $to_set );

    unless ( $ret_val ) {
        $data->{err} = 1;
        $data->{err_msg} = "Error: update msjobp_cmd failed ... (ret_val=$ret_val)."; # TODO
        return 0;
    }

    return 1;
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

    my $to_set = {
        status_id => $cmd_status_id,
    };
    if ( $params->{etime} ) {
        $to_set->{end_time} = DateTime->from_epoch( epoch => $params->{etime} );
    }

    if ( $params->{output_file} ) {
        my $fsfile_id = $self->uploaded_file_found(
            $c, $data,
            'output_file', # $input_name
            $msjob_info->{rep_path_id}, # rep_path_id
            $msjobp_cmd_id
        );
        return 0 unless $fsfile_id;
        $to_set->{output_id} = $fsfile_id;
    }

    if ( $params->{outdata_file} ) {
        my $fsfile_id = $self->uploaded_file_found(
            $c, $data,
            'outdata_file', # $input_name
            $msjob_info->{rep_path_id}, # rep_path_id
            $msjobp_cmd_id
        );
        return 0 unless $fsfile_id;
        $to_set->{outdata_id} = $fsfile_id;
    }

    return $self->update_msjobp_cmd( $c, $data, $msjobp_cmd_id, $to_set );
}




=head2 get_rr_info

Select rep_path info and rev info for rep_path_id and rev_id.

=cut

sub get_rr_info {
    my ( $self, $c, $data, $rep_path_id, $rev_id ) = @_;

    # select from rev_rep_path will validate rep_path_id and rev_id relationship
    my $rs = $c->model('WebDB::rev_rep_path')->search( {
        'me.rep_path_id' => $rep_path_id,
        'me.rev_id' => $rev_id,
    }, {
        select => [ 'rep_id.path', 'project_id.name', 'rep_path_id.path', 'rev_id.rev_num', ],
        as => [ 'rep_path', 'project_name', 'rep_path_path', 'rev_num', ],
        join => [ { 'rep_path_id' => { 'rep_id' => 'project_id' } }, 'rev_id' ],
    } );
    my $row = $rs->next;
    if ( !$row ) {
        $data->{err} = 1;
        $data->{err_msg} = "Error: Rev_rep_path id (rep_path_id=$rep_path_id, rev_id=$rev_id) not found.";
        return 0;
    }
    my $row_data = { $row->get_columns() };
    return $row_data;
}


=head2 rh_copy_kv_to

Copy/rewrite input hash ref keys/values to output hash ref.

=cut


sub rh_copy_kv_to {
    my ( $self, $rh_in, $rh_out ) = @_;

    foreach my $key ( keys %$rh_in ) {
        $rh_out->{ $key } = $rh_in->{ $key };
    }
    return 1;
}


=head2 cmd_rriget

Get info for rep_path_id an rev_id.

=cut

sub cmd_rriget {
    my ( $self, $c, $data, $params, $upload ) = @_;

    # $params->{mid} - already checked
    my $machine_id = $params->{mid};
    # $params->{msid} - already checked
    my $msession_id = $params->{msid};

    my $rep_path_id = $params->{rpid};
    my $rev_id = $params->{revid};

    my $rr_info = $self->get_rr_info( $c, $data, $rep_path_id, $rev_id );
    return 0 unless $rr_info;

    $self->rh_copy_kv_to( $rr_info, $data );

    # create mslog
    my $ret_code = $self->create_mslog(
        $c, $data, 'rriget',
        $msession_id,
        4, # $msstatus_id, 4 .. command preparation
        1,
        DateTime->now, # $change_time
        undef # $estimated_finish_time
    ) || return 0;

    return 1;
}


=head2 cmd_mevent

Machine event occured.

=cut

sub cmd_mevent {
    my ( $self, $c, $data, $params ) = @_;

    # $params->{mid} - already checked
    my $machine_id = $params->{mid};
    # $params->{msid} - already checked
    my $msession_id = $params->{msid};

    # TODO - undef or is_numeric?
    my $msjobp_cmd_id = $params->{mcid};

    $self->check_param( $c, $data, $params, 'en', 'event name' ) || return 0;
    my $event_name = $params->{en};

    my $new_msstatus_id = undef;
    my $new_cmd_status_id = undef;

    if ( $event_name eq 'pause' ) {
        $new_msstatus_id = 6; # paused by user
        $new_cmd_status_id = 6; # paused by user

    } elsif ( $event_name eq 'continue' ) {
        # TODO - try to restore msstatus_id from before pause
        $new_msstatus_id = 1; # unknown status
        $new_cmd_status_id = 2; # running

    } else {
        $data->{err} = 1;
        $data->{err_msg} = "Error: Unknown event name '$event_name'.";
        return 0;
    }


    if ( $new_msstatus_id ) {
        # create mslog
        my $ret_code = $self->create_mslog(
            $c, $data, 'mevent',
            $msession_id,
            $new_msstatus_id, # $msstatus_id
            1, # $attempt_number
            DateTime->now, # $change_time
            undef # $estimated_finish_time
        ) || return 0;
    }

    if ( $msjobp_cmd_id && $new_cmd_status_id ) {
        # check/validate of msession_id vs. msjobp_cmd_id
        my $msjob_info = $self->get_msjobp_cmd_info( $c, $data, $msession_id, $msjobp_cmd_id );
        return 0 unless $msjob_info;

        my $to_set = {
            status_id => $new_cmd_status_id,
        };
        return $self->update_msjobp_cmd( $c, $data, $msjobp_cmd_id, $to_set );
    }

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
    } elsif ( $action eq 'rriget' )     { $param_msid_checks = 1;   # rep rev info get
    } elsif ( $action eq 'mevent' )     { $param_msid_checks = 1;   # machine event occured
    # debug commands
    } elsif ( $action eq 'login' )      { $param_msid_checks = 0;   # login
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

        } elsif ( $action eq 'rriget' ) {
            $cmd_ret_code = $self->cmd_rriget( $c, $data, $params );

        } elsif ( $action eq 'mevent' ) {
            $cmd_ret_code = $self->cmd_mevent( $c, $data, $params );

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
