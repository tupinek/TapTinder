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

use constant VERSION => 0.01;


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
$ua->agent( "TapTinder-client/" . VERSION );
$ua->env_proxy;

sub do_login {
    my ( $ua, $client_conf ) = @_;

    my $action = 'login';
    my %request = (
        uid => $client_conf->{client_id},
        pass => $client_conf->{client_passwd},
        version => VERSION,
        ot => 'json',
    );

    my $taptinder_server_url = $client_conf->{taptinderserv} . 'client/' . $action;

    my $resp = $ua->post( $taptinder_server_url => \%request );
    if ( !$resp->is_success ) {
        debug "error: " . $resp->status_line . ' --- ' . $resp->content . "\n";
        exit 1;
    }

    my $json_text = $resp->content;
    my $json = from_json( $json_text, {utf8 => 1} );
    my $data = $json->{data};

    print Dumper( $json );

    if ( !$data->{login_ok} ) {
        carp $data->{login_msg} . "\n";
    }
    return $data->{login_ok};
}

my $login_rc = do_login( $ua, $client_conf );





