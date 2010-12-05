#! perl

use strict;
use warnings;

use Carp qw(carp croak verbose);
use FindBin qw($RealBin);

use YAML;
use File::Spec::Functions;

use lib "$RealBin/../lib";
use TapTinder::Utils::Cmd qw(run_cmd_ipc);

my $src_conf_fpath  = $ARGV[0];
croak "Source config file path not given." unless $src_conf_fpath;
croak "Source config file '$src_conf_fpath' not found." unless -f $src_conf_fpath;

my $dest_conf_fpath  = $ARGV[1] || catfile( $RealBin, '..', 'conf', 'web_db.yml' );
croak "Destination config file '$dest_conf_fpath' not found." unless -f $dest_conf_fpath;

my ( $src_conf ) = YAML::LoadFile( $src_conf_fpath );
croak "Configuration for source database loaded from '$src_conf_fpath' is empty.\n" unless $src_conf->{db};

my ( $dest_conf ) = YAML::LoadFile( $dest_conf_fpath );
croak "Configuration for destination database loaded from '$dest_conf_fpath' is empty.\n" unless $dest_conf->{db};

my $cmd_dump = 'mysqlhotcopy';
$cmd_dump .= " -u '" . $src_conf->{db}->{user} . "'";
$cmd_dump .= " -p '" . $src_conf->{db}->{pass} . "'";
$cmd_dump .= " --allowold";

$cmd_dump .= " '" . $src_conf->{db}->{name} . "'";
$cmd_dump .= " '" . $dest_conf->{db}->{name} . "'";

#print "cmd_dump: '$cmd_dump'\n";

print "Runnign mysqlhotcopy '$src_conf->{db}->{name}' -> '$dest_conf->{db}->{name}':\n";
my $dump_rc = TapTinder::Utils::Cmd::run_cmd_ipc( $cmd_dump, 1, undef );
