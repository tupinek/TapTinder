#! perl

use strict;
use warnings;
use Carp qw(carp croak verbose);
use FindBin qw($RealBin);

use Getopt::Long;
use Pod::Usage;

use File::Spec::Functions;
use YAML;
use DBI;

my $help = 0;
my $client_project_name = 'tt-test-proj';
my $machine_id = '';
my $machine_name = '';
my $client_new_passwd = '';
my $client_conf_fpath = catfile( $RealBin, '..', '..', 'client-conf', 'client-conf.yaml' );
my $server_conf_fpath = catfile( $RealBin, '..', 'conf', 'dbconf.pl' );

my $options_ok = GetOptions(
    'help|h|?' => \$help,
    'machine_id|mid=i' => \$machine_id,
    'machine_name|mn=s' => \$machine_name,
    'passwd|p=s' => \$client_new_passwd,
    'client_conf_fpath|ccfp' => \$client_conf_fpath,
    'client_project_name|cpn=s' => \$client_project_name,
    'server_conf_fpath|scfp' => \$server_conf_fpath
);
pod2usage(1) if $help || !$options_ok;

croak "You can't set both machine_id and machine_name." if $machine_id && $machine_name;

# load client data from configuration file
my $machine_selected = ( $machine_id || $machine_name );
if ( !$machine_selected || !$client_new_passwd ) {
    croak "Can't find client configuration file '$client_conf_fpath'.\n" unless -f $client_conf_fpath;
    my ( $all_client_conf ) = YAML::LoadFile( $client_conf_fpath );
    unless ( exists $all_client_conf->{$client_project_name} ) {
        croak "Project '$client_project_name' configuration not found inside client config file '$client_conf_fpath'."
    }
    my $client_conf = $all_client_conf->{$client_project_name};

    if ( !$machine_id && !$machine_name ) {
        $machine_id = $client_conf->{client_id};
    }
    if ( !$client_new_passwd ) {
        $client_new_passwd = $client_conf->{client_passwd};
    }
}

croak "Can't find server configuration file '$server_conf_fpath'.\n" unless -f $server_conf_fpath;
my $server_conf = require $server_conf_fpath;
croak "Config loaded from '$server_conf_fpath' is empty.\n" unless $server_conf;

my $dbh = DBI->connect(
    $server_conf->{db}->{dsn},
    $server_conf->{db}->{user},
    $server_conf->{db}->{password},
    { RaiseError => 1, AutoCommit => 0 }
) or croak $DBI::errstr;


my $sth;

my @bv = ( $client_new_passwd );
my $sql = 'UPDATE machine SET passwd=substring(MD5(?), -8) WHERE ';
if ( $machine_id ) {
    $sql .= 'machine_id=?';
    push @bv, $machine_id;
} else {
    $sql .= 'name=?';
    push @bv, $machine_name;
}
$sth = $dbh->prepare($sql);
$sth->execute( @bv );

$dbh->commit;
$dbh->disconnect;

print "Password set.\n";

__END__

=head1 NAME

set_client_passwd - Loads client configuration file and sets client (machine) password to database.

=head1 SYNOPSIS

set_client_passwd [options]

 Options:
   --help
   --machine_id
   --machine_name
   --passwd
   --client_conf_fpath
   --client_project_name
   --server_conf_fpath

=head1 DESCRIPTION

B<This program> will set password ...

=cut
