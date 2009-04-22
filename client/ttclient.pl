#!perl

use strict;
use warnings;

use Carp qw(carp croak verbose);
use FindBin qw($RealBin);
use Data::Dumper;
use File::Spec::Functions;

# CPAN libs and own libs
use lib "$FindBin::Bin/../libcpan";
use lib "$FindBin::Bin/lib";

use YAML;

use Getopt::Long;
use Pod::Usage;

use TapTinder::Client;
use TapTinder::Client::Conf qw(load_client_conf);

my $help = 0;
my $project_name = 'tt-test-proj';
my $conf_fpath = catfile( $RealBin, '..', 'client-conf', 'client-conf.yml' );
my $ver = 2; # verbosity level
my $debug = 0; # debug
my $end_after_no_new_job = 0;

my $options_ok = GetOptions(
    'help|h|?' => \$help,
    'project|p=s' => \$project_name,
    'conf_fpath|cfp=s' => \$conf_fpath,
    'verbose|v=i' => \$ver,
    'debug|d=i' => \$debug,
    'end_after_no_new_job' => \$end_after_no_new_job,
);
pod2usage(1) if $help || !$options_ok;

# TODO - Check parameters.
if ( $ver !~ /^\s*\d+\s*$/ || $ver < 0 || $ver > 5 ) {
    croak "Parameter error: ver is not 0-5.\n";
}

print "Verbose level: $ver\n" if $ver >= 3;
print "Working path: '" . $RealBin . "'\n" if $ver >= 4;

print "Loading config file for project '$project_name'.\n" if $ver >= 3;

my $client_conf = load_client_conf( $conf_fpath, $project_name );

# debug, will also dump passwd on screen
# print Dumper( $client_conf ) if $ver >= 5;

print "Starting Client.\n" if $ver >= 3;

my $base_dir = catdir( $RealBin, '..' );
my $client = TapTinder::Client->new(
    $client_conf,
    $base_dir,
    {
        ver => $ver,
        debug => $debug,
        end_after_no_new_job => $end_after_no_new_job,
    }
);
$client->run();

exit;

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
   --end_after_no_new_job ... Will end if new job not found.

=head1 DESCRIPTION

B<This program> will start TapTinder client.

=cut
