package TapTinder::Client::WebAgent;

use strict;
use warnings;
use Carp qw(carp croak verbose);

use Data::Dumper;
use YAML;
use LWP::UserAgent;
use JSON;

our $VERSION = '0.10';
use constant REVISION => 150;


=head1 NAME

TapTinder::Client::WebAgent - TapTinder client web interaction

=head1 SYNOPSIS

See L<TapTinder::Client>

=head1 DESCRIPTION

TapTinder client ...

=cut


sub new {
    my ( $class, $taptinderserv, $machine_id, $machine_passwd, $ver, $debug ) = @_;

    my $self  = {};
    $self->{taptinderserv} = $taptinderserv;
    $self->{machine_id} = $machine_id;
    $self->{machine_passwd} = $machine_passwd;

    $ver = 2 unless defined $ver;
    $debug = 0 unless defined $debug;
    $self->{ver} = $ver;
    $self->{debug} = $debug;

    $self->{ua} = undef;

    bless ($self, $class);
    $self->init_ua();

    return $self;
}


sub init_ua {
    my ( $self, $ua_conf ) = @_;

    my $ua = LWP::UserAgent->new;
    $ua->agent( "TapTinder-client/" . REVISION );
    $ua->env_proxy;
    $self->{ua} = $ua;
    return 1;
}


sub run_action {
     my ( $self, $action, $request, $form_data ) = @_;

    my $taptinder_server_url = $self->{taptinderserv} . 'client/' . $action;
    my $resp;
    if ( $form_data ) {
        $resp = $self->{ua}->post( $taptinder_server_url, Content_Type => 'form-data', Content => $request );
    } else {
        $resp = $self->{ua}->post( $taptinder_server_url, $request );
    }
    if ( !$resp->is_success ) {
        croak "error: " . $resp->status_line . ' --- ' . $resp->content . "\n";
    }

    my $json_text = $resp->content;
    my $json = from_json( $json_text, {utf8 => 1} );

    if ( $self->{ver} >= 5 ) {
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
    my ( $self ) = @_;

    my $action = 'mscreate';
    my $request = {
        ot => 'json',
        mid => $self->{machine_id},
        pass => $self->{machine_passwd},
        crev => REVISION,
        pid => $$,
    };
    my $data = $self->run_action( $action, $request );
    return 0 unless defined $data;

    return ( 1, $data->{msid} );
}


sub msdestroy {
    my ( $self, $msession_id ) = @_;

    my $action = 'msdestroy';
    my $request = {
        ot => 'json',
        mid =>  $self->{machine_id},
        pass => $self->{machine_passwd},
        msid => $msession_id,
    };
    my $data = $self->run_action( $action, $request );
    return 0 unless defined $data;

    return 1;
}


sub cget {
    my ( $self, $msession_id, $attempt_number, $estimated_finish_time,
         $prev_msjobp_cmd_id ) = @_;

    my $action = 'cget';
    my $request = {
        ot =>   'json',
        mid =>  $self->{machine_id},
        pass => $self->{machine_passwd},
        msid => $msession_id,
        an => $attempt_number,
        eftime => $estimated_finish_time,
        pmcid => $prev_msjobp_cmd_id,
    };
    my $data = $self->run_action( $action, $request );
    return $data;
}


sub sset {
    my ( $self, $msession_id, $msjobp_cmd_id, $cmd_status_id,
         $end_time, $output_fpath, $outdata_fpath
    ) = @_;

    my $action = 'sset';
    my $request_upload = 0;
    my $request = {
        ot =>   'json',
        mid =>  $self->{machine_id},
        pass => $self->{machine_passwd},
        msid => $msession_id,
        mcid => $msjobp_cmd_id,
        csid => $cmd_status_id,
    };
    if ( $end_time ) {
        $request_upload = 1;
        $request->{etime} = $end_time;
    }
    if ( $output_fpath ) {
        $request_upload = 1;
        $request->{output_file} = [ $output_fpath, 'output_file_name' ];
    }
    if ( $outdata_fpath ) {
        $request_upload = 1;
        $request->{outdata_file} = [ $outdata_fpath, 'outdata_file_name' ];
    }
    my $data = $self->run_action( $action, $request, $request_upload );
    return $data;
}


sub rriget {
    my ( $self, $msession_id, $rep_path_id, $rev_id ) = @_;

    my $action = 'rriget';
    my $request = {
        ot =>   'json',
        mid =>  $self->{machine_id},
        pass => $self->{machine_passwd},
        msid => $msession_id,
        rpid => $rep_path_id,
        revid => $rev_id,
    };
    my $data = $self->run_action( $action, $request );
    return $data;
}


1;
