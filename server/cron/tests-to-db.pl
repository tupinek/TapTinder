use strict;
use warnings;

use Carp qw(carp croak verbose);
use FindBin qw($RealBin);

use Data::Dumper;
use File::stat;
use File::Spec::Functions;
use File::Basename;

use lib '../lib';
use TapTin::DB;

my $conf_fpath = catfile( $RealBin, '..', 'conf', 'dbconf.pl' );
my $conf = require $conf_fpath;
croak "Config loaded from '$conf_fpath' is empty.\n" unless $conf;

my $project_name = 'parrot';
my $conf_rep = $conf->{project}->{$project_name};

my $results_dir = $ARGV[0] || './../../test-smoke';
my $debug = $ARGV[1] || 10;

print "Debug level: $debug\n" if $debug;
print "Results path: '$results_dir'\n";
print "\n" if $debug;


my $db = TapTin::DB->new();
$db->debug( $debug );
$db->connect( $conf->{db} );


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


# TODO  
sub is_valid_user {
    my ( $client_id, $archname, $cc, $cpuarch, $osname ) = @_;
    print "Valid client conf.\n";
    return 1;
}


sub process_test_results {
    my ( $db, $data, $fn ) = @_;

    my $client_id = $data->{conf}->{client_id};

    my $rev_num = $data->{pconfig}->{revision};

    # TODO
    # $data->{duration}

    # TODO
    my $is_valid_user = is_valid_user( 
        $client_id,
        $data->{pconfig}->{archname},
        $data->{pconfig}->{cpuarch},
        $data->{pconfig}->{osname},
    );
    $is_valid_user || return 0;

    
    my $conf_id = $db->get_or_insert_conf(
        $data->{pconfig}->{cc},
        $data->{harness_args},
        $data->{pconfig}->{DEVEL},
        $data->{pconfig}->{optimize}
    );


    my $rep_id = $db->get_rep_id( $data->{conf}->{repository} );
    return 0 unless $rep_id;
    my $rev_id = $db->get_rev_id( $rep_id, $rev_num );
    return 0 unless $rev_id;
    my $rep_path_id = $db->get_rep_path_id( $rep_id, $data->{conf}->{repository_path} );
    return 0 unless $rep_path_id;

    my $trun_id = $db->insert_trun_base(
        $rev_id, $rep_path_id, $client_id, $conf_id
    );
    print "trun_id: $trun_id\n";

    return 1;
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
    my $fn_basename = basename( $fn );
    my @lt = localtime($mtime);
    my $time = sprintf("%04d-%02d-%02d %02d-%02d-%02d",($lt[5] + 1900),($lt[4] + 1),$lt[3],$lt[2], $lt[1], $lt[0] );
    print "file: $fn_basename\n";
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
            my $ret = process_test_results( $db, $data, $fn_basename );
            if ( $ret ) {
                $db->commit();
            } else {
                $db->rollback();
            }
            $loaded_revs->{$rev}->{$arch}->{num}++;
            push @{$loaded_revs->{$rev}->{$arch}->{files}}, $fn;
            #print Dumper($loaded_revs);
        } else {
            print "Results file error. No archname or revisions in pconfig.\n";
        }
    }
    print "\n\n";
    last if $num >= 1 && $debug;
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

$db->commit or $db->db_error( "End commit failed." );
$db->disconnect;
