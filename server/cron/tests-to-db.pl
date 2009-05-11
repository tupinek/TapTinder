#!perl

use strict;
use warnings;
use Carp qw(carp croak verbose);
use FindBin qw($RealBin);

use Getopt::Long;
use Pod::Usage;

use Data::Dumper;
use File::Spec::Functions;
use Devel::StackTrace;

use Archive::Tar;
use Cwd;
use YAML::Syck;
use TAP::Parser;

use lib "$FindBin::Bin/../lib";
use TapTinder::DB;
use TapTinder::Utils::Conf qw(load_conf_multi);
use TapTinder::Utils::DB qw(get_connected_schema);

my $help = 0;
my $ver = 2;
my $save_extracted = 0;
my $first_archive_only = 0;
my $msjobp_cmd_id = undef;
my $options_ok = GetOptions(
    'help|h|?' => \$help,
    'verbosity|v=i' => \$ver,
    'save_extracted' => \$save_extracted,
    'first_archive_only' => \$first_archive_only,
    'msjobp_cmd_id=i' => \$msjobp_cmd_id,
);
pod2usage(1) if $help || !$options_ok;

my $conf = load_conf_multi( undef, 'db' );
croak "Configuration for database is empty.\n" unless $conf->{db};

my $schema = get_connected_schema( $conf->{db} );

my $plus_rows = [ qw/ msjobp_cmd_id file_path file_name rev_id rev_num rep_path_id /];
my $search_cond = {};
if ( defined $msjobp_cmd_id ) {
     $search_cond->{msjobp_cmd_id} = $msjobp_cmd_id;
}
my $search_attrs = {
    'select' => $plus_rows,
    'as'     => $plus_rows,
};
my $rs = $schema->resultset( 'NotLoadedTruns' )->search( $search_cond, $search_attrs );
unless ( $rs ) {
    croak "No files found\n";
}

my %summary_methods = map { $_ => $_ } qw(
  failed
  parse_errors
  passed
  planned
  skipped
  todo
  todo_passed
  wait
  exit
  total
  skip_all
);
$summary_methods{total}   = 'tests_run';
$summary_methods{planned} = 'tests_planned';

my %aggregator_summary_methods = map { $_ => $_ } qw(
  planned
  parse_errors
  failed
  skipped
  todo
  todo_passed
  passed
  wait
  exit
);


my %trest = (
    1 => 'not_seen',
    2 => 'failed',
    3 => 'todo',
    4 => 'skip',
    5 => 'bonus',
    6 => 'ok',
);


sub create_new_table_row {
    my ( $schema, $table_name, $rh_new_vals ) = @_;

    my $rs = $schema->resultset($table_name)->create($rh_new_vals);
    return undef unless $rs;
    my $new_id = $rs->get_column($table_name.'_id');
    return $new_id;
}


sub trun_create {
    my ( $schema, $trun_status_id, $msjobp_cmd_id ) = @_;
    return create_new_table_row( $schema, 'trun', {
        msjobp_cmd_id => $msjobp_cmd_id,
        trun_status_id => $trun_status_id,
    } );
}


sub trun_update {
    my ( $schema, $trun_id, $rh_new_values ) = @_;

    my $trun_rs = $schema->resultset('trun')->search( {
        trun_id => $trun_id,
    } );

    my $ret_val = $trun_rs->update( $rh_new_values );
    return undef unless $ret_val;
    return 1;
}


sub rep_file_find {
    my ( $schema, $rep_path_id, $sub_path, $rev_num ) = @_;

    my $rs = $schema->resultset('rep_file')->search( {
        rep_path_id => $rep_path_id,
        sub_path => $sub_path,
        rev_num_from => { '<=', $rev_num },
        -or => [
            rev_num_to => { 'is', undef },
            rev_num_to => { '>=', $rev_num },
        ],
    } );
    my $row = $rs->next;
    my $row_data = { $row->get_columns };
    my $rep_file_id = $row_data->{rep_file_id};
    return $rep_file_id;
}


sub create_rep_test {
    my ( $schema, $rep_file_id, $number, $name ) = @_;

    return create_new_table_row( $schema, 'rep_test',  {
        rep_file_id => $rep_file_id,
        number => $number,
        name => $name,
    } );
}


sub my_find_or_create_rep_test {
    my ( $schema, $rep_file_id, $number, $name ) = @_;

    my $rs = $schema->resultset('rep_test')->search( {
        rep_file_id => $rep_file_id,
        number => $number
    } );


    my $row = undef;
    my $has_another_name = 0;
    while ( my $new_row = $rs->next ) {
        $row = $new_row;
        if ( $row->name eq $name ) {
            $has_another_name = 1;
            last;
        }
    }

    # Not found.
    return create_rep_test( $schema, $rep_file_id, $number, $name ) unless defined $row;

    # Found and has the same name.
    return $row->rep_test_id if $has_another_name;

    # Found, has another name, but has_another_name already set.
    return $row->rep_test_id if $row->has_another_name;

    # Has another name and has_another_name == 1. Update rep_test.
    # set has_another_name=1.
    my $new_vals = { has_another_name => 1 };

    # Set new name if previous is empty.
    $new_vals->{name} = $name if $row->name =~ /^\s*$/;

    my $ret_val = $row->update( $new_vals );
    return undef unless $ret_val;

    return $row->rep_test_id;
}


while ( my $row = $rs->next ) {
    my $rdata = { $row->get_columns };
    print Dumper( $rdata ) if $ver >= 4;
    my $fpath = catfile( $rdata->{file_path}, $rdata->{file_name} );
    my $msjobp_cmd_id = $rdata->{msjobp_cmd_id};
    my $rep_path_id = $rdata->{rep_path_id};
    my $rev_num = $rdata->{rev_num};
    print "Archive file: '$fpath':\n" if $ver >= 1;

    my $tar = Archive::Tar->new();

    my $work_dir = catdir( $FindBin::Bin, '..', 'temp', 'tar', $rdata->{file_name}.'-dir'  );
    $tar->setcwd( $work_dir );

    my @files = $tar->read( $fpath, undef );
    $tar->extract() if $save_extracted;

    my $trun_status_id = 1;
    my $trun_id = trun_create( $schema, $trun_status_id, $msjobp_cmd_id );

    my %file_names = ();
    foreach my $file_num ( 0..$#files ) {
        my $file = $files[ $file_num ];
        $file_names{ $file->full_path } = $file_num;
    }
    print Dumper( \%file_names ) if $ver >= 5;

    my $file_num = $file_names{ 'meta.yml' };
    my $meta_yaml = $files[$file_num]->get_content;
    my $meta = Load( $meta_yaml );

    my %all_aggr = ( 1 => 0, 2 => 0, 3 => 0, 4 => 0, 5 => 0, 6 => 0 );
    my $all_my_parse_errors = 0;
    my $all_my_planned = 0;
    foreach my $tap_file_path ( @{ $meta->{file_order} } ) {
        carp "Path '$tap_file_path' not found." unless exists $file_names{ $tap_file_path };
        my $file_num = $file_names{ $tap_file_path };
        my $file = $files[ $file_num ];
        print Dumper( \$file ) if $ver>= 5;
        my $tap_source = $file->{data};

        print "Test file: '$tap_file_path'\n" if $ver >= 3;
        my $rep_file_id = rep_file_find( $schema, $rep_path_id, $tap_file_path, $rev_num );
        unless ( $rep_file_id ) {
            carp "Can't find rep_file_id for rep_path_id:$rep_path_id, sub_path:'$tap_file_path', rev_num:$rev_num\n";
            next;
        }
        print "  rep_file_id: $rep_file_id\n" if $ver >= 5;

        my $tap_parser = TAP::Parser->new( { tap => $tap_source } );
        my $prev_num = 0;
        my $actual_num = 0;
        my $trest_id = 0;

        my %aggr = ( 1 => 0, 2 => 0, 3 => 0, 4 => 0, 5 => 0, 6 => 0 );
        my $my_parse_errors = 0;
        my $my_planned = undef;
        while ( my $result = $tap_parser->next ) {
            print $result->as_string . "\n" if $ver >= 5;
            if ( $result->is_plan ) {
                unless ( defined $my_planned ) {
                    $my_planned = $result->tests_planned;
                    print "  my plan: " . $my_planned . "\n\n" if $ver >= 4;
                }

            } elsif ( $result->is_test ) {
                $actual_num = $result->number;

                # error, skip this
                if ( $actual_num < $prev_num + 1 ) {
                    $my_parse_errors++;
                    print "    my parse error $my_parse_errors (test num $actual_num): " . $result->as_string . "\n" if $ver >= 1;

                } elsif ( defined $my_planned && $actual_num > $my_planned ) {
                    $my_parse_errors++;
                    print "    my parse error $my_parse_errors (test num $actual_num): " . $result->as_string . "\n" if $ver >= 1;

                } else {
                    if ( $actual_num > $prev_num + 1 ) {
                        $trest_id = 1; # not seen
                        foreach my $not_seen_num ( ($prev_num+1)..($actual_num-1) ) {
                            $aggr{ $trest_id }++;
                            # do not count not seen as parse errors
                            print "  " . $not_seen_num . " $trest{$trest_id}:\n" if $ver >= 3;
                        }
                    }
                    my $directive = $result->directive;
                    if ( $directive eq 'TODO' ) {
                        if ( ! $result->is_actual_ok ) {
                            $trest_id = 3; # todo
                        } else {
                            $trest_id = 5; # bonus
                        }

                    } elsif ( $directive eq 'SKIP' ) {
                        $trest_id = 4; # skip

                    } else {
                        if ( $directive ) {
                            carp "Unknown directive '$directive'\n";
                        }
                        if ( $result->is_actual_ok ) {
                            $trest_id = 6; # ok
                        } else {
                            $trest_id = 2; # failed
                        }
                    }

                    print "  " . $actual_num . " $trest{$trest_id}: " . $result->as_string . "\n" if $ver >= 4;
                    my $test_name = $result->description;
                    $test_name =~ s{^\s*-\s*}{};
                    $aggr{ $trest_id }++;

                    my $rep_test_id = my_find_or_create_rep_test(
                        $schema,
                        $rep_file_id,
                        $actual_num,  # $number,
                        $test_name    # $name
                    );
                    unless ( $rep_test_id ) {
                        carp "Can't find or create rep_test for rep_file_id:$rep_file_id, number:'$actual_num', name:'$test_name'\n";
                        next;
                    }
                    print "    rep_test_id: $rep_test_id\n" if $ver >= 5;


                    # Do not save results with ok status.
                    if ( $trest_id == 6 ) {
                        print "    ttest_id: not saved\n" if $ver >= 5;

                    } else {
                        my $ttest_id = create_new_table_row( $schema, 'ttest',  {
                            trun_id => $trun_id,
                            rep_test_id => $rep_test_id,
                            trest_id => $trest_id,
                        } );
                        unless ( $rep_test_id ) {
                            carp "Can't create ttest for trun_id:$trun_id, rep_test_id:$rep_test_id, trest_id:$trest_id\n";
                            next;
                        }
                        print "    ttest_id: $ttest_id\n" if $ver >= 5;
                    }

                    $prev_num = $actual_num;
                }
            }
        } # while ... $tap_parser->next

        # last checks
        my $missing_num = $my_planned - $actual_num;
        if ( $missing_num > 0 ) {
            $trest_id = 1; # not seen
            foreach my $not_seen_num ( ($actual_num+1)..$my_planned ) {
                $aggr{ $trest_id }++;
                # do not count not seen as parse errors
                print "  " . $not_seen_num . " $trest{$trest_id}:\n" if $ver >= 3;
            }
        }

        # Number of 'not seen' and 'failed' should be zero.
        my $all_passed = ( $aggr{1} == 0 && $aggr{2} == 0 );
        # ToDo
        my $tskipall_msg_id = undef;
        # ToDo
        my $hang = undef;

        # Insert tfile.
        my $tfile_id = create_new_table_row( $schema, 'tfile',  {
            trun_id => $trun_id,
            rep_file_id => $rep_file_id,
            all_passed => $all_passed,
            tskipall_msg_id => $tskipall_msg_id,
            hang => $hang,
        } );
        unless ( $tfile_id ) {
            carp "Can't create tfile for trun_id:$trun_id, rep_file_id:$rep_file_id, all_passed:$all_passed, tskipall_msg_id: $tskipall_msg_id, hang: $hang\n";
        }
        print "  tfile_id: $tfile_id\n" if $ver >= 5;


        # Aggregate.
        foreach my $trest_id ( 1..6 ) {
            $all_aggr{$trest_id} += $aggr{$trest_id};
            # not seen, failed
        }


        if ( $ver >= 3 ) {
            print "\n";

            print "  my my_planned: $my_planned\n";
            print "  my my_parse_errors: $my_parse_errors\n";
            foreach my $trest_id ( 1..6 ) {
                print "  my $trest{$trest_id}: $aggr{$trest_id}\n";
            }
            print "\n";

            while ( my ( $summary, $method ) = each %summary_methods ) {
                if ( my $count = $tap_parser->$method() ) {
                    print "  $summary: $count\n";
                }
            }
            if ( scalar $tap_parser->parse_errors ) {
                print "  parse_errors:\n";
                my @errors = $tap_parser->parse_errors;
                foreach my $err ( @errors ) {
                    print "    $err\n";
                }
            }
            print "\n";
        }

        $all_my_planned += $my_planned;
        $all_my_parse_errors += $my_parse_errors;

    }

    if ( $ver >= 2 ) {
        print "my all_my_planned: $all_my_planned\n";
        print "my all_my_parse_errors: $all_my_parse_errors\n";
        foreach my $trest_id ( 1..6 ) {
            print "my all $trest{$trest_id}: $all_aggr{$trest_id}\n";
        }
        print "\n";
    }

    my $new_trun_values = {};
    $new_trun_values = {
        trun_status_id => 2, # ok
        not_seen    => $all_aggr{1},
        failed      => $all_aggr{2},
        todo        => $all_aggr{3},
        skip        => $all_aggr{4},
        bonus       => $all_aggr{5},
        ok          => $all_aggr{6},

    };
    my $ret_val = trun_update( $schema, $trun_id, $new_trun_values );

    last if $first_archive_only;
}


=head1 NAME

tests-to-db.pl - Extract data from Test::Harness:Archive and save to DB.

=head1 SYNOPSIS

perl tests-to-db.pl [options]

 Options:
   --help
   --debug
   --save_extracted
   --first_archive_only .. Process only first test harness archive file found.
   --msjobp_cmd_id=$ID .. Process only archive for $ID job part command id.

=head1 DESCRIPTION

B<This program> will save ...

=cut
