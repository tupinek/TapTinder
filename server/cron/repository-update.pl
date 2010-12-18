#! perl

use strict;
use warnings;
use Carp qw(carp croak verbose);
use FindBin qw($RealBin);

use Getopt::Long;
use Pod::Usage;

use Data::Dumper;
use File::Spec::Functions;
use Devel::StackTrace;
use Git::Repository;

use lib "$FindBin::Bin/../lib";
use Git::Repository::LogRaw;
use TapTinder::DB;
use TapTinder::Utils::Conf qw(load_conf_multi);

my $help = 0;
my $project_name = undef;
my $ver = 2;
my $debug_logpart = 0;
my $options_ok = GetOptions(
    'help|h|?' => \$help,
    'project|p=s' => \$project_name,
    'ver|v=i' => \$ver,
);
pod2usage(1) if $help || !$options_ok;

unless ( $project_name ) {
    print "Project name not found.\n\n";
    pod2usage(1);
    exit 0;
}

my $cm_dir = catfile( $FindBin::Bin , '..', 'conf' );
my $conf = load_conf_multi( $cm_dir, 'db', 'project' );

croak "Configuration for database is empty.\n" unless $conf->{db};
croak "Configuration for projects is empty.\n" unless $conf->{project};

unless ( $conf->{project}->{ $project_name } ) {
    croak "Configuration for project '$project_name' not found.";
}

my $conf_rep = $conf->{project}->{$project_name};

my $base_dir = catdir( $FindBin::RealBin, '..', '..' );
my $work_tree = catdir( $base_dir, 'server-repos', $project_name );
my $state_fn = catfile( $base_dir, 'server-repos', $project_name . '-state.pl' );


my $repo_url = $conf_rep->{repository};

my $db = TapTinder::DB->new();
$db->debug( $ver >= 3 );
$db->connect( $conf->{db} );

sub dmp {
    my $dd = Data::Dumper->new( [ @_ ] );
    $dd->Indent(1);
    $dd->Terse(1);
    $dd->Purity(1);
    $dd->Deepcopy(1);
    $dd->Deparse(1);
    return $dd->Dump;
}

my $state;

sub save_state {
    open SFH, ">", $state_fn or croak;
    print SFH dmp($state)."\n";
    close SFH;
}

if ( -e $state_fn ) {
    $state = require $state_fn;
    if ( $project_name ne $state->{project_name} ) {
        print "Loaded state conf for project '$state->{project_name}', but your project name is '$project_name'";
    }
} else {
    $state = {};
    $state->{project_name} = $project_name;
    $state->{create_time} = time();
    save_state();
}


my $repo = undef;
unless ( -d $work_tree ) {
    print "Cloning '$repo_url' to '$work_tree'.\n";
    $repo = Git::Repository->create( 
        clone => $repo_url => $work_tree,
    );

} else {
    print "Initializing from '$work_tree'.\n";
    $repo = Git::Repository->new( 
        work_tree => $work_tree,
    );
}
print "\n";


my $log_obj = Git::Repository::LogRaw->new( $repo, $ver );
my $log = $log_obj->get_log( $repo );

#print Dumper( $log );

my $rep_id = $db->get_rep_id( $conf_rep->{repository} );
croak "Repository id not found for '$conf_rep->{repository}'." unless $rep_id;

print "rep_id $rep_id\n";



$db->commit or $db->db_error( "End commit failed." );
$db->disconnect;

=head1 NAME

repository-update - Save new revisions to database

=head1 SYNOPSIS

repository-update.pl -p project_name [options]

 Options:
   --help

=head1 DESCRIPTION

B<This program> will save ...

=cut
