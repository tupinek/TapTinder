package TapTinder::Client;

use strict;
use warnings;
use Carp qw(carp croak verbose);

our $VERSION = '0.10';

use Data::Dumper;
use File::Spec::Functions;
use Cwd;

use Watchdog qw(sys sys_for_watchdog);
use TapTinder::Client::KeyPress qw(process_keypress sleep_and_process_keypress cleanup_before_exit);
use TapTinder::Client::WebAgent;
use TapTinder::Client::RepManager;

=head1 NAME

TapTinder::Client - Client for TapTinder software development tool.

=head1 DESCRIPTION

TapTinder is software development tool (continuous integration, test
harness, collect and analyse test results, create reports and diffs).

=head2 $ver

Verbosity level.

* >0 .. print errors only
* >1 .. print base run info
* >2 .. all run info (default)
* >3 .. major debug info
* >4 .. major and minor debug info
* >5 .. all debug info

=cut

our $ver = 0;

our $debug = 0;


=head2 new

Create Client object.

=cut

sub new {
    my ( $class, $client_conf, $base_dir, $t_ver, $t_debug ) = @_;

    $t_ver = 2 unless defined $t_ver;
    $t_debug = 0 unless defined $t_debug;
    $ver = $t_ver;
    $debug = $t_debug;

    my $self = {};
    $self->{client_conf} = $client_conf;
    $self->{src_add_dir} = catdir( $base_dir, 'client-src-add' );
    $self->{data_dir} = catdir( $base_dir, 'client-data' );

    $self->{agent} = undef;

    # current work directory on start
    $self->{orginal_cwd} = Cwd::getcwd;

    bless ($self, $class);
    $self->init_agent();
    $self->init_repmanager();
    $self->init_keypress();

    return $self;
}


=head2 init_agent

Initialize WebAgent object.

=cut

sub init_agent {
    my ( $self ) = @_;

    print "Starting WebAgent.\n" if $ver >= 3;
    my $agent = TapTinder::Client::WebAgent->new(
        $self->{client_conf}->{taptinderserv},
        $self->{client_conf}->{machine_id},
        $self->{client_conf}->{machine_passwd},
        $ver,
        $debug
    );

    $self->{agent} = $agent;
    return 1;
}


=head2 init_agent

Initialize WebAgent object.

=cut

sub init_repmanager {
    my ( $self ) = @_;

    print "Starting RepManager.\n" if $ver >= 3;
    my $repman = TapTinder::Client::RepManager->new(
        $self->{data_dir},
        $ver,
        $debug
    );

    $self->{repman} = $repman;
    return 1;
}


=head2 init_agent

Initialize KeyPress.

=cut

sub init_keypress {
    my ( $self ) = @_;

    $TapTinder::Client::KeyPress::ver = $ver;
    Term::ReadKey::ReadMode('cbreak');
    select(STDOUT); $| = 1;

    # closure - take $self
    $TapTinder::Client::KeyPress::sub_before_exit = sub {
        chdir( $self->{orginal_cwd} );
        Term::ReadKey::ReadMode('normal');
        if ( $self->{msession_id} ) {
            $self->{agent}->msdestroy( $self->{msession_id} );
        }
    };
    return 1;
}


=head2 my_croak

Cleanup and croak.

=cut

sub my_croak {
    my ( $self, $err_msg ) = @_;
    cleanup_before_exit();
    croak $err_msg;
}


=head2 ccmd_get_src

Run get_src client command.

=cut

sub ccmd_get_src {
    my ( $self, $msjobp_cmd_id, $cmd_name, $cmd_env ) = @_;

    my $data; # many different uses
    $data = $self->{agent}->rriget(
        $self->{msession_id}, $cmd_env->{rep_path_id}, $cmd_env->{rev_id}
    );
    $self->my_croak("Cmd rriget error.") unless defined $data;
    $self->my_croak( $data->{err_msg} ) if $data->{err};

    my $rep_rev_info = { %$data };
    $cmd_env->{project_name} = $data->{project_name};
    $cmd_env->{rep_path} = $data->{rep_path};
    $cmd_env->{rep_path_path} = $data->{rep_path_path};
    $cmd_env->{rev_num} = $data->{rev_num};
    #print Dumper( [ $rep_rev_info, $cmd_env ] );

    my $rep_full_path = $rep_rev_info->{rep_path} . $rep_rev_info->{rep_path_path};
    print "Getting revision $data->{rev_num} from $rep_full_path.\n" if $ver >= 2;

    $data = $self->{agent}->sset( $self->{msession_id}, $msjobp_cmd_id, 2 ); # running, $cmd_status_id
    $self->my_croak( $data->{err_msg} ) if $data->{err};

    my $dirs = $self->{repman}->prepare_temp_copy( $rep_rev_info );
    unless ( $dirs ) {
        $data = $self->{agent}->sset( $self->{msession_id}, $msjobp_cmd_id, 5 ); # error, $cmd_status_id
        $self->my_croak( $data->{err_msg} ) if $data->{err};
        return 0; # not needed
    }
    $cmd_env->{temp_dir} = $dirs->{temp_dir};
    $cmd_env->{results_dir} = $dirs->{results_dir};

    $data = $self->{agent}->sset( $self->{msession_id}, $msjobp_cmd_id, 3 ); # ok, $cmd_status_id
    return 1;
}


=head2 ccmd_prepare

Run prepare client command. Prepare project dir for TapTinder run.

=cut

sub ccmd_prepare {
    my ( $self, $msjobp_cmd_id, $cmd_name, $cmd_env ) = @_;

    my $data = $self->{agent}->sset( $self->{msession_id}, $msjobp_cmd_id, 2 ); # running, $cmd_status_id

    my $src_add_project_dir = catdir( $self->{src_add_dir}, $cmd_env->{project_name} );
    $self->{repman}->add_merge_copy( $src_add_project_dir, $cmd_env->{temp_dir} );

    $data = $self->{agent}->sset( $self->{msession_id}, $msjobp_cmd_id, 3 ); # ok, $cmd_status_id

    return 1;
}


=head2 ccmd_patch

Run patch client command.

=cut

sub ccmd_patch {
    my ( $self, $msjobp_cmd_id, $cmd_name, $cmd_env ) = @_;
    print "Client command 'patch' not implemented yet.\n" if $ver >= 2;
    return 1;
}


=head2 run_cmd

Run command.

=cut

sub run_cmd {
    my ( $self, $msjobp_cmd_id, $cmd_name, $cmd_env, $cmd, $cmd_timeout ) = @_;

    my $log_file_name =
        $cmd_env->{msjob_id}
        . '-' . $cmd_env->{jobp_num}
        . '-' . $cmd_env->{jobp_cmd_num}
        . '-' . $cmd_name
    ;
    my $cmd_log_fp = catfile( $cmd_env->{results_dir}, $log_file_name );

    my $data = $self->{agent}->sset(
        $self->{msession_id},
        $msjobp_cmd_id, # $msjobp_cmd_id
        2, # running
        undef, # $end_time
        undef  # $file_path
    );

    my ( $cmd_rc, $out ) = sys_for_watchdog(
        $cmd,
        $cmd_log_fp,
        $cmd_timeout,
        undef,
        $self->{data_dir}, # path to watchdog-setting.bin
        $ver # verbose or not
    );
    print "Command '$cmd_name' return $cmd_rc.\n" if $ver >= 5;

    my $status = 3; # 3 .. ok
    if ( $cmd_rc ) {
        $status = 5; # 5 .. error
    }

    $data = $self->{agent}->sset(
        $self->{msession_id},
        $msjobp_cmd_id, # $msjobp_cmd_id
        $status,
        time(), # $end_time, TODO - is GMT?
        $cmd_log_fp
    );
    $self->my_croak( $data->{err_msg} ) if $data->{err};
    return 1;
}


=head2 ccmd_perl_configure

Run perl_configure client command.

=cut

sub ccmd_perl_configure {
    my ( $self, $msjobp_cmd_id, $cmd_name, $cmd_env ) = @_;

    my $cmd = 'perl Configure.pl';
    my $cmd_timeout = 5*60; # 5 min
    return $self->run_cmd( $msjobp_cmd_id, $cmd_name, $cmd_env, $cmd, $cmd_timeout );
}


=head2 ccmd_make

Run make client command.

=cut

sub ccmd_make {
    my ( $self, $msjobp_cmd_id, $cmd_name, $cmd_env ) = @_;

    my $cmd = 'make';
    if ( $^O eq 'MSWin32' ) {
        my $rc = system( "mingw32-make --version > nul" );
        if ( $rc == 0 ) {
            $cmd = 'mingw32-make';
        } else {
            $cmd = 'nmake';
        }
    }

    my $cmd_timeout = 5*60; # 5 min
    return $self->run_cmd( $msjobp_cmd_id, $cmd_name, $cmd_env, $cmd, $cmd_timeout );
}


=head2 ccmd_trun

Run trun client command.

=cut

sub ccmd_trun {
    my ( $self, $msjobp_cmd_id, $cmd_name, $cmd_env ) = @_;

    print "Client command 'trun' not implemented yet.\n" if $ver >= 2;
    return 1;
}


=head2 ccmd_test

Run test client command.

=cut

sub ccmd_test {
    my ( $self, $msjobp_cmd_id, $cmd_name, $cmd_env ) = @_;

    my $cmd = 'make test';
    my $cmd_timeout = 5*60; # 5 min
    return $self->run_cmd( $msjobp_cmd_id, $cmd_name, $cmd_env, $cmd, $cmd_timeout );
}


=head2 ccmd_bench

Run bench client command.

=cut

sub ccmd_bench {
    my ( $self, $msjobp_cmd_id, $cmd_name, $cmd_env ) = @_;
    print "Client command 'bench' not implemented yet.\n" if $ver >= 2;
    return 1;
}


=head2 ccmd_install

Run install client command.

=cut

sub ccmd_install {
    my ( $self, $msjobp_cmd_id, $cmd_name, $cmd_env ) = @_;
    print "Client command 'install' not implemented yet.\n" if $ver >= 2;
    return 1;
}


=head2 ccmd_clean

Run clean client command.

=cut

sub ccmd_clean {
    my ( $self, $msjobp_cmd_id, $cmd_name, $cmd_env ) = @_;
    print "Client command 'clean' not implemented yet.\n" if $ver >= 2;
    return 1;
}


=head2 run

Main run loop.

=cut

sub run {
    my ( $self ) = @_;

    print "Creating new machine session.\n" if $ver >= 3;
    my ( $login_rc, $msession_id ) = $self->{agent}->mscreate();
    $self->my_croak("Login failed.") unless $login_rc;
    $self->{msession_id} = $msession_id;
    process_keypress();

    # current (or last successful) ids
    my $msjob_id = undef;
    my $msjobp_id = undef;
    my $msjobp_cmd_id = undef;

    # data shared between commands
    my $cmd_env = {};
    # Keys:
    # temp_dir - path to working copy (temp), created after ccmd_get_src
    # jobp_num, jobp_cmd_num - Number of job part in job and number of cmd in job_part.
    #                          Used as part of local client log file names.

    # number of job runs
    my $job_num = 0;
    # number of cget runs with "new cmd not found"
    my $no_job_num = 0;

    # Number of next attempt. Reseted to 1 after each successful cget.
    my $next_attempt_number = 1;
    my $estimated_finish_time = undef;

    while ( 1 ) {
        # try to get command from server
        my $data = $self->{agent}->cget(
            $self->{msession_id},
            $next_attempt_number, # $attemnt_number
            $estimated_finish_time,
            $msjobp_cmd_id # use actual id to get new one
        );
        $self->my_croak("Cmd cget error.") unless defined $data;
        $self->my_croak( $data->{err_msg} ) if $data->{err};

        # new cmd not found
        if ( ! $data->{msjobp_cmd_id} ) {
            $no_job_num++;
            $next_attempt_number++;

            print "New msjobp_cmd_id not found.\n";
            last if $debug; # debug - end forced by debug

            my $sleep_time = 15;
            print "Waiting for $sleep_time s ...\n" if $ver >= 1;
            sleep_and_process_keypress( $sleep_time );

        # new cmd found
        } else {
            $next_attempt_number = 1;

            # new job
            if ( !defined($msjob_id) || ( exists($data->{msjob_id}) && $msjob_id != $data->{msjob_id}) ) {
                $job_num++;

                $cmd_env = {};
                $cmd_env->{jobp_num} = 0;
                $cmd_env->{jobp_cmd_num} = 0;
                $msjob_id = $data->{msjob_id};
                $cmd_env->{msjob_id} = $msjob_id;

                last if $debug && ($job_num > 1); # debug - end forced by debug
            }
            # new job part
            if ( !defined($msjobp_id) || ( exists($data->{msjobp_id}) && $msjobp_id != $data->{msjobp_id} ) ) {
                $cmd_env->{jobp_num}++;
                chdir( $self->{orginal_cwd} );
                $cmd_env->{temp_dir} = undef;
                $msjobp_id = $data->{msjobp_id};
            }
            # new command
            if ( !defined($msjobp_cmd_id) || ( exists($data->{msjobp_cmd_id}) && $msjobp_cmd_id != $data->{msjobp_cmd_id} ) ) {
                $cmd_env->{jobp_cmd_num}++;
                $msjobp_cmd_id = $data->{msjobp_cmd_id};
            } else {
                $self->my_croak("Error new msjobp_cmd_id=$data->{msjobp_cmd_id}.");
            }

            my $cmd_name = $data->{cmd_name};
            if ( $cmd_name eq 'get_src' ) {
                $cmd_env->{rep_path_id} = $data->{rep_path_id};
                $cmd_env->{rev_id} = $data->{rev_id};
                # will set another keys to $cmd_env
                $self->ccmd_get_src( $msjobp_cmd_id, $cmd_name, $cmd_env );

                # change current working directory (cwd, pwd)
                chdir( $cmd_env->{temp_dir} );

            } elsif ( $cmd_name eq 'prepare' ) {
                $self->ccmd_prepare( $msjobp_cmd_id, $cmd_name, $cmd_env );

            } elsif ( $cmd_name eq 'patch' ) {
                $self->ccmd_patch( $msjobp_cmd_id, $cmd_name, $cmd_env );

            } elsif ( $cmd_name eq 'perl_configure' ) {
                $self->ccmd_perl_configure( $msjobp_cmd_id, $cmd_name, $cmd_env );

            } elsif ( $cmd_name eq 'make' ) {
                $self->ccmd_make( $msjobp_cmd_id, $cmd_name, $cmd_env );

            } elsif ( $cmd_name eq 'trun' ) {
                $self->ccmd_trun( $msjobp_cmd_id, $cmd_name, $cmd_env );

            } elsif ( $cmd_name eq 'test' ) {
                $self->ccmd_test( $msjobp_cmd_id, $cmd_name, $cmd_env );

            } elsif ( $cmd_name eq 'bench' ) {
                $self->ccmd_bench( $msjobp_cmd_id, $cmd_name, $cmd_env );

            } elsif ( $cmd_name eq 'install' ) {
                $self->ccmd_install( $msjobp_cmd_id, $cmd_name, $cmd_env );

            } elsif ( $cmd_name eq 'clean' ) {
                $self->ccmd_clean( $msjobp_cmd_id, $cmd_name, $cmd_env );
            }

            # debug sleep
            if ( 0 ) {
                my $sleep_time = 5;
                print "Debug sleep. Waiting for $sleep_time s ...\n" if $ver >= 1;
                sleep_and_process_keypress( $sleep_time );
            }
        }
        process_keypress(); # after each command
    }

    cleanup_before_exit();
    return 1;
}


=head1 AUTHOR

Michal Jurosz <mj@mj41.cz>

=head1 COPYRIGHT

Copyright (c) 2007-2008 Michal Jurosz. All rights reserved.

=head1 TODO

Refactoring
* remove direct KeyPress method calls from RepManager
* ...

=head1 LICENSE

TapTinder is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

TapTinder is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with Foobar.  If not, see <http://www.gnu.org/licenses/>.

=head1 BUGS

L<http://dev.taptinder.org/>

=head1 SEE ALSO

L<TapTinder>, L<TapTinder::Web>

=cut

1;
