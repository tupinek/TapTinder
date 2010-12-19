#! perl

use strict;
use warnings;
use Carp qw(carp croak verbose);
use FindBin qw($RealBin);

use Getopt::Long;
use Pod::Usage;

use DateTime;
use Data::Dumper;
use File::Spec::Functions;
use Devel::StackTrace;
use Git::Repository;

use lib "$FindBin::Bin/../lib";
use Git::Repository::LogRaw;
use TapTinder::DB;
use TapTinder::Utils::Conf qw(load_conf_multi);
use TapTinder::Utils::DB qw(get_connected_schema);

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

my $schema = get_connected_schema( $conf->{db} );
croak "Connection to DB failed." unless $schema;


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


sub find_or_create_rep {
    my ( $schema, $project_name, $repo_url ) = @_;
    
    my $rep_id = $schema->resultset('rep')->find(
        {
            repo_url => $repo_url,
            name  => $project_name,
        }, {
            join => 'project_id',
        }
    );
    
    return $rep_id if $rep_id;
    
    my $project_id = $schema->resultset('project')->find_or_create({
        name   => $project_name,
    });
    
    $rep_id = $schema->resultset('rep')->find_or_create({
        repo_url   => $repo_url,
        project_id => $project_id,
        active => 1,
    });

    return $rep_id;
}
  
#print Dumper( $log );
$schema->storage->txn_begin;

  
my $rep_row = find_or_create_rep( $schema, $project_name, $repo_url );
#print Dumper( { $rep_row->get_columns } );
my $rep_id = $rep_row->get_column('rep_id');
print "rep_id $rep_id\n";

my $rcommit_rs = $schema->resultset('rcommit')->search(
    {},
    {
        join => 'sha_id',
    }
);

my $rcommits_rows = [ $rcommit_rs->cursor->all ]; 

print Dumper( $rcommits_rows );


$rcommit_rs = $schema->resultset('rcommit');
my $sha_rs = $schema->resultset('sha');
my $rauthor_rs = $schema->resultset('rauthor');
my $rcommit_sha_list = {};
my $all_ok = 1;
LOG_COMMIT: foreach my $log_commit ( @$log ) {
    
    print "log msg '$log_commit->{msg}'\n";
    
    my $first_parent_sha = undef;
    my $first_parent_sha_id = undef;
    if ( defined $log_commit->{parents}->[0] ) {
       $first_parent_sha = $log_commit->{parents}->[0];
       unless ( exists $rcommit_sha_list->{$first_parent_sha} ) {
          $all_ok = 0; 
          last LOG_COMMIT;
       }
       $first_parent_sha_id = $rcommit_sha_list->{$first_parent_sha};
    }
    
    my $rcommit_sha = $log_commit->{commit};
    my $rcommit_sha_id = $sha_rs->create({
        sha => $rcommit_sha,
    })->id;
    #my $rcommit_sha_id = $rcommit_sha_row->get_column('sha_id');
    $rcommit_sha_list->{ $rcommit_sha } = $rcommit_sha_id;

    my $tree_sha_id = $sha_rs->find_or_create({
        sha => $log_commit->{tree},
    })->id;

    my $author_id = $rauthor_rs->find_or_create({
        rep_login => $log_commit->{author}->{name},
        email => $log_commit->{author}->{email},
        rep_id => $rep_id,
    })->id;

    my $committer_id = $rauthor_rs->find_or_create({
        rep_login => $log_commit->{committer}->{name},
        email => $log_commit->{committer}->{email},
        rep_id => $rep_id,
    })->id;
    
    
    $rcommit_rs->create({
        rep_id => $rep_id,
        msg => $log_commit->{msg},
        sha_id => $rcommit_sha_id,
        tree_id => $tree_sha_id,
        parents_num => scalar @{$log_commit->{parents}},
        parent_id => $first_parent_sha_id,
        author_id => $author_id,
        author_time => DateTime->from_epoch( 
            epoch => $log_commit->{author}->{gmtime},
            time_zone => 'GMT',
        ),
        committer_id => $committer_id,
        committer_time => DateTime->from_epoch( 
            epoch => $log_commit->{committer}->{gmtime},
            time_zone => 'GMT',
        ),
    });
    
}

if ( $all_ok ) {
    print "Doing commit.\n";
    $schema->storage->txn_commit;
} else {
    print "Doing rollback.\n";
    $schema->storage->txn_rollback;
}

=head1 NAME

repository-update - Save new revisions to database

=head1 SYNOPSIS

repository-update.pl -p project_name [options]

 Options:
   --help

=head1 DESCRIPTION

B<This program> will save ...

=cut
