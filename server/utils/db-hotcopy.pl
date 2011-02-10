#! perl

$| = 1;

use strict;
use warnings;

use Carp qw(carp croak verbose);
use FindBin qw($RealBin);

use YAML;
use File::Spec::Functions;

use lib "$RealBin/../lib";
use TapTinder::Utils::Cmd qw(run_cmd_ipc);
use TapTinder::Utils::DB qw(get_connected_schema);



sub dbutil_hotcopy {
    my ( $src_conf, $dest_conf, $hotcopy_dpath ) = @_;

    unless ( -d $hotcopy_dpath ) {
        print "Creating directory '$hotcopy_dpath'.\n";
        mkdir($hotcopy_dpath) or return 0;
    }

    my $cmd_dump = 'mysqlhotcopy';
    $cmd_dump .= " --noindices --allowold";
    $cmd_dump .= " -u '" . $src_conf->{db}->{user} . "'";
    $cmd_dump .= " -p '" . $src_conf->{db}->{pass} . "'";

    $cmd_dump .= " '" . $src_conf->{db}->{name} . "'";
    $cmd_dump .= " '" . $hotcopy_dpath . "'";

    #print "cmd_dump: $cmd_dump\n";

    print "Running mysqlhotcopy '$src_conf->{db}->{name}' -> '$hotcopy_dpath':\n";
    my $dump_rc = TapTinder::Utils::Cmd::run_cmd_ipc( $cmd_dump, 1, undef );
    return $dump_rc;
}




my $src_conf_fpath  = $ARGV[0] || catfile( $RealBin, '..', '..', '..', 'tt', 'server', 'conf', 'web_db.yml' );
croak "Source config file path not given." unless $src_conf_fpath;
croak "Source config file '$src_conf_fpath' not found." unless -f $src_conf_fpath;

my $dest_conf_fpath  = $ARGV[1] || catfile( $RealBin, '..', 'conf', 'web_db.yml' );
croak "Destination config file '$dest_conf_fpath' not found." unless -f $dest_conf_fpath;

my $hotcopy_conf_fpath  = $ARGV[1] || catfile( $RealBin, '..', 'conf', 'hotcopy.yml' );
croak "Hotcopy credential config file '$hotcopy_conf_fpath' not found." unless -f $hotcopy_conf_fpath;

my ( $src_conf ) = YAML::LoadFile( $src_conf_fpath );
croak "Configuration for source database loaded from '$src_conf_fpath' is empty.\n" unless $src_conf->{db};

my ( $dest_conf ) = YAML::LoadFile( $dest_conf_fpath );
croak "Configuration for destination database loaded from '$dest_conf_fpath' is empty.\n" unless $dest_conf->{db};

my ( $hotcopy_conf ) = YAML::LoadFile( $hotcopy_conf_fpath );
croak "Configuration for destination database loaded from '$hotcopy_conf_fpath' is empty.\n" unless $hotcopy_conf->{user};

exit;

my $dest_schema = get_connected_schema( $dest_conf->{db} );
croak "Connection to destination DB failed." unless $dest_schema;

my $rc = undef;

# Hotcopy.
my $dest_dpath =  '/var/lib/mysql-backup';
$rc = dbutil_hotcopy( $src_conf, $dest_conf, $dest_dpath );
unless ( $rc ) {
    croak "Drop all tables failed.";
}

# Drop all tables.
$dest_schema->storage->txn_begin;
$rc = TapTinder::Utils::DB::do_drop_all_existing_tables( $dest_schema );
unless ( $rc ) {
    croak "Drop all tables failed.";
}
$dest_schema->storage->txn_commit;
$dest_schema = undef;



my $dest_hotcopy_conf = $dest_conf->{db};
$dest_hotcopy_conf->{user} = $hotcopy_conf->{user};
$dest_hotcopy_conf->{pass} = $hotcopy_conf->{pass};
my $dest_schema_hotcopy_user = get_connected_schema( $dest_hotcopy_conf );


my $source_path = '/var/lib/mysql-backup/' . $src_conf->{db}->{name};
$rc = TapTinder::Utils::DB::restore_all_tables_from( $dest_schema_hotcopy_user, $source_path );
unless ( $rc ) {
    croak "Restore all tables failed.";
}
