use DBI;
use strict;

use Carp qw(carp croak verbose);
use FindBin qw($RealBin);

use YAML;
use File::Spec::Functions;

my $sql_fpath = $ARGV[0] || undef;
my $noipc = $ARGV[1] || 0;

croak "SQL file '$sql_fpath' not found." unless -f $sql_fpath;

my $conf_fpath = catfile( $RealBin, '..', 'conf', 'web_db.yml' );
my ( $conf ) = YAML::LoadFile( $conf_fpath );
croak "Configuration for database loaded from '$conf_fpath' is empty.\n" unless $conf->{db};

croak "Database name not found.\n" unless $conf->{db}->{name};
croak "Database user name not found.\n" unless $conf->{db}->{user};
croak "Database user password not found.\n" unless $conf->{db}->{pass};

my $cmd = 'mysql -u ' . $conf->{db}->{user};
if ( $noipc ) {
    $cmd .= " -p'" . $conf->{db}->{pass} . "'";
} else {
    $cmd .= ' -p';
}
$cmd .= ' ' . $conf->{db}->{name};
$cmd .= ' < ' . $sql_fpath;

#print "cmd: '$cmd'\n";

# TODO IPC version (no password on command line or process list)

$! = undef;
$@ = undef;
if ( ! $noipc ) {
    print "Enter database password for user '$conf->{db}->{user}': ";
}
my $ret_code = system( $cmd );
print "Return code: $ret_code - ";
if ( $ret_code ) {
    print "error";
} else {
    print "ok";
}
print "\n";

print $! if $!;
print $@ if $@;
