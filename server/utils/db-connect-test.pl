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
) or croak $DBI::errstr;


my $sth = $dbh->prepare("
    SELECT machine_id, user_id, name, info, ip,
           cpuarch, osname, archname, active, created,
           last_login, prev_machine_id
      FROM machine WHERE active=1
");
$sth->execute();

while ( my @row = $sth->fetchrow_array ) {
    print join(' | ',@row) . "\n";
}

$dbh->commit;
$dbh->disconnect;
