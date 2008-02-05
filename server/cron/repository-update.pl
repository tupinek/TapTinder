use DBI;
use strict;

use Carp qw(carp croak verbose);
use FindBin qw($RealBin);

use Data::Dumper;
use File::Spec::Functions;

use SVN::Log;

my $conf_fpath = catfile( $RealBin, '..', 'conf', 'dbconf.pl' );
my $conf = require $conf_fpath;
croak "Config loaded from '$conf_fpath' is empty.\n" unless $conf;

my $project_name = 'parrot';
my $conf_rep = $conf->{project}->{$project_name};

my $state_fn = catfile( $RealBin,'..', 'conf', $project_name . '-replog-state.pl' );
my $log_dump_fn = catfile( $RealBin, '..', 'conf', $project_name.'-replog-dump.pl' );

my $log_dump_refresh = $ARGV[0] || $conf_rep->{log_dump_refresh};
my $debug = $ARGV[1] || 0;

if ( 0 ) {
    my $dbh = DBI->connect(
        $conf->{db}->{dsn},
        $conf->{db}->{user},
        $conf->{db}->{password},
        { RaiseError => 1, AutoCommit => 0 }
    ) or die $DBI::errstr;


    my $sth = $dbh->prepare("SELECT client_id, user_id, created, last_login, ip, cpuarch, osname, archname, active  FROM client WHERE active=1");
    $sth->execute();

    while ( my @row = $sth->fetchrow_array ) {
        print join(' | ',@row) . "\n";
    }

    $dbh->commit;
    $dbh->disconnect;
}

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
if ( $state->{rep}->{log_dump_time} + $log_dump_refresh < time() ) {
    print "getting svn log for revisions $last_log_rev..HEAD online...\n";
    my $new_revs = SVN::Log::retrieve ($conf_rep->{repository}, $last_log_rev, 'HEAD');
    
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



foreach my $rd ( @$revs ) {
    my $found = 0;

    if ( $debug > 1 ) {
        print dmp($rd) if $debug > 4;
        print "rev:" . $rd->{'revision'};
        print ", autor: " . $rd->{'author'};
        print ", datum: " . $rd->{'date'};
        print "\n";
        my $msg = $rd->{'message'};
        print "msg:\n";
        $msg =~ s{\r}{}sg;
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