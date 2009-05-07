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

use lib "$FindBin::Bin/../lib";
use SVN::Log;

#$SVN::Log::FORCE_COMMAND_LINE_SVN = 1;

use lib "$FindBin::Bin/../lib";
use TapTinder::DB;
use TapTinder::Utils::Conf qw(load_conf_multi);

my $help = 0;
my $project_name = undef;
my $debug = 0;
my $debug_logpart = 0;
my $options_ok = GetOptions(
    'help|h|?' => \$help,
    'project|p=s' => \$project_name,
    'debug|p=i' => \$debug,
);
pod2usage(1) if $help || !$options_ok;

unless ( $project_name ) {
    print "Project name not found.\n\n";
    pod2usage(1);
    exit 0;
}

my $cm_dir = catfile( $FindBin::Bin , '..', 'conf' );
my $conf = load_conf_multi( $cm_dir, 'db', 'project' );

# print Dumper($conf); exit();
croak "Configuration for database is empty.\n" unless $conf->{db};
croak "Configuration for projects is empty.\n" unless $conf->{project};

unless ( $conf->{project}->{ $project_name } ) {
    croak "Configuration for project '$project_name' not found.";
}

my $conf_rep = $conf->{project}->{$project_name};
my $log_dump_refresh = $conf_rep->{log_dump_refresh} || 150;

my $state_fn = catfile( $RealBin,'..', 'conf', $project_name . '-replog-state.pl' );
my $log_dump_file = $project_name.'-replog-dump.pl';
$log_dump_file = $project_name.'-replog-debugdump.pl' if $debug_logpart;
my $log_dump_fn = catfile( $RealBin, '..', 'conf', $log_dump_file );


my $db = TapTinder::DB->new();
$db->debug( $debug );
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
}
else {
    $state = {};
    $state->{project_name} = $project_name;
    $state->{create_time} = time();
    $state->{rep} = {};
    $state->{rep}->{log_dump_time} = undef;
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
    print "getting svn log for revisions $last_log_rev..$to_rev for $conf_rep->{repository} online...\n";
    my $new_revs = SVN::Log::retrieve( $conf_rep->{repository}, $last_log_rev, $to_rev );

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


my $rep_id = $db->get_rep_id( $conf_rep->{repository} );

my $max_revnum_in_db = $db->get_max_rev_num( $rep_id );
unless ( defined $max_revnum_in_db ) {
    my $num_of_revs_found = $db->get_number_of_revs( $rep_id );
    croak "No max rev found, but some revs exists." if $num_of_revs_found;
    $max_revnum_in_db = 0;
}
print "max_revnum_in_db: $max_revnum_in_db\n" if $debug > 3;

# debug - probably disabled below
my $this_rev_nums_only;
$this_rev_nums_only = {
     1907 => 1, # A /branches/REL_0_0_7
#     9619 => 1, # D /branhces/debian
#    22647 => 1, # D /branches/autogcc
#    22648 => 1, # D /tags/autogcc-22642
#
#     1853 => 1, # A /branches/PERL6
#    23145 => 1, # D /branches/PERL6
};
$this_rev_nums_only = undef; # disable debug

if ( defined $this_rev_nums_only ) {
    print "Using only defined rev numbers.\n";
    my $new_revs = [];
    foreach my $rd ( @$revs ) {
        if ( defined $this_rev_nums_only && $this_rev_nums_only->{ $rd->{revision} } ) {
            push @$new_revs, $rd;
        }
    }
    $revs = $new_revs;
}


# inserting authors into rep_author table
my $authors = $db->get_rep_authors( $rep_id );
foreach my $rd ( @$revs ) {
    next if $rd->{revision} <= $max_revnum_in_db;
    my $author = $rd->{'author'}; # can be null, will create row in rep_author
    if ( exists $authors->{$author} ) {
        print "author '$author' exists in DB, rep_author_id=" . $authors->{$author}->{rep_author_id} . "\n" if $debug > 3;
    }
    else {
        print "author '$author' not exists in DB, inserting\n" if $debug > 1;
        my $rep_author_id = $db->insert_rep_author( $rep_id, $author );
        # temporary data, probably different keys than in data loaded from DB
        $authors->{$author} = {
            rep_author_id => $rep_author_id,
            rep_login => $author,
        }
    }
}
$db->commit or $db->db_error( "Commiting authors failed." );
$authors = $db->get_rep_authors( $rep_id );


# input:  /trunk/filepath/filename,      /braches/BRANCHNAME,            /tags/TAGNAME
# output: ( trunk/, filepath/filename ), ( braches/BRANCHNAME/, undef ), ( tags/TAGNAME/, undef )
sub split_rep_path {
    my ( $project_name, $path ) = @_;

    if ( my ( $base, $oth ) = $path =~ m{^/(trunk|branches/[^\/]+|tags/[^\/]+)\/?(.*?)$} ) {
        $base .= '/' unless substr($base,-1,1) eq '/';
        return ( $base, $oth );
    }
    return ( undef, undef );
}


sub svntime_to_dbtime {
    my ( $svn_time ) = @_;
    return $svn_time;
}


sub process_file {
    my ( $db, $sub_path, $info, $revision, $rep_path_id, $rev_id ) = @_;

    my $action = $info->{action};

    if ( $action eq 'A' || $action eq 'R' ) {
        $db->insert_rep_file( $sub_path, $rep_path_id, $revision );
    }
    elsif ( $action eq 'D' ) {
        $db->set_rep_file_deleted( $sub_path, $rep_path_id, $revision );
    }
    elsif ( $action eq 'M' ) {
        $db->set_rep_file_modified( $sub_path, $rep_path_id, $revision, $rev_id );
    }
    else {
        $@ = "Uknown file svn action '$action'.";
        return 0;
    }

    return 1;
}



foreach my $rd ( @$revs ) {
    next if $rd->{revision} <= $max_revnum_in_db;
    my $rev_num = $rd->{'revision'};
    # insert rev if needed
    my $rev_id = $db->get_rev_id( $rep_id, $rev_num );
    unless ( defined $rev_id ) {
        my $date_ts = svntime_to_dbtime( $rd->{date} );
        $db->log_rev_error( $rd, "Time parser error datestr '$rd->{date}'." ) unless defined $date_ts;
        my $rep_author_id = $authors->{ $rd->{'author'} }->{rep_author_id};
        $rev_id = $db->insert_rev(
            $rep_id,
            $rev_num,
            $rep_author_id,
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

        if ( $path eq '/' || $path eq '/tags' || $path eq '/branches' ) {
            carp "Skipping path '$path' (rev $rev_num, action $action).\n";
            next;
        }

        my $rep_layout_ok = 1;
        my ( $rep_path, $sub_path );

        if ( $conf_rep->{repository_default_layout} ) {
            ( $rep_path, $sub_path ) = split_rep_path( $project_name, $path );
            unless ( defined $rep_path ) {
                carp "Parsing path '$path' failed.";
                $rep_layout_ok = 0;
            }

        } else {
            $rep_path = '';
            $sub_path = $path;
            if ( substr($sub_path,0,1) eq '/' ) {
                $sub_path = substr(  $sub_path, 1 );
            }
            #croak "'$sub_path'\n";
        }


        if ( $rep_layout_ok ) {
            unless ( exists $rp_changes->{$rep_path} ) {
                $rp_changes->{$rep_path} = {
                    sub_paths => {},
                };

                # get or insert rep_path
                my $rep_path_id = $db->get_rep_path_id( $rep_id, $rep_path, $rev_num );
                unless ( defined $rep_path_id ) {
                    $rep_path_id = $db->insert_rep_path(
                        $rep_id, $rep_path, $rev_num
                    );
                }

                # insert rev_rep_path unless exists
                unless ( $db->exists_rev_rep_path( $rev_id, $rep_path_id ) ) {
                    $db->insert_rev_rep_path( $rev_id, $rep_path_id );
                }

                $rp_changes->{$rep_path}->{rep_path_id} = $rep_path_id;
            }

            # set deleted for $rep_path
            if ( $sub_path eq '' && $action eq 'D' ) {
                # delete rep_path
                $db->set_rep_path_deleted( $rep_id, $rep_path, $rev_num );
            }

            # store ref to path info
            $rp_changes->{$rep_path}->{sub_paths}->{$sub_path} = $rd->{'paths'}->{$path};
            print "rep_path: $rep_path, sub_path: $sub_path\n" if $debug > 4;
        }
    }

    #print dmp( $rp_changes );
    #$db->rollback; die;

    my @rp_keys = keys %$rp_changes;
    if ( scalar @rp_keys > 0 ) {
        foreach my $rep_path ( @rp_keys ) {
            my $rep_path_id = $rp_changes->{$rep_path}->{rep_path_id};
            #$db->commit or $db->db_error( "Commiting rev_num $rev_num failed." );

            my $sub_paths = $rp_changes->{$rep_path}->{sub_paths};
            foreach my $sub_path ( sort keys %$sub_paths ) {
                my $info = $sub_paths->{$sub_path};
                process_file( $db, $sub_path, $info, $rev_num, $rep_path_id, $rev_id ) or $db->log_rev_error( $rd, $@ );
            }
        }
    }

    $db->commit or $db->db_error( "Commiting all changes for $rev_num failed." );

    print "rev " . $rev_num . " done, ok\n" if $debug > 1;

    if ( $debug > 9 ) {
        print dmp($rd) if $debug > 9;
        print "rev: $rev_num";
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
}

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
