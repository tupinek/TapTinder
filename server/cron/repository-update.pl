use DBI;
use strict;

use Carp qw(carp croak verbose);
use FindBin qw($RealBin);

use Data::Dumper;
use File::Spec::Functions;
use Devel::StackTrace;

use SVN::Log;


my $conf_fpath = catfile( $RealBin, '..', 'conf', 'dbconf.pl' );
my $conf = require $conf_fpath;
croak "Config loaded from '$conf_fpath' is empty.\n" unless $conf;

my $project_name = 'parrot';
my $conf_rep = $conf->{project}->{$project_name};

my $log_dump_refresh = $ARGV[0] || $conf_rep->{log_dump_refresh};
my $debug = $ARGV[1] || 0;
my $debug_logpart = $ARGV[2] || 0;

my $state_fn = catfile( $RealBin,'..', 'conf', $project_name . '-replog-state.pl' );
my $log_dump_file = $project_name.'-replog-dump.pl';
$log_dump_file = $project_name.'-replog-debugdump.pl' if $debug_logpart;
my $log_dump_fn = catfile( $RealBin, '..', 'conf', $log_dump_file );

my $dbh;
my $sth_cache;

my $dbh = DBI->connect(
    $conf->{db}->{dsn},
    $conf->{db}->{user},
    $conf->{db}->{password},
    { RaiseError => 0, AutoCommit => 0 }
) or die $DBI::errstr;


sub trc {
    my $trace = Devel::StackTrace->new;
    return $trace->as_string;
}

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
}
else {
    $state = {};
    $state->{project_name} = $project_name;
    $state->{create_time} = time();
    $state->{log_dump_time} => undef;
    $state->{rev_to_db_saved} => undef;
    save_state();
}


my $revs;
my $last_log_rev;
unless ( -e $log_dump_fn ) {
    $last_log_rev = 1;
} 
else {
    print "reading svn log dump from $log_dump_fn...\n";
    $revs = require $log_dump_fn;
    $last_log_rev = $revs->[-1]->{revision};
    print "done\n";
}
print "last_log_rev: $last_log_rev\n" if $debug > 1;


# each $log_dump_refresh hours add fresh log info
if ( ( !$debug_logpart || (not -e $log_dump_fn) )
     && $state->{rep}->{log_dump_time} + $log_dump_refresh < time()
   )
{
    my $to_rev = 'HEAD';
    $to_rev = '100' if $debug_logpart;
    print "getting svn log for revisions $last_log_rev..$to_rev online...\n";
    my $new_revs = SVN::Log::retrieve ($conf_rep->{repository}, $last_log_rev, $to_rev);
    
    #shift @$new_revs;
    #print dmp( $new_revs );
    if ( scalar @$new_revs > 0 ) {
        if ( defined $revs ) {
            $revs = [ @$revs, @$new_revs ]; # merge
        } else {
            $revs = $new_revs;
        }
        open my $fh, ">", $log_dump_fn or croak;
        print $fh dmp( $revs );
        close $fh;

        $last_log_rev = $revs->[-1]->{revision};
        print "done\n";
    } else {
        print "no newer revisions found\n";
    }

    $state->{rep}->{log_dump_time} = time();
    save_state();
}


sub log_error {
    my ( $dbh, $rd, $msg ) = @_;
    
    $dbh->rollback;
    $dbh->disconnect;
    if ( defined $rd ) {
        croak 
            $msg
            . "\n"
            . "For revison " . $rd->{revision} . ".\n"
            . dmp( $rd ) ."\n"
        ;
    }
}


sub db_error {
    my ( $dbh, $msg ) = @_;
    
    $dbh->rollback;
    $dbh->disconnect;
    $msg = '' unless defined $msg;
    $msg .= $dbh->errstr;
    $msg .= "\n\n" . trc();
    croak $msg;
}


sub dump_get {
    my ( $sub_name, $ra_args, $results ) = @_;
    print "function $sub_name, input (" . join(', ',@$ra_args) . "), result " . dmp($results);
}

# next functions use global variables $dbh, $sth_cache, $debug

# $repository, $project_name
sub get_rep_id {
    my $cname = (caller(0))[3];
    unless ( defined $sth_cache->{$cname} ) {
        $sth_cache->{$cname} = $dbh->prepare(qq{
            select rep_id
              from rep, project 
             where rep.path = ? 
               and rep.active = 1
               and project.project_id = rep.project_id
               and project.name = ?
        }) or croak $dbh->errstr;
    }
    my $result = $dbh->selectrow_hashref( $sth_cache->{$cname}, {}, @_ );
    db_error($dbh) if $sth_cache->{$cname}->err;
    print dump_get( $cname, \@_, $result ) if $debug;
    return $result->{rep_id};
}


# $rep_id
sub get_rep_users {
    my $cname = (caller(0))[3];
    unless ( defined $sth_cache->{$cname} ) {
        $sth_cache->{$cname} = $dbh->prepare(qq{
            select user_rep_id,
                   rep_login
              from user_rep
             where rep_id = ?
        }) or croak $dbh->errstr;
    }
    $sth_cache->{$cname}->execute( @_ );
    my $result = $sth_cache->{$cname}->fetchall_hashref( 'rep_login' );
    db_error($dbh) if $sth_cache->{$cname}->err;
    print dump_get( $cname, \@_, $result ) if $debug;
    return $result;
}

# $rep_id, $rep_login (null)
sub get_rep_user_id {
    my $cname = (caller(0))[3];
    unless ( defined $sth_cache->{$cname} ) {
        $sth_cache->{$cname} = $dbh->prepare(qq{
            select user_rep_id
              from user_rep
             where rep_id = ?
               and rep_login = ? OR (rep_login IS NULL AND ? = 1)
        }) or croak $dbh->errstr;
    }
    my $result = $dbh->selectrow_hashref(
        $sth_cache->{$cname}, {},
        @_[0], @_[1], defined(@_[1]) ? 0 : 1
    );
    db_error($dbh) if $sth_cache->{$cname}->err;
    print dump_get( $cname, \@_, $result ) if $debug;
    return $result->{user_rep_id};
}

# $rep_id, $rep_login
sub insert_rep_user {
    my $cname = (caller(0))[3];
    unless ( defined $sth_cache->{$cname} ) {
        $sth_cache->{$cname} = $dbh->prepare(qq{
            insert into user_rep ( rep_id, rep_login ) values ( ?, ? )
        }) or croak $dbh->errstr;
    }
    $sth_cache->{$cname}->execute( @_ );
    db_error($dbh) if $sth_cache->{$cname}->err;
    #my $result = $dbh->last_insert_id( undef, undef, undef, undef);
    my $result = get_rep_user_id( @_[0], @_[1] );
    print dump_get( $cname, \@_, $result ) if $debug;
    return $result;
}


# $rep_id, $rep_path
sub get_rep_path_id {
    my $cname = (caller(0))[3];
    unless ( defined $sth_cache->{$cname} ) {
        $sth_cache->{$cname} = $dbh->prepare(qq{
            select rep_path_id
              from rep_path
             where rep_id = ?
               and path = ?
        }) or croak $dbh->errstr;
    }
    my $result = $dbh->selectrow_hashref( $sth_cache->{$cname}, {}, @_ );
    db_error($dbh) if $sth_cache->{$cname}->err;
    print dump_get( $cname, \@_, $result ) if $debug;
    return $result->{rep_path_id};
}

# $rep_id, $rep_path, $base_rev_id
sub insert_rep_path {
    my $cname = (caller(0))[3];
    unless ( defined $sth_cache->{$cname} ) {
        $sth_cache->{$cname} = $dbh->prepare(qq{
            insert into rep_path ( rep_id, path ) values ( ?, ? )
        }) or croak $dbh->errstr;
    }
    $sth_cache->{$cname}->execute( @_ );
    db_error($dbh) if $sth_cache->{$cname}->err;
    my $result = get_rep_path_id( @_[0], @_[1] );
    print dump_get( $cname, \@_, $result ) if $debug;
    return $result;
}


# $rev_id, $rep_path_id
sub exists_rev_rep_path {
    my $cname = (caller(0))[3];
    unless ( defined $sth_cache->{$cname} ) {
        $sth_cache->{$cname} = $dbh->prepare(qq{
            select 1 as found
              from rev_rep_path
             where rev_id = ?
               and rep_path_id = ?
        }) or croak $dbh->errstr;
    }
    my $result = $dbh->selectrow_hashref( $sth_cache->{$cname}, {}, @_ );
    db_error($dbh) if $sth_cache->{$cname}->err;
    print dump_get( $cname, \@_, $result ) if $debug;
    return $result->{found};
}


# $rev_id, $rep_path_id
sub insert_rev_rep_path {
    my $cname = (caller(0))[3];
    unless ( defined $sth_cache->{$cname} ) {
        $sth_cache->{$cname} = $dbh->prepare(qq{
            insert into rev_rep_path ( rev_id, rep_path_id ) values ( ?, ? )
        }) or croak $dbh->errstr;
    }
    $sth_cache->{$cname}->execute( @_ );
    db_error($dbh) if $sth_cache->{$cname}->err;
    my $result = get_rep_path_id( @_[0], @_[1] );
    print dump_get( $cname, \@_, $result ) if $debug;
    return $result;
}




# $rev_num
sub get_rev_id {
    my $cname = (caller(0))[3];
    unless ( defined $sth_cache->{$cname} ) {
        $sth_cache->{$cname} = $dbh->prepare(qq{
            select rev_id
              from rev
             where rev_num = ?
        }) or croak $dbh->errstr;
    }
    my $result = $dbh->selectrow_hashref( 
        $sth_cache->{$cname},
        {},
        @_[0]
    );
    db_error($dbh) if $sth_cache->{$cname}->err;
    print dump_get( $cname, \@_, $result ) if $debug;
    return $result->{rev_id};
}

# $rep_id
sub get_max_rev_num {
    my $cname = (caller(0))[3];
    unless ( defined $sth_cache->{$cname} ) {
        $sth_cache->{$cname} = $dbh->prepare(qq{
            select max(rev.rev_num) as max
              from rep_path, rev_rep_path, rev
             where rep_path.rep_id = ?
               and rev_rep_path.rep_path_id = rep_path.rep_path_id
               and rev.rep_id = rev_rep_path.rev_id
        }) or croak $dbh->errstr;
    }
    my $result = $dbh->selectrow_hashref( $sth_cache->{$cname}, @_ );
    db_error($dbh) if $sth_cache->{$cname}->err;
    print dump_get( $cname, \@_, $result ) if $debug;
    return $result->{max};
}

# $rev_num, $date, $rep_user_id (author_id), $msg
sub insert_rev {
    my $cname = (caller(0))[3];
    unless ( defined $sth_cache->{$cname} ) {
        $sth_cache->{$cname} = $dbh->prepare(qq{
            insert into rev ( rev_num, author_id, date, msg ) values ( ?, ?, ?, ? )
        }) or croak $dbh->errstr;
    }
    $sth_cache->{$cname}->execute( @_ );
    db_error($dbh) if $sth_cache->{$cname}->err;
    my $result = get_rev_id( @_[0], @_[1] );
    print dump_get( $cname, \@_, $result ) if $debug;
    return $result;
}


# $sub_path, $rep_path_id, $revision
sub get_rep_file_id {
    my $cname = (caller(0))[3];
    my ( $sub_path, $rep_path_id, $revision ) = @_;
    unless ( defined $sth_cache->{$cname} ) {
        $sth_cache->{$cname} = $dbh->prepare(qq{
            select rep_file_id
              from rep_file
             where rep_path_id = ?
               and sub_path = ?
               and rev_num_from <= ?
               and (rev_num_to IS NULL OR rev_num_to >= ?)
        }) or croak $dbh->errstr;
    }
    my $result = $dbh->selectrow_hashref( 
        $sth_cache->{$cname},
        {},
        $rep_path_id, $sub_path, $revision, $revision
    );
    db_error($dbh) if $sth_cache->{$cname}->err;
    print dump_get( $cname, \@_, $result ) if $debug;
    return $result->{rev_file_id};
}

# $sub_path, $rep_path_id, $revision
sub insert_rep_file {
    my $cname = (caller(0))[3];
    unless ( defined $sth_cache->{$cname} ) {
        $sth_cache->{$cname} = $dbh->prepare(qq{
            insert into rep_file ( sub_path, rep_path_id, rev_num_from ) values ( ?, ?, ? )
        }) or croak $dbh->errstr;
    }
    $sth_cache->{$cname}->execute( @_ );
    db_error($dbh) if $sth_cache->{$cname}->err;
    my $result = get_rep_file_id( @_[0], @_[1], @_[2] );
    print dump_get( $cname, \@_, $result ) if $debug;
    return $result;
}


# $sub_path, $rep_path_id, $revision
sub set_rep_file_deleted {
    my $cname = (caller(0))[3];
    my ( $sub_path, $rep_path_id, $revision ) = @_;
    unless ( defined $sth_cache->{$cname} ) {
        $sth_cache->{$cname} = $dbh->prepare(qq{
            update rep_file
               set rev_num_to = ?
             where rep_path_id = ?
               and sub_path = ?
               and rev_num_from <= ?
               and rev_num_to is null
        }) or croak $dbh->errstr;
    }
    $sth_cache->{$cname}->execute( 
        $revision, $rep_path_id, $sub_path, $revision
    );
    db_error($dbh) if $sth_cache->{$cname}->err;
    my $result = get_rep_file_id( @_[0], @_[1], @_[2] );
    print dump_get( $cname, \@_, $result ) if $debug;
    return $result;
}


sub set_rep_file_modified {
    my ( $sub_path, $rep_path_id, $revision ) = @_;
    return 1;
}


my $rep_id = get_rep_id( $conf_rep->{repository}, $project_name );

# userting users into user_rep table
my $users = get_rep_users( $rep_id );
foreach my $rd ( @$revs ) {
    my $author = $rd->{'author'}; # can be null, will create row in rep_user
    if ( exists $users->{$author} ) {
        print "author '$author' exists in DB, user_rep_id=" . $users->{$author}->{user_rep_id} . "\n" if $debug > 3;
    }
    else {
        print "author '$author' not exists in DB, inserting\n" if $debug > 1;
        my $user_rep_id = insert_rep_user( $rep_id, $author );
        # temporary data, probably different keys than in data loaded from DB
        $users->{$author} = {
            user_rep_id => $user_rep_id,
            rep_login => $author,
        }
    }
}
$dbh->commit or db_error( $dbh, "Commiting users failed." );
$users = get_rep_users( $rep_id );

# /trunk, /braches/BRANCHNAME, /tags/TAGNAME
sub split_rep_path {
    my ( $project_name, $path ) = @_;
    
    if ( my ( $base, $oth ) = $path =~ m{^(/trunk|/branches/[^\/]+|/tags/[^\/]+)(.*?)$} ) {
        return ( $base, $oth );
    }
    return ( undef, undef );
}


sub svntime_to_dbtime {
    my ( $svn_time ) = @_;
    return $svn_time;
}


sub process_file {
    my ( $dbh, $sub_path, $info, $revision, $rep_path_id ) = @_;

    my $action = $info->{action};

    if ( $action eq 'A' || $action eq 'R' ) {
        insert_rep_file( $sub_path, $rep_path_id, $revision );
    }
    elsif ( $action eq 'D' ) {
        set_rep_file_deleted( $sub_path, $rep_path_id, $revision );
    }
    elsif ( $action eq 'M' ) {
        set_rep_file_modified( $sub_path, $rep_path_id, $revision );
    }
    else {
        $@ = "Uknown file svn action '$action'.";
        return 0;
    }

    return 1;
}

# todo, doesn't work
my $max_revnum_in_db = get_max_rev_num( $rep_id );
print "max_revnum_in_db: $max_revnum_in_db\n" if $debug > 3;
$max_revnum_in_db = 0 unless defined $max_revnum_in_db;

foreach my $rd ( @$revs ) {
    if ( $rd->{revision} <= $max_revnum_in_db ) {
        #print "Skipping rev $rd->{revision}\n";
        next;
    }
    
    # insert rev if needed
    my $rev_id = get_rev_id( $rd->{'revision'} );
    unless ( defined $rev_id ) {
        my $date_ts = svntime_to_dbtime( $rd->{date} );
        log_error( $dbh, $rd, "Time parser error datestr '$rd->{date}'." ) unless defined $date_ts;
        my $author_rep_user_id = $users->{ $rd->{'author'} }->{user_rep_id};
        $rev_id = insert_rev( 
            $rd->{'revision'},
            $author_rep_user_id,
            $date_ts,
            $rd->{'message'}
        );
    }

    # group files by rep_path
    # table rev can contain same rev_num for different rev_path_ids
    my $rp_changes = {};
    
    foreach my $path ( sort keys %{$rd->{'paths'}} ) {
        my $path_info = $rd->{'paths'}->{$path};
        my $action = $path_info->{'action'};
        # rep_path -> rev -> rep_file

        if ( $action eq 'D' ) {
            #next;
        }

        if ( $path eq '/' || $path eq '/tags' || $path eq '/branches' ) {
            carp "Skipping path '$path'.\n";
            next;
        }

        my ( $rep_path, $sub_path ) = split_rep_path( $project_name, $path );
        log_error( $dbh, $rd, "Parsing path '$path' failed." ) unless defined $rep_path;

        unless ( exists $rp_changes->{$rep_path} ) {
            $rp_changes->{$rep_path} = {
                sub_paths => {},
            };

            # get or insert rep_path
            my $rep_path_id = get_rep_path_id( $rep_id, $rep_path );
            unless ( defined $rep_path_id ) {
                $rep_path_id = insert_rep_path( $rep_id, $rep_path );
            }

            # insert rev_rep_path unless exists
            unless ( exists_rev_rep_path( $rev_id, $rep_path_id ) ) {
                insert_rev_rep_path( $rev_id, $rep_path_id );
            }

            $rp_changes->{$rep_path}->{rep_path_id} = $rep_path_id;
        }
        # store ref to path info
        $rp_changes->{$rep_path}->{sub_paths}->{$sub_path} = $rd->{'paths'}->{$path};
        print "rep_path: $rep_path, sub_path: $sub_path\n" if $debug > 4;
    }
    
    print dmp( $rp_changes );
    #$dbh->rollback; die;

    my @rp_keys = keys %$rp_changes;
    if ( scalar @rp_keys > 0 ) {
        foreach my $rep_path ( @rp_keys ) {
            my $rep_path_id = $rp_changes->{$rep_path}->{rep_path_id};
            #$dbh->commit or db_error( $dbh, "Commiting rev_num $rd->{'revision'} failed." );

            my $sub_paths = $rp_changes->{$rep_path}->{sub_paths};
            foreach my $sub_path ( sort keys %$sub_paths ) {
                my $info = $sub_paths->{$sub_path};
                process_file( $dbh, $sub_path, $info, $rd->{'revision'}, $rep_path_id ) or log_error( $dbh, $rd, $@ );
            }
        }
    }
    
    $dbh->commit or db_error( $dbh, "Commiting all changes for $rd->{'revision'} failed." );

    print "rev " . $rd->{'revision'} . " done, ok\n" if $debug > 1;

    if ( $debug > 9 ) {
        print dmp($rd) if $debug > 9;
        print "rev:" . $rd->{'revision'};
        print ", autor: " . $rd->{'author'};
        print ", date: " . $rd->{'date'};
        print "\n";
        my $msg = $rd->{'message'};
        print "msg:\n";
        $msg =~ s{\r}{}sg;
        $msg =~ s{^\n}{}sg;
        $msg =~ s{\n+$}{}sg;
        $msg = '  ' . $msg;
        $msg =~ s{\n}{\n  }sg;
        print $msg;
        print "\n";
        print "files:\n";
        foreach my $rkey ( sort keys %{$rd->{'paths'}} ) {
            print "  " . $rd->{'paths'}->{$rkey}->{'action'} . " " . $rkey . "\n";
        }
    }
    
    #$state->{rev_to_db_saved} = $rd->{revisions};
    # save_state();
    
}

$dbh->commit or db_error( $dbh, "End commit failed." );
$dbh->disconnect;
