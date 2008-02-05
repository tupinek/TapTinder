use DBI;
use strict;

use Carp qw(carp croak verbose);
use FindBin qw($RealBin);

use Data::Dumper;
use File::Spec::Functions;

use SVN::Log;
use Time::Local;

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
my $dbh = DBI->connect(
    $conf->{db}->{dsn},
    $conf->{db}->{user},
    $conf->{db}->{password},
    { RaiseError => 1, AutoCommit => 0 }
) or die $DBI::errstr;

sub dmp {
    my $dd = Data::Dumper->new( [ @_ ] );
    $dd->Indent(1);
    $dd->Terse(1);
    $dd->Purity(1);
    $dd->Deepcopy(1);
    $dd->Deparse(1);
    return $dd->Dump . "\n";
}


my $state;

sub save_state {
    open SFH, ">", $state_fn or croak;
    print SFH dmp($state);
    close SFH;
}

sub fatal_err {
    my ( $msg ) = @_;
    print $msg;
    save_state();
    exit;
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


sub fatal_error {
    my ( $dbh, $rd, $msg ) = @_;
    
    $dbh->rollback;
    $dbh->disconnect;
    croak 
        $msg
        . "\n"
        . "For revison " . $rd->{revisons} . ".\n"
    ;
}


#my $sth = $dbh->prepare("INSERT INTO rev, bar FROM table WHERE baz=?");

foreach my $rd ( @$revs ) {
    my $found = 0;
    
    # 2001-09-15T20:51:23.000000Z
    my $date_ts = 0;
    if ( my ($year,$mon,$mday,$hour,$min,$sec) = $rd->{date} =~
     /^(\d{4})\-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})\.\d+Z$/ ) {
        $date_ts = timegm($sec,$min,$hour,$mday,$mon,$year);
    }
    else {
        fatal_error( $dbh, $rd, "Time parser error date str '".$rd->{date}."'." );
    }

    if ( $debug > 1 ) {
        print dmp($rd) if $debug > 4;
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

$dbh->commit;
$dbh->disconnect;
