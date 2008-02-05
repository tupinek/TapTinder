use DBI;
use strict;

use Carp qw(carp croak verbose);
use FindBin qw($RealBin);

use File::Spec::Functions;


my $conf_fpath = catfile( $RealBin, '..', 'conf', 'dbconf.pl' );
my $conf = require $conf_fpath;
croak "Config loaded from '$conf_fpath' is empty.\n" unless $conf;

my $dbh = DBI->connect(
    $conf->{db}->{dsn},
    $conf->{db}->{user},
    $conf->{db}->{password},
    { RaiseError => 1, AutoCommit => 0 }
) or die $DBI::errstr;


my $sth = $dbh->prepare("SELECT client_id, user_id, created, last_login, ip, cpuarch, osname, archname, active  FROM client WHERE active=1");
$sth->execute();

while ( my @row = $sth->fetchrow_array ) {
    print join(' | ',@row) . "\n";
}

$dbh->commit;
$dbh->disconnect;
