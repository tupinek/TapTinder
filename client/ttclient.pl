#!perl

use strict;
use warnings;

use Carp qw(carp croak verbose);
use FindBin qw($RealBin);

use File::Spec::Functions;
use File::Path;
use File::Copy;

# CPAN libs
use lib "$FindBin::Bin/../libcpan";
use Data::Dump qw(dump);
use File::Copy::Recursive qw(dircopy);
use YAML;

use Getopt::Long;
use Pod::Usage;

# own libs
use lib "$FindBin::Bin/lib";
use Watchdog qw(sys sys_for_watchdog);
use SVNShell qw(svnversion svnup svndiff);

use TapTinder::Client::KeyPress qw(process_keypress sleep_and_process_keypress cleanup_before_exit);
use TapTinder::Client::WebAgent;
use TapTinder::Client::Conf qw(load_client_conf);

# verbose level
#  >0 .. print errors only
#  >1 .. print base run info
#  >2 .. all run info (default)
#  >3 .. major debug info
#  >4 .. major and minor debug info
#  >5 .. all debug info

my $help = 0;
my $project_name = 'tt-test-proj';
my $conf_fpath = catfile( $RealBin, '..', 'client-conf', 'client-conf.yml' );
my $ver = 2; # verbosity level
my $debug = 1; # debug

my $options_ok = GetOptions(
    'help|h|?' => \$help,
    'project|p=s' => \$project_name,
    'conf_fpath|cfp=s' => \$conf_fpath,
    'verbose|v=i' => \$ver,
);
pod2usage(1) if $help || !$options_ok;

# TODO - Check parameters.
if ( $ver !~ /^\s*\d+\s*$/ || $ver < 0 || $ver > 5 ) {
    croak "Parameter error: ver is not 0-5.\n";
}


# KeyPress init
$TapTinder::Client::KeyPress::ver = 10;
Term::ReadKey::ReadMode('cbreak');
select(STDOUT); $| = 1;

my ( $agent, $msession_id );
$TapTinder::Client::KeyPress::sub_before_exit = sub {
    Term::ReadKey::ReadMode('normal');
    if ( $msession_id ) {
        $agent->msdestroy( $msession_id );
    }
};


print "Verbose level: $ver\n" if $ver >= 3;
print "Working path: '" . $RealBin . "'\n" if $ver >= 4;

print "Loading config file for project '$project_name'.\n" if $ver >= 3;

my $client_conf = load_client_conf( $conf_fpath, $project_name );
process_keypress();

# debug, will also dump passwd on screen
# dump( $client_conf ) if $ver >= 5;

print "Starting WebAgent.\n" if $ver >= 3;
$agent = TapTinder::Client::WebAgent->new( $client_conf );
process_keypress();

print "Creating new machine session.\n" if $ver >= 3;
my $login_rc;
( $login_rc, $msession_id ) = $agent->mscreate();

if ( ! $login_rc ) {
    croak "Login failed\n";
}
process_keypress();

my $prev_msjobp_cmd_id = undef;
my $attempt_number = 1;
while ( 1 ) {
    my $estimated_finish_time = undef;
    my $data = $agent->cget(
        $msession_id, $attempt_number, $estimated_finish_time,
        $prev_msjobp_cmd_id,
    );
    #print Dumper( $data );

    croak "cmd error\n" unless defined $data;
    if ( $data->{err} ) {
        croak $data->{err_msg};
    }

    if ( $data->{msjobp_cmd_id} ) {
        $prev_msjobp_cmd_id = $data->{msjobp_cmd_id};
        $attempt_number = 1;

        my $cmd_name = $data->{cmd_name};
        if ( $cmd_name eq 'get_src' ) {
            my $data = $agent->rriget(
                $msession_id, $data->{rep_path_id}, $data->{rev_id}
            );
            croak "cmd error\n" unless defined $data;
            if ( $data->{err} ) {
                croak $data->{err_msg};
            }
            if ( $ver >= 2 ) {
                print "Getting revision $data->{rev_num} from $data->{rep_path}$data->{rep_path_path}\n";
            }
        }

        $data = $agent->sset(
            $msession_id,
            $prev_msjobp_cmd_id, # $msjobp_cmd_id
            2 # running, $cmd_status_id
        );
        if ( $data->{err} ) {
            croak $data->{err_msg};
        }

        if ( 1 ) {
            my $status = 3; # todo
            my $output_file_path = catfile( $RealBin, 'README' );
            $data = $agent->sset(
                $msession_id,
                $prev_msjobp_cmd_id, # $msjobp_cmd_id
                $status,
                time(), # $end_time, TODO - is GMT?
                $output_file_path
            );

            if ( $data->{err} ) {
                croak $data->{err_msg};
            }
        }

        # debug
        my $sleep_time = 0;
        print "Debug sleep. Waiting for $sleep_time s ...\n" if $ver >= 1;
        sleep_and_process_keypress( $sleep_time );

    } else {
        print "New msjobp_cmd_id not found.\n";
        last if $debug;
        $attempt_number++;
        $prev_msjobp_cmd_id = undef;

        my $sleep_time = 15;
        print "Waiting for $sleep_time s ...\n" if $ver >= 1;
        sleep_and_process_keypress( $sleep_time );
    }
}

cleanup_before_exit();
exit;

__END__

=head1 NAME

ttclient - TapTinder client.

=head1 SYNOPSIS

ttclient [options]

 Options:
   --help
   --project ... Project name.
   --conf_fpath ... Config file path.
   --ver ... Verbose level, 0-5, default 2.

=head1 DESCRIPTION

B<This program> will start TapTinder client.

=cut
