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

use TapTinder::Client::KeyPress qw(process_keypress sleep_and_process_keypress);
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

while ( 1 ) {

    my $sleep_time = 5;
    sleep_and_process_keypress( $sleep_time );
}


my_exit(1);

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
