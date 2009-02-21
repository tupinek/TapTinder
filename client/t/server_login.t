#! perl

use strict;
use warnings;
use Carp qw(carp croak verbose);
use FindBin qw($RealBin);

use File::Spec::Functions;
use YAML;
use LWP::UserAgent;
use JSON;
use Data::Dumper;

use constant REVISION => 150;


# debug output
{
    my $fresh;

    sub debug($) {
        my $msg = shift;

        print STDERR "* " and $fresh++ unless $fresh;
        print STDERR $msg;
        $fresh = 0 if substr( $msg, -1 ) eq "\n";
        1;
    }
}

my $conf_fpath = $ARGV[1] || catfile( $RealBin, '..', '..', 'client-conf', 'client-conf.yaml' );
my $project_name = $ARGV[0] || 'tt-test-proj';

sub load_client_conf {
    my ( $conf_fpath, $project_name ) = @_;

    croak "Can't find client configuration file '$conf_fpath'.\n" unless -f $conf_fpath;
    my ( $all_conf ) = YAML::LoadFile( $conf_fpath );
    unless ( exists $all_conf->{$project_name} ) {
        croak "Project '$project_name' configuration not found inside client config file '$conf_fpath'."
    }
    my $client_conf = $all_conf->{$project_name};
    return $client_conf;
}

my $client_conf = load_client_conf( $conf_fpath, $project_name );


my $ua = LWP::UserAgent->new;
$ua->agent( "TapTinder-client/" . REVISION );
$ua->env_proxy;


sub run_action {
     my ( $ua, $client_conf, $action, $request ) = @_;

    my $taptinder_server_url = $client_conf->{taptinderserv} . 'client/' . $action;
    my $resp = $ua->post( $taptinder_server_url => $request );
    if ( !$resp->is_success ) {
        debug "error: " . $resp->status_line . ' --- ' . $resp->content . "\n";
        exit 1;
    }

    my $json_text = $resp->content;
    my $json = from_json( $json_text, {utf8 => 1} );

    if ( 1 ) {
        print "action '$action' debug:\n";
        print Dumper( $request );
        print Dumper( $json );
        print "\n";
    }

    my $data = $json->{data};
    if ( $data->{ag_err} ) {
        # TODO ag_err_msesion_abort_reason_id
        carp $data->{ag_err_msg} . "\n";
        return undef;
    }

    if ( $data->{err} ) {
        carp $data->{err_msg} . "\n";
        return undef;
    }

    return $data;
}


sub mscreate {
    my ( $ua, $client_conf ) = @_;

    my $action = 'mscreate';
    my $request = {
        ot => 'json',
        mid => $client_conf->{machine_id},
        pass => $client_conf->{machine_passwd},
        crev => REVISION,
        pid => $$,
    };
    my $data = run_action( $ua, $client_conf, $action, $request );
    return 0 unless defined $data;

    return ( 1, $data->{msid} );
}


sub msdestroy {
    my ( $ua, $client_conf, $msession_id ) = @_;

    my $action = 'msdestroy';
    my $request = {
        ot => 'json',
        mid => $client_conf->{machine_id},
        pass => $client_conf->{machine_passwd},
        msid => $msession_id,
    };
    my $data = run_action( $ua, $client_conf, $action, $request );
    return 0 unless defined $data;

    return 1;
}


sub cget {
    my ( $ua, $client_conf, $msession_id, $run_number, $attempt_number,
         $estimated_finish_time, $prev_msjobp_cmd_id ) = @_;

    my $action = 'cget';
    my $request = {
        ot => 'json',
        mid => $client_conf->{machine_id},
        pass => $client_conf->{machine_passwd},
        msid => $msession_id,
        rn => $run_number,
        an => $attempt_number,
        eftime => $estimated_finish_time,
        pmcid => $prev_msjobp_cmd_id,
    };
    my $data = run_action( $ua, $client_conf, $action, $request );
    return $data;
}


my ( $login_rc, $msession_id ) = mscreate( $ua, $client_conf );


if ( ! $login_rc ) {
    croak "Login failed\n";
}

my $prev_msjobp_cmd_id = undef;
my $attempt_number = 1;
for my $num ( 1..4 ) {
    my $run_number = $num;
    my $estimated_finish_time = undef;
    my $data = cget(
        $ua, $client_conf, $msession_id, $run_number, $attempt_number,
        $estimated_finish_time, $prev_msjobp_cmd_id,
    );
    #print Dumper( $data );

    croak "cmd error\n" unless defined $data;
    if ( $data->{err} ) {
        croak $data->{err_msg};
    }
    if ( $data->{msjobp_cmd_id} ) {
        $prev_msjobp_cmd_id = $data->{msjobp_cmd_id};
        $attempt_number = 1;
    } else {
        carp "New msjobp_cmd_id not found.\n";
        $attempt_number++;
    }
}

msdestroy( $ua, $client_conf, $msession_id );




