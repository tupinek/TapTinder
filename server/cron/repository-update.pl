#!perl

=pod

ToDo
* refactor to package/objects
* add tests
** https://github.com/mj41/TapTinder/issues#issue/25
* speed up 
** initil parrot to DB takes 15 minutes

=cut

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
use TapTinder::Utils::DB qw(get_connected_schema do_dbh_sql get_dbh_errstr);

my $help = 0;
my $project_name = undef;
my $ver = 2;
my $debug_logpart = 0;
my $steps_str = undef;
my $options_ok = GetOptions(
    'help|h|?' => \$help,
    'project|p=s' => \$project_name,
    'ver|v=i' => \$ver,
    'steps=s' => \$steps_str,
);
pod2usage(1) if $help || !$options_ok;

sub option_fatal_err {
    my ( $msg ) = @_;
    print $msg . "\n\n"  if $ver >= 1;
    pod2usage(1);
    exit 0;
}

option_fatal_err("Project name not found.") unless $project_name;

my $cm_dir = catfile( $FindBin::Bin , '..', 'conf' );
my $conf = load_conf_multi( $cm_dir, 'db', 'project' );

croak "Configuration for database is empty.\n" unless $conf->{db};
croak "Configuration for projects is empty.\n" unless $conf->{project};

unless ( $conf->{project}->{ $project_name } ) {
    croak "Configuration for project '$project_name' not found.";
}

my $steps = {
    pull => 1,
    commits => 1,
    refs => 1,
};
if ( defined $steps_str ) {
    my @steps_opt = split( /\s*,\s*/, $steps_str );
    option_fatal_err("Error in --step value '$steps_str'.") unless scalar @steps_opt;
    foreach my $step_key ( keys %$steps ) {
        $steps->{$step_key} = 0 ;
    }
    foreach my $step_key ( @steps_opt ) {
        option_fatal_err("Unknown step '$step_key' name.") unless exists $steps->{ $step_key };
        $steps->{ $step_key } = 1;
    }
}


my $start_time = time();
print "Starting repository update for project '$project_name'.\n" if $ver >= 2;

my $conf_rep = $conf->{project}->{$project_name};

my $base_dir = catdir( $FindBin::RealBin, '..', '..' );
my $work_tree = catdir( $base_dir, 'server-repos', $project_name );
my $state_fn = catfile( $base_dir, 'server-repos', $project_name . '-state.pl' );


my $repo_url = $conf_rep->{repository};

print "Connecting to DB.\n" if $ver >= 3;
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
    open SFH, ">", $state_fn or croak $!;
    print SFH dmp($state)."\n";
    close SFH;
}

if ( -e $state_fn ) {
    $state = require $state_fn;
    if ( $project_name ne $state->{project_name} ) {
        print "Loaded state conf for project '$state->{project_name}', but your project name is '$project_name'" if $ver >= 3;;
    }
    print "State file loaded.\n" if $ver >= 3;

} else {
    $state = {};
    $state->{project_name} = $project_name;
    $state->{create_time} = time();
    save_state();
    print "State file created.\n" if $ver >= 3;
}


my $repo = undef;
unless ( -d $work_tree ) {
    print "Cloning '$repo_url' to '$work_tree'.\n" if $ver >= 3;
    $repo = Git::Repository->create( 
        clone => $repo_url => $work_tree,
    );

} else {
    print "Initializing from '$work_tree'.\n" if $ver >= 3;
    $repo = Git::Repository->new( 
        work_tree => $work_tree,
    );
    if ( $steps->{pull} ) {
        print "Running 'git pull'.\n" if $ver >= 2;
        $repo->command( 'pull' );
    }
}

my $gitrepo_obj = Git::Repository::LogRaw->new( $repo, $ver );


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
    })->id;

    return $rep_id;
}
  
my $rep_id = find_or_create_rep( $schema, $project_name, $repo_url );
print "Repository for '$project_name' and '$repo_url' has rep_id=$rep_id.\n" if $ver >= 3;

print "Starting transaction.\n" if $ver >= 3;
$schema->storage->txn_begin;

my $all_ok = 1;

my $rcommit_rs = $schema->resultset('rcommit')->search(
    {},
    {
        join => 'sha_id',
        'select' => [ 'me.rcommit_id', 'sha_id.sha', 'me.parent_id', 'me.rline_id' ],
    }
);
my $rcommits_sha_list = {};
my $has_descendant = {};
my $rcommits_rline_id = {};
foreach my $rcommit_row ( $rcommit_rs->cursor->all ) {
    my $rcommit_id = $rcommit_row->[0];
    my $sha = $rcommit_row->[1];
    $rcommits_sha_list->{ $sha } = $rcommit_id;
    if ( defined $rcommit_row->[2] ) {
        my $parent_id = $rcommit_row->[2];
        $has_descendant->{ $parent_id } = 1;
    }
    $rcommits_rline_id->{ $rcommit_id } = $rcommit_row->[3];
}


sub finish_rcommits_set {
    my ( $schema, $rline_last_rcommit_id_update, $rline_merged_info ) = @_;
    
    my $rline_rs = $schema->resultset('rline');
    my $rcommit_rs = $schema->resultset('rcommit');
    foreach my $rline_id ( keys %$rline_last_rcommit_id_update ) {
        my $new_values = $rline_last_rcommit_id_update->{ $rline_id };

        my $rline_row = $rline_rs->find( $rline_id );
        $rline_row->update( $new_values );
    }
    
    foreach my $data ( @$rline_merged_info ) {
        my $rline_id = $data->[0];
        my $merged_to_rline_id = $data->[1];
        print "Merged $rline_id to $merged_to_rline_id - changing rcommits.\n" if $ver >= 4;
        my $sql = "
            update rcommit
               set super_rline_id = ?
             where ( rline_id = ? and rline_id = super_rline_id )
                or ( super_rline_id = ? and rline_id <> super_rline_id )
        ";
        my $ba = [ $merged_to_rline_id, $rline_id, $rline_id, ];
        my $rc = do_dbh_sql( $schema, $sql, $ba );
        return 0 unless $rc;
    }
    
    $rline_last_rcommit_id_update = {};
    $rline_merged_info = [];
    
    return 1;
}


my $commits_added_num = 0;
my $err = [];
if ( $steps->{commits} ) {
    print "Adding new commits.\n" if $ver >= 2;

    print "Loading log.\n" if $ver >= 3;
    my $log = $gitrepo_obj->get_log(
        $rcommits_sha_list  # $ssh_skip_list
    );
    print "Found " . (scalar @$log) . " new commit log items.\n" if $ver >= 3;
    #print Dumper( $log );
    
    my $rcommit_rs = $schema->resultset('rcommit');
    my $sha_rs = $schema->resultset('sha');
    my $rauthor_rs = $schema->resultset('rauthor');
    my $rcparent_rs = $schema->resultset('rcparent');
    my $rline_rs = $schema->resultset('rline');
    my $rline_hier_rs = $schema->resultset('rline_hier');
    my $rline_last_rcommit_id_update = {};
    my $rline_merged_info = [];
    my $new_rcommits_num = 0;
    LOG_COMMIT: foreach my $log_num ( 0..$#$log ) {
        my $log_commit = $log->[ $log_num ];
        #last if $log_num > $#$log / 2; # debug

        my $rcommit_sha = $log_commit->{commit};
        next if exists $rcommits_sha_list->{ $rcommit_sha };
        
        print "Log msg '$log_commit->{msg}'\n" if $ver >= 5;
        
        my $first_parent_sha = undef;
        my $first_parent_rcommit_id = undef;
        if ( defined $log_commit->{parents}->[0] ) {
           $first_parent_sha = $log_commit->{parents}->[0];
           unless ( exists $rcommits_sha_list->{$first_parent_sha} ) {
              push @$err, "First parent rcommit_id not found in sha_lit for sha '$first_parent_sha'.";
              $all_ok = 0; 
              last LOG_COMMIT;
           }
           $first_parent_rcommit_id = $rcommits_sha_list->{ $first_parent_sha };
        }
        
        my $rcommit_sha_id = $sha_rs->create({
            sha => $rcommit_sha,
        })->id;

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


        my $parents = $log_commit->{parents};
        my $num_of_parents = scalar @$parents;
        my $insert_new_rline_id = undef;
        my $rline_id = undef;
        # no ancestor
        if ( $num_of_parents == 0 ) {
            $insert_new_rline_id = 1;

        # one parent without descendant
        } elsif ( $num_of_parents == 1 && $has_descendant->{$first_parent_rcommit_id} ) {
            $insert_new_rline_id = 1;

        # one parent already with at least one descendant
        # more than one parent
        } else {
            unless ( exists $rcommits_rline_id->{ $first_parent_rcommit_id } ) {
                push @$err, "First parent rline_id not found in rcommits_rline_id list for rcommit_id '$first_parent_rcommit_id'.";
                $all_ok = 0; 
                last LOG_COMMIT;
            }
            $insert_new_rline_id = 0;
            $rline_id = $rcommits_rline_id->{ $first_parent_rcommit_id };
        }
        
        my $rline_row;
        if ( $insert_new_rline_id ) {
            $rline_row = $rline_rs->create({
                first_rcommit_id => undef,
                last_rcommit_id => undef,
            });
            $rline_id = $rline_row->id;

            # self link
            $rline_hier_rs->create({
                rline_id => $rline_id,
                super_rline_id => $rline_id,
            });
        }
        
        if ( defined $first_parent_rcommit_id ) {
           $has_descendant->{ $first_parent_rcommit_id } = 1;
        }
        
        my $rcommit_row = $rcommit_rs->create({
            rep_id => $rep_id,
            msg => $log_commit->{msg},
            sha_id => $rcommit_sha_id,
            tree_id => $tree_sha_id,
            parents_num => $num_of_parents,
            parent_id => $first_parent_rcommit_id,
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
            super_rline_id => $rline_id,
            rline_id => $rline_id,
        });
        my $rcommit_id = $rcommit_row->id;
        $rcommits_sha_list->{ $rcommit_sha } = $rcommit_id;
        $rcommits_rline_id->{ $rcommit_id } = $rline_id;

        # update rline row
        if ( $insert_new_rline_id ) {
            $rline_row->update( {
                first_rcommit_id => $rcommit_id,
                last_rcommit_id => $rcommit_id,
            } );
        }
        
        $rline_last_rcommit_id_update->{ $rline_id }->{last_rcommit_id} = $rcommit_id;

        if ( $num_of_parents >= 2 ) {
            foreach my $parent_num ( 1..$#$parents ) {
                my $parent_sha = $parents->[ $parent_num ];
                unless ( exists $rcommits_sha_list->{ $parent_sha } ) {
                    push @$err, "Parent rcommit_id not found in sha_lit for sha '$parent_sha'.";
                    $all_ok = 0; 
                    last LOG_COMMIT;
                }
                         
                my $parent_rcommit_id = $rcommits_sha_list->{ $parent_sha };
                unless ( exists $rcommits_rline_id->{ $parent_rcommit_id } ) {
                    push @$err, "Parent rline_id not found in rcommits_rline_id list for rcommit_id '$parent_rcommit_id'.";
                    $all_ok = 0; 
                    last LOG_COMMIT;
                }

                # skip first parent
                $rcparent_rs->create({
                    child_id => $rcommit_id,
                    parent_id => $parent_rcommit_id,
                    num => $parent_num+1,
                });

                my $parent_rline_id = $rcommits_rline_id->{ $parent_rcommit_id };
                
                # merge link
                $rline_hier_rs->create({
                    rline_id => $parent_rline_id,
                    super_rline_id => $rline_id, # first parent rline_id
                });

                $has_descendant->{ $parent_rcommit_id } = 1;
                $rline_last_rcommit_id_update->{ $parent_rline_id }->{merged} = 1;
                push @$rline_merged_info, [ $parent_rline_id, $rline_id ];
            }
        }
        
        if ( $new_rcommits_num >= 1000 ) {
            # ToDo - Its too slow to do this each time.
            my $rc = finish_rcommits_set( $schema, $rline_last_rcommit_id_update, $rline_merged_info );
            unless ( $rc ) {
                push @$err, "Method finish_rcommits_set errror: " . get_dbh_errstr($schema);
                $all_ok = 0; 
                last LOG_COMMIT;
            }
            
            print "Commiting transaction.\n" if $ver >= 3;
            $schema->storage->txn_commit;
            print "Already added $commits_added_num commits.\n" if $ver >= 3;

           
            print "Starting new transaction.\n" if $ver >= 3;
            $schema->storage->txn_begin;

            $new_rcommits_num = 0;
        }
        $new_rcommits_num++;
        
        $commits_added_num++;
    } # end foreach

    my $rc = finish_rcommits_set( $schema, $rline_last_rcommit_id_update, $rline_merged_info );
    unless ( $rc ) {
        push @$err, "Method finish_rcommits_set errror: " . get_dbh_errstr($schema);
        $all_ok = 0; 
    }
    print "Added $commits_added_num new commits.\n" if $ver >= 3;

} # end if


sub get_db_refs {
    my ( $schema, $rep_id ) = @_;
    
    my $all_rref_rs = $schema->resultset('rref')->search({
        'rcommit_id.rep_id' => $rep_id,
    }, {
        join => { 'rcommit_id' => 'sha_id', },
        select => [ 'me.rref_id', 'me.active', 'me.fullname', 'sha_id.sha', ],
        as => [ 'rref_id', 'active', 'fullname', 'sha', ],
    });
    my $db_refs = {};
    while ( my $row = $all_rref_rs->next ) {
        $db_refs->{ $row->get_column('fullname') } = { $row->get_columns };
    }
    return $db_refs;
}


my $rref_updated_num = 0;
my $rref_removed_num = 0;
if ( $all_ok && $steps->{refs} ) {
    print "Doing refs update.\n" if $ver >= 2;
    # Hash $db_refs is used to cache DB values. Used keys are removed during processiong
    # repository refs. Then remainning keys are used to deactivate refs in db.
    my $db_refs = get_db_refs( $schema, $rep_id );
    print Dumper( $db_refs ) if $ver >= 5;

    my $repo_refs = $gitrepo_obj->get_refs( 'remote_ref' );
    my $rcommit_rs = $schema->resultset('rcommit');
    my $rref_rs = $schema->resultset('rref');
    REF_LIST: foreach my $ref_key ( keys %$repo_refs ) {
        my $ref_info = $repo_refs->{ $ref_key };
        my $ref_sha = $ref_info->{sha};
        my $ref_fullname = $ref_info->{fullname};
        
        # Not changed.
        if ( exists $db_refs->{$ref_key} ) {
            if ( ! $db_refs->{$ref_key}->{active} ) {
                my $rref_id = $db_refs->{$ref_key}->{rref_id};
                my $row = $rref_rs->find( $rref_id );
                my $rcommit_id = $rcommits_sha_list->{ $ref_sha };
                $row->update({
                    active => 1,
                    rcommit_id => $rcommit_id,
                });
                print "Activating a probably also updating '$ref_key'.\n" if $ver >= 3;
                $rref_updated_num++;
            } elsif ( $db_refs->{$ref_key} eq $ref_sha ) {
                print "Ref '$ref_key' not changed.\n" if $ver >= 4;
            }
            delete $db_refs->{$ref_key};
            next REF_LIST;
        }
        
        unless ( exists $rcommits_sha_list->{ $ref_sha } ) {
            push @$err, "Can't find rcommit_id for sha '$ref_sha' in sha_list.";
            $all_ok = 0; 
            last REF_LIST;
        }
        my $rcommit_id = $rcommits_sha_list->{ $ref_sha };
        $rref_rs->update_or_create(
            {
                fullname => $ref_key,
                name => $ref_info->{branch_name},
                rcommit_id => $rcommit_id,
                active => 1,
            }, {
                fullname => $ref_key,
            }
        );
        print "Updating '$ref_key'.\n" if $ver >= 3;
        $rref_updated_num++;
    }
    print "Updated $rref_updated_num refs.\n" if $ver >= 3;

    #print Dumper( $db_refs );
    foreach my $ref_key ( keys %$db_refs ) {
        next unless $db_refs->{ $ref_key }->{active};
        my $rref_id = $db_refs->{ $ref_key }->{rref_id};
        my $row = $rref_rs->find( $rref_id );
        $row->update({active => 0});
        $rref_removed_num++;
    }
    print "Deactivated $rref_removed_num refs.\n" if $ver >= 3;
 
    $db_refs = get_db_refs( $schema, $rep_id );
    print Dumper( $db_refs ) if $ver >= 5;
   
} # end if


if ( $ver >= 2 && ($commits_added_num == 0 && $rref_updated_num == 0 && $rref_removed_num == 0) ) {
    print "Nothing to do.\n";
}

if ( $all_ok ) {
    print "Doing commit.\n" if $ver >= 3;
    $schema->storage->txn_commit;

} else {
    print "Doing rollback.\n" if $ver >= 2;
    if ( $ver >= 1 ) {
        print "Error mesages:\n";
        print join("\n", @$err );
        print "\n";
    }
    $schema->storage->txn_rollback;
}

save_state();
my $time_diff = time() - $start_time;
print "Script takes ${time_diff}s to run.\n" if $ver >= 3;

=head1 NAME

repository-update - Update copy of project repository and related project database tables.

=head1 SYNOPSIS

repository-update.pl -p project_name [options]

 Options:
   --help
   --ver=%d .. Verbose level (default 2).
   --project=%s .. Project name.
   --steps=%s .. Steps to run (default --step=pull,commits,refs).

=head1 DESCRIPTION

B<This program> will clone/pull reposioty and fill/update related database tables.

=cut
