use strict;
use warnings;

use Carp qw(carp croak verbose);
use FindBin qw($RealBin);

use Data::Dumper;
use File::stat;
use File::Spec::Functions;
use File::Basename;

use lib '../lib';
use TapTinder::DB;

my $conf_fpath = catfile( $RealBin, '..', 'conf', 'dbconf.pl' );
my $conf = require $conf_fpath;
croak "Config loaded from '$conf_fpath' is empty.\n" unless $conf;

my $project_name = 'parrot';
my $conf_rep = $conf->{project}->{$project_name};

my $results_dir = $ARGV[0] || './../../../temp/test-smoke';
my $debug = $ARGV[1] || 0;

print "Debug level: $debug\n" if $debug;
print "Results path: '$results_dir'\n";
print "\n" if $debug;


my $db = TapTinder::DB->new();
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
    #delete $data->{results};
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
    my ( $machine_id, $archname, $cc, $cpuarch, $osname ) = @_;
    print "Valid machine conf.\n" if $debug;
    return 1;
}


# logic for test (detail) result to tresult.tresult_id
sub get_test_result_id {
    my ( $test, $trun_id, $rep_file_id, $test_num ) = @_;

    # 0 .. not seen (not ok) -- empty result info
    return 0 unless defined $test;
    
    # 5 ... skip -- type == 'skip'
    return 5 if $test->{type} eq 'skip';

    if ( $test->{actual_ok} == 1 ) {
        # 4 .. bonus (ok) -- actual_ok == 1 && type == 'todo'
        return 4 if $test->{type} eq 'todo';

        # unknown with actual_ok == 1 -> ok
        if ( $test->{type} ne '' ) {
            print
                "Unknown result state: actual_ok=1, type='" . $test->{type} . "'"
                . " trun_id:$trun_id, rep_file_id:$rep_file_id, test_num:$test_num.\n"
            ;
        }

        # 6 .. ok (ok) -- actual_ok == 1 && type != 'todo' && type != 'skip' ( other types, reason, ... ignored )
        return 6;
    }
    
    # 3 .. todo (not ok || ok) -- actual_ok == 0 && type == 'todo'
    return 3 if $test->{type} eq 'todo';

    # 1 .. failed (not ok) -- actual_ok == 0 && type == ''
    return 1 if $test->{type} eq '';
    
    # 2 .. unknown (not ok) -- actual_ok == 0 && type != 'todo' && type != 'skip'
    return 2;
}


sub process_test_raw_results {
    my ( $db, $stats, $trun_id, $rev_num, $rep_path_id, $all_results ) = @_;

    my $ret;
    TEST_RESULT: foreach my $res_num ( 0..$#$all_results ) {
        my $result = $all_results->[ $res_num ];
        #print dmp( $result ) if $debug > 5;

        my $test_details = $result->{details};
        # skiping files withnout details
        # probably not exist in repository, e.g. parrot rev: 26769 test_file: t/codingstd/cppcomments.t
        unless ( defined $test_details ) {
            print "Details for test_file '" . $result->{test_file} . "' not found.";
            next TEST_RESULT;
        }

        my $file_path = $result->{test_file};
        my $rep_file_id = $db->get_rep_file_id( 
            $file_path, # $sub_path
            $rep_path_id,
            $rev_num
        );
        unless ( defined $rep_file_id ) {
            carp( "Rep file not found for ( $file_path, $rep_path_id, $rev_num )." );
            return 0;
        }
        
        my $all_passed = ( $result->{max} == $result->{seen} && $result->{max} == $result->{ok} );
        my $skip_all_msg = $result->{skip_all};
        my $hang = 0;

        $ret = $db->insert_tfile( $trun_id, $rep_file_id, $all_passed, $skip_all_msg, $hang );
        return 0 unless defined $ret;

        foreach my $test_num ( 0..$#$test_details ) {
            my $test = $test_details->[ $test_num ];
            my $tresult_id = get_test_result_id( $test, $trun_id, $rep_file_id, $test_num );
            $stats->[ $tresult_id ]++;

            if ( 0 && $tresult_id != 6 ) {
                print "test name: '" . $test->{name} . "', tresult_id: $tresult_id\n";
                print dmp( $test );
                print "\n";
            }

            # insert rep_test
            my $rep_test_id = $db->prepare_and_get_rep_test_id( $rep_file_id, $test_num, $test->{name} );
            return 0 unless $rep_test_id;

            # not insert ok test results
            if ( $tresult_id != 6 ) {
                $ret = $db->insert_ttest( $trun_id, $rep_test_id, $tresult_id );
                return 0 unless $ret;
            }
                
            #return 0; # debug - roolback
        }
    }

    return 1;
}


sub process_test_results {
    my ( $db, $data, $fn ) = @_;

    my $machine_id = 
        $data->{conf}->{machine_id}
        || $data->{conf}->{client_id}
    ;

    my $rev_num = $data->{pconfig}->{revision};

    # TODO
    # $data->{duration}

    # TODO
    my $is_valid_user = is_valid_user( 
        $machine_id,
        $data->{pconfig}->{archname},
        $data->{pconfig}->{cpuarch},
        $data->{pconfig}->{osname},
    );
    $is_valid_user || return 0;

    my $rep_id = $db->get_rep_id( $data->{conf}->{repository} );
    return 0 unless $rep_id;
    my $rev_id = $db->get_rev_id( $rep_id, $rev_num );
    return 0 unless $rev_id;
    my $rep_path_id = $db->get_rep_path_id( $rep_id, $data->{conf}->{repository_path}, $rev_num );
    return 0 unless $rep_path_id;

    my @build_conf_params = (
        $data->{pconfig}->{cc},
        $data->{pconfig}->{DEVEL},
        $data->{pconfig}->{optimize}
    );
    my @trun_conf_params = (
        $data->{harness_args},
    );

    my $build_conf_id = $db->get_or_insert_build_conf( @build_conf_params );
    return 0 unless defined $build_conf_id;

    # TODO
    my $start_time = undef;
    my $build_duration = undef;
    my $build_id = $db->get_or_insert_build( 
        $rep_path_id, $rev_id, $machine_id, $build_conf_id, $start_time,
        $build_duration
    );
    return 0 unless defined $build_id;

    my $trun_conf_hash = $db->str_args_md5( @trun_conf_params );
    my $trun_conf_id = $db->get_trun_conf_id( $trun_conf_hash );
    unless ( defined $trun_conf_id ) {
        $trun_conf_id = $db->insert_trun_conf( $trun_conf_hash, @trun_conf_params );
        return 0 unless $trun_conf_id;

    } else {
        my $trun_id = $db->get_max_trun_id( $build_id, $trun_conf_id );
        if ( $trun_id ) {
            print "trun for $build_id, $trun_conf_id already found in DB.";
            return 0;
        }
    }

    my $trun_id = $db->insert_trun_base(
        $build_id, $trun_conf_id
    );
    return 0 unless defined $trun_id;
    print "trun_id: $trun_id\n";

    my $stats = [];
    my $results = $data->{results};
    my $ret = process_test_raw_results( $db, $stats, $trun_id, $rev_num, $rep_path_id, $results );
    return 0 unless $ret;
    
    return $db->update_trun_stats( $trun_id, $stats );
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

    my $data = load_tap_data( $fn, 1 );
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
    if ( $num >= 1 && $debug ) {
        print "Debug forced end after $num runs.\n";
        last;
    }
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
