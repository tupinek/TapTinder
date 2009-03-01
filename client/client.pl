#!perl

use strict;
use warnings;

use Carp qw(carp croak verbose);
use FindBin qw($RealBin);

use File::Spec::Functions;
use File::Path;
use File::Copy;

use lib "$FindBin::Bin/../libcpan";
use Data::Dump qw(dump);
use File::Copy::Recursive qw(dircopy);
use YAML;

use lib 'lib';
use lib "$FindBin::Bin/lib";
use Watchdog qw(sys sys_for_watchdog);
use SVNShell qw(svnversion svnup svndiff);

use TapTinder::Client::KeyPress qw(process_keypress sleep_and_process_keypress);

# verbose level
#  >0 .. print errors
#  >1 .. verbose 1 - print base run info about sucesfull svn ups
#  >2 .. verbose 2 - default
#  >3 .. verbose 3
#  >4
#  >5 .. debug output
#  >10 .. set params to devel value

my $ver = $ARGV[0] ? $ARGV[0] : 2;

$TapTinder::Client::KeyPress::ver = 10;
Term::ReadKey::ReadMode('cbreak');
select(STDOUT); $| = 1;


print "Verbose level: $ver\n" if $ver > 2;
print "Working path: '" . $RealBin . "'\n" if $ver > 3;

print "Loading config file.\n" if $ver > 2;

my $fn_client_config = 'client-conf.yml';
my $fp_client_conf = catfile( $RealBin, '..', 'client-conf', $fn_client_config );
print "Client config file path: '" . $fp_client_conf . "'\n" if $ver > 5;
unless ( -e $fp_client_conf ) {
    croak
        "Client config file '$fn_client_config' not found.\n"
        . "Use '$fn_client_config'.example to create one.\n"
    ;
}
my ( $client_conf ) = YAML::LoadFile( $fp_client_conf );
dump( $client_conf ) if $ver > 6;
