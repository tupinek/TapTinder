use strict;
use warnings;

use Carp qw(carp croak verbose);
use FindBin qw($RealBin);

use DBI;
use File::stat;
use File::Spec::Functions;

use Data::Dumper;


my $conf_fpath = catfile( $RealBin, '..', 'conf', 'dbconf.pl' );
my $conf = require $conf_fpath;
croak "Config loaded from '$conf_fpath' is empty.\n" unless $conf;

my $project_name = 'parrot';
my $conf_rep = $conf->{project}->{$project_name};

my $results_dir = $ARGV[0] || './../../test-smoke';
my $debug = $ARGV[1] || 10;

print "Debug level: $debug\n" if $debug;
print "\n" if $debug;

my $dbh;
my $sth_cache;

$dbh = DBI->connect(
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

sub dump_get {
    my ( $sub_name, $ra_args, $results ) = @_;
    print "function $sub_name, input (" . join(', ',@$ra_args) . "), result " . dmp($results);
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


sub load_tap_data {
    my ( $fp, $use_full_yaml ) = @_;
    $use_full_yaml = 1 unless defined $use_full_yaml;

    my $data;
    eval {
        #use YAML::Tiny;
        #my $yaml = YAML::Tiny->read( $fp ); 
        #$data = $yaml->[0];
        use YAML::Syck;
        $data = LoadFile( $fp );
        delete $data->{results};
    };

    if ( $@ ) {
        carp $@;
        print "Using YAML ...\n";
        if ( $use_full_yaml ) {
            eval {
                use YAML;
                my ( $rh, $ra, $sc ) = YAML::LoadFile( $fp );
                $data = $rh;
            };
            if ( $@ ) {
                carp $@;
                return undef;
            }
        }
        else {
            return undef;
        }
    }
    return $data;
}


sub dump_header {
    my ( $data ) = @_;
    print "archname: " . $data->{pconfig}->{archname} . "\n";
    print "revision: " . $data->{pconfig}->{revision} . "\n";
    #print Dumper( $data );
}

        
my $mtimes = {};
my $glob_pattern = $results_dir.'/parrot-smoke-*.yaml';
foreach my $fp ( glob($glob_pattern) ) {
    my $st = stat $fp;
    $mtimes->{ $st->mtime } = $fp;
}
if ( scalar keys %$mtimes <= 0 ) {
    print "Not found any file with $glob_pattern. First param is path to directory with results.\n";
    exit;
}


my $last_fn;
my $loaded_revs = {};
my $num = 0;
foreach my $mtime ( reverse sort keys %$mtimes ) {
    $num++;
    my $fn = $mtimes->{$mtime};
    my @lt = localtime($mtime);
    my $time = sprintf("%04d-%02d-%02d %02d-%02d-%02d",($lt[5] + 1900),($lt[4] + 1),$lt[3],$lt[2], $lt[1], $lt[0] );
    print "file: $fn\n";
    print "mtime: $time\n";
    $last_fn = $fn;

    my $data = load_tap_data($fn,!$debug);
    if ( defined $data ) {
        dump_header( $data );
        my $rev = $data->{pconfig}->{revision};
        my $arch = $data->{pconfig}->{archname};
        if ( defined $rev && defined $arch ) {
            unless ( exists $loaded_revs->{$rev}->{$arch} ) {
                $loaded_revs->{$rev}->{$arch} = {
                    num => 0,
                    files => [],
                };
            }
            $loaded_revs->{$rev}->{$arch}->{num}++;
            push @{$loaded_revs->{$rev}->{$arch}->{files}}, $fn;
            #print Dumper($loaded_revs);
        } else {
            print "Results file error. No archname or revisions in pconfig.\n";
        }
    }
    print "\n\n";
    last if $num >= 3 && $debug;
}
print "\n";

print "Stats:\n";
my $arch_stat = {};
foreach my $rev ( sort keys %$loaded_revs ) {
    print "  $rev: ";
    my $archs = $loaded_revs->{$rev};
    my $arch_num = 0;
    foreach my $arch ( sort keys %$archs ) {
        $arch_num++;
        print ", " if $arch_num > 1;
        print $arch;
        print "(".$archs->{$arch}->{num}.")" if $archs->{$arch}->{num} > 1;
        $arch_stat->{$arch} = {} unless exists $arch_stat->{$arch};
        $arch_stat->{$arch}->{$rev} = 0 unless defined $arch_stat->{$arch}->{$rev};
        $arch_stat->{$arch}->{$rev}++;
    }
    print "\n";
}
print "\n";


foreach my $arch ( sort keys %$arch_stat ) {
    my $unique_revs = scalar keys %{$arch_stat->{$arch}};
    my $all_tests = 0;
    foreach my $rev ( keys %{$arch_stat->{$arch}} ) {
        $all_tests += $arch_stat->{$arch}->{$rev} 
    }
    print "  $arch : $unique_revs ($all_tests)\n";
}

$dbh->commit or db_error( $dbh, "End commit failed." );
$dbh->disconnect;
