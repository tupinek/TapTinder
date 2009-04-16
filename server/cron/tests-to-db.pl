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
my $options_ok = GetOptions(
    'help|h|?' => \$help,
    'debug' => \$debug,
    'save_extracted' => \$save_extracted,
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


while ( my $row = $rs->next ) {
    my $rdata = { $row->get_columns };
    #print Dumper( $row_data );
    my $fpath = catfile( $rdata->{file_path}, $rdata->{file_name} );
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

        my $tap_parser = TAP::Parser->new( { tap => $tap_source } );
        while ( my $result = $tap_parser->next ) {
            #print $result->as_string . "\n" if $debug;
            $tap_parser->run;
            $aggregator->add( $tap_file_path, $tap_parser );
        }
    }
    my $summary = <<'END_SUMMARY';
Passed:  %s
Failed:  %s
Unexpectedly succeeded: %s

END_SUMMARY
    printf $summary,
        scalar $aggregator->passed,
        scalar $aggregator->failed,
        scalar $aggregator->todo_passed
    ;
    #exit;

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
