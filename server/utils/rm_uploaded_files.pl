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
my $remove = 0;
my $server_conf_fpath = catfile( $RealBin, '..', 'conf', 'web_db.yml' );

my $options_ok = GetOptions(
    'help|h|?' => \$help,
    'remove|rm' => \$remove,
    'server_conf_fpath|scfp' => \$server_conf_fpath
);
pod2usage(1) if $help || !$options_ok;

croak "Can't find server configuration file '$server_conf_fpath'.\n" unless -f $server_conf_fpath;
my ( $server_conf ) = YAML::LoadFile( $server_conf_fpath );
croak "Configuration for database loaded from '$server_conf_fpath' is empty.\n" unless $server_conf->{db};

my $dbh = DBI->connect(
    $server_conf->{db}->{dbi_dsn},
    $server_conf->{db}->{user},
    $server_conf->{db}->{pass},
    { RaiseError => 1, AutoCommit => 0 }
) or croak $DBI::errstr;

my $sql_cmd = "
    select fsp.fspath_id, fsp.path, fsp.name
      from fspath fsp
     where fsp.deleted is null
";
my $sth = $dbh->prepare($sql_cmd) or croak $dbh->errstr;
$sth->execute();
while ( my $fp_info = $sth->fetchrow_hashref ) {
    print "$fp_info->{fspath_id} $fp_info->{name}: '$fp_info->{path}' \n";

    my $dir = $fp_info->{path};
    opendir(my $dh, $dir) || die "can't opendir $dir: $!";
    my @files = grep { -f "$dir/$_" } readdir($dh);
    closedir $dh;

    if ( @files ) {
        foreach my $file ( sort @files ) {
            print "  $file";
            if ( $remove ) {
                my $ok = unlink( "$dir/$file" );
                if ( $ok ) {
                    print " - removed";
                } else {
                    print " - unlink failed - $!";
                }
            }
            print "\n";
        }
    } else {
        print " No files found.\n";
    }
}

$dbh->commit;
$dbh->disconnect;


__END__

=head1 NAME

rm_uploaded_files - Remove all files from all not deleted paths in fspath.path table.

=head1 SYNOPSIS

rm_uploaded_files [options]

 Options:
   --help
   --remove .. Will remove files. Default only print file list.
   --server_conf_fpath

=head1 DESCRIPTION

B<This program> will remove ...

=cut
