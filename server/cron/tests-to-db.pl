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
use TAP::Parser::Aggregator;

use lib "$FindBin::Bin/../lib";
use TapTinder::DB;
use TapTinder::Utils::Conf qw(load_conf_multi);
use TapTinder::Utils::DB qw(get_connected_schema);

my $help = 0;
my $debug = 0;
my $save_extracted = 0;
my $first_archive_only = 0;
my $options_ok = GetOptions(
    'help|h|?' => \$help,
    'debug|d' => \$debug,
    'save_extracted' => \$save_extracted,
    'first_archive_only' => \$first_archive_only,
);
pod2usage(1) if $help || !$options_ok;

my $conf = load_conf_multi( undef, 'db' );
croak "Configuration for database is empty.\n" unless $conf->{db};

my $schema = get_connected_schema( $conf->{db} );

my $plus_rows = [ qw/ msjobp_cmd_id file_path file_name /];
my $search_conf = {
    'select' => $plus_rows,
    'as'     => $plus_rows,
};
my $rs = $schema->resultset( 'NotLoadedTruns' )->search( {}, $search_conf );

my %summary_methods = map { $_ => $_ } qw(
  failed
  parse_errors
  passed
  skipped
  todo
  todo_passed
  total
  wait
  exit
  planned
  skip_all
  parse_errors
);
$summary_methods{total}   = 'tests_run';
$summary_methods{planned} = 'tests_planned';


my %trest = (
    1 => 'not seen',
    2 => 'failed',
    3 => 'unknown',
    4 => 'todo',
    5 => 'bonus',
    6 => 'skip',
    7 => 'ok',
);

while ( my $row = $rs->next ) {
    my $rdata = { $row->get_columns };
    #print Dumper( $row_data );
    my $fpath = catfile( $rdata->{file_path}, $rdata->{file_name} );
    print "archive file: '$fpath'\n\n" if $debug;

    my $tar = Archive::Tar->new();

    my $work_dir = catdir( $FindBin::Bin, '..', 'temp', 'tar', $rdata->{file_name}.'-dir'  );
    $tar->setcwd( $work_dir );

    my @files = $tar->read( $fpath, undef );
    $tar->extract() if $save_extracted;

    my %file_names = ();
    foreach my $file_num ( 0..$#files ) {
        my $file = $files[ $file_num ];
        $file_names{ $file->full_path } = $file_num;
    }
    #print Dumper( \%file_names ) if $debug;

    my $file_num = $file_names{ 'meta.yml' };
    my $meta_yaml = $files[$file_num]->get_content;
    my $meta = Load( $meta_yaml );

    my $aggregator = TAP::Parser::Aggregator->new();
    foreach my $tap_file_path ( @{ $meta->{file_order} } ) {
        carp "$tap_file_path not foun." unless exists $file_names{ $tap_file_path };
        my $file_num = $file_names{ $tap_file_path };
        my $file = $files[ $file_num ];
        #print Dumper( \$file ) if $debug;
        my $tap_source = $file->{data};

        print "test file: '$tap_file_path'\n" if $debug;
        my $tap_parser = TAP::Parser->new( { tap => $tap_source } );
        my $prev_num = 0;
        my $actual_num = 0;
        my $trest_id = 0;
        my $my_parse_errors = 0;
        my $planned = undef;
        while ( my $result = $tap_parser->next ) {
            #print $result->as_string . "\n" if $debug;
            if ( $result->is_plan ) {
                $planned = $result->tests_planned;
                print "  plan: " . $planned . "\n\n";

            } elsif ( $result->is_test ) {
                $actual_num = $result->number;

                # error, skip this
                if ( $actual_num < $prev_num + 1 ) {
                    $my_parse_errors++;
                    print "    my parse error $my_parse_errors (test num $actual_num): " . $result->as_string . "\n" if $debug;

                } elsif ( defined $planned && $actual_num > $planned ) {
                    $my_parse_errors++;
                    print "    my parse error $my_parse_errors (test num $actual_num): " . $result->as_string . "\n" if $debug;

                } else {
                    if ( $actual_num > $prev_num + 1 ) {
                        $trest_id = 1; # not seen
                        foreach my $not_seen_num ( ($prev_num+1)..($actual_num-1) ) {
                            # do not count not seen as parse errors
                            print "  " . $not_seen_num . " $trest{$trest_id}:\n";
                        }
                    }
                    my $directive = $result->directive;
                    if ( $directive eq 'TODO' ) {
                        if ( ! $result->is_actual_ok ) {
                            $trest_id = 4; # todo
                        } else {
                            $trest_id = 5; # bonus
                        }

                    } elsif ( $directive eq 'SKIP' ) {
                        $trest_id = 6; # skip

                    } elsif ( $directive ) {
                        $trest_id = 3; # unknown

                    } else {
                        if ( $result->is_actual_ok ) {
                            $trest_id = 7; # ok
                        } else {
                            $trest_id = 2; # failed
                        }
                    }

                    print "  " . $actual_num . " $trest{$trest_id}: " . $result->as_string . "\n" if $debug;
                    my $description = $result->description;
                    $prev_num = $actual_num;
                }
            }
        }
        my $missing_num = $planned - $actual_num;
        if ( $missing_num > 0 ) {
            $trest_id = 1; # not seen
            foreach my $not_seen_num ( $actual_num..$planned ) {
                # do not count not seen as parse errors
                print "  " . $not_seen_num . " $trest{$trest_id}:\n";
            }
        }


        if ( $debug ) {
            print "\n";
            print "  my my_parse_errors: $my_parse_errors\n";
            print "  my_parse_errors: " . scalar $tap_parser->parse_errors . "\n";
            my @errors = $tap_parser->parse_errors;
            foreach my $err ( @errors ) {
                print "    $err\n";
            }

            while ( my ( $summary, $method ) = each %summary_methods ) {
                if ( my $count = $tap_parser->$method() ) {
                    print "  $summary: $count\n";
                }
            }
            print "\n";
        }

        $aggregator->add( $tap_file_path, $tap_parser );
    }
    print "\n" if $debug;

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

=head1 DESCRIPTION

B<This program> will save ...

=cut
