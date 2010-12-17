#!perl

use strict;
use warnings;
use Carp qw(carp croak verbose);
use FindBin qw($RealBin);

use Getopt::Long;
use Pod::Usage;

use Data::Dumper;
use File::Spec::Functions;

use lib "$FindBin::Bin/../lib";
use TapTinder::DB;
use TapTinder::Utils::Conf qw(load_conf_multi);
use TapTinder::Utils::DB qw(get_connected_schema);

my $help = 0;
my $ver = 2;
my $save = 0;
my $deploy = 0;
my $options_ok = GetOptions(
    'save' => \$save,
    'deploy' => \$deploy,
    'help|h|?' => \$help,
    'ver|v=i' => \$ver,
);
pod2usage(1) if $help || !$options_ok || ( !$save && !$deploy );

my $conf = load_conf_multi( undef, 'db' );
croak "Configuration for database is empty.\n" unless $conf->{db};

my $schema = get_connected_schema( $conf->{db} );

if ( $save ) {
    my $ddl_dir = catdir( $RealBin, '..', 'temp', 'deploy-ddl' );
    unless ( - $ddl_dir ) {
        mkdir $ddl_dir or croak $!;
    }

    my $drop_sql = TapTinder::Utils::DB::get_drop_all_existing_tables_sql( $schema );
    my $drop_sql_fpath = catfile( $ddl_dir, 'drop-all-tables.sql' );
    my $fh;
    open( $fh, '>'.$drop_sql_fpath ) || croak $!;
    print $fh $drop_sql;
    close $fh;

    $schema->create_ddl_dir('MySQL', undef, $ddl_dir);

    print "DDL files saved to $ddl_dir\n" if $ver >= 2;
}

if ( $deploy ) {
    my $rc = TapTinder::Utils::DB::do_drop_all_existing_tables( $schema );
    $schema->deploy();
}


=head1 NAME

deploy - Deploy utility.

=head1 SYNOPSIS

perl deploy.pl [options]

 Options:
   --save .. Save ddl files to temp/deploy-ddl.
   --deploy .. Drop all tables and deploy new schema.
   --help
   --ver=$NUM .. Verbosity level. Default 2.

=head1 DESCRIPTION

B<This program> will delete ..

=cut
