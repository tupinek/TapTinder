use strict;
use warnings;

use Carp qw(carp croak verbose);
use FindBin qw($RealBin);

use lib "$RealBin/../libcpan";
use lib "$RealBin/../lib";

use SQL::Translator;

use Data::Dumper;

my $to = $ARGV[0] || 'dbix';
my $input_file = $ARGV[1] || './temp/schema-raw-create.sql';
my $debug = $ARGV[2] || 0;

print "to: $to, input '$input_file', debug: $debug\n" if $debug;

# package - DBIx::Class - .pm
if ( $to eq 'dbix' || $to eq 'ALL' ) {
    my $translator = SQL::Translator->new(
        filename  => $input_file,
        parser    => 'MySQL',
        producer  => 'DBIx::Class::TapTinderFile',
        producer_args => {
            prefix => 'TapTinder::DB::Schema',
        },
    ) or die SQL::Translator->error;

    my $out_fn = './lib/TapTinder/DB/Schema.pm';
    my $content = $translator->translate;
    my $fh;
    open ( $fh, '>', $out_fn ) || die $!;
    print $fh $content;
    close $fh;


# graph - GraphViz - .png
} elsif ( $to eq 'graph' || $to eq 'ALL' ) {
    my $output_type = 'png';

    my $all_clusters = [];

    push @$all_clusters, {
        name => 'Project',
        filename_infix => 'pr',
        tables => [
          qw/ project rep rep_path rep_author rev rev_rep_path rep_file /,
        ],
        colors => [ qw/ Moccasin lightgoldenrod4 / ],
    };

    push @$all_clusters, {
        name => 'Machine',
        filename_infix => 'm',
        tables => [
          qw/ machine farm /,
        ],
        colors => [ qw/ BurlyWood SaddleBrown / ],
    };

    push @$all_clusters, {
        name => 'User',
        filename_infix => 'u',
        tables => [ qw/ user /, ],
        colors => [ qw/ YellowGreen darkgoldenrod4 / ],
    };

    push @$all_clusters, {
        name => 'Patch',
        filename_infix => 'p',
        tables => [ qw/ patch /, ],
        colors => [ qw/ cadetblue cadetblue4 / ],
    };

    push @$all_clusters, {
        name => 'MJConf',
        filename_infix => 'mjc',
        tables => [ qw/ machine_job_conf /, ],
        colors => [ qw/ LightCoral FireBrick / ],
    };

    push @$all_clusters, {
        name => 'FsPSelect',
        filename_infix => 'fss',
        tables => [ qw/ fspath_select fsfile_type /, ],
        colors => [ qw/ LightSalmon Crimson / ],
    };

    push @$all_clusters, {
        name => 'Rep_file_chng',
        filename_infix => 'rch',
        tables => [
          qw/ rep_file_change rep_file_change_from rep_change_type /,
        ],
        colors => [ qw/ Pink DeepPink / ],
    };


    push @$all_clusters, {
        name => 'Jobs',
        filename_infix => 'job',
        tables => [ qw/ job jobp jobp_cmd cmd /, ],
        colors => [ qw/ Coral OrangeRed / ],
    };

    push @$all_clusters, {
        name => 'Machine_sessions',
        filename_infix => 'ms',
        tables => [ qw/ msession msabort_reason mslog msstatus msjob msjobp msjobp_cmd cmd_status / ],
        colors => [ qw/ Khaki DarkKhaki / ],
    };

    push @$all_clusters, {
        name => 'Test_runs',
        filename_infix => 'trun',
        tables => [ qw/ trun trun_status ttest trest tdiag_msg rep_test tfile tskipall_msg / ],
        colors => [ qw/ RoyalBlue MidnightBlue / ],
    };

    push @$all_clusters, {
        name => 'Benchmark_runs',
        filename_infix => 'brun',
        tables => [ qw/ brun brun_conf bfile / ],
        colors => [ qw/ Plum deeppink4 / ],
    };

    push @$all_clusters, {
        name => 'Files_paths',
        filename_infix => 'file',
        tables => [ qw/ fspath fsfile fsfile_ext /, ],
        colors => [ qw/ PaleGreen LimeGreen / ],
    };

    push @$all_clusters, {
        name => 'IRC_robot',
        filename_infix => 'ibot',
        tables => [ qw/ ibot ichannel ichannel_conf ireport_type ibot_log / ],
        colors => [ qw/ PaleTurquoise Turquoise / ],
    };


    push @$all_clusters, {
        name => 'Config',
        filename_infix => 'conf',
        tables => [ qw/ param param_type /, ],
        colors => [ qw/ Grey DimGray / ],
    };

    my $cluster = [];
    foreach my $cluster_num ( 0..$#$all_clusters ) {

        my $cluster = $all_clusters->[ $cluster_num ];

        my $out_file_infix = $cluster->{filename_infix};
        my $out_file = './temp/schema-' . $out_file_infix .  '.' . $output_type;

        print "Running for $cluster->{name} ($cluster->{filename_infix}):\n";
        my $translator = SQL::Translator->new(
            filename  => $input_file,
            parser => 'MySQL',
            producer => 'TTGraphViz',
            debug => $debug,

            producer_args => {
                out_file => $out_file,
                output_type => $output_type,
                #layout => 'neato',
                layout => 'dot',
                add_color => 0,
                show_constraints => 1,

                width => 26,
                height => 18,
                fontsize => 18,

                all_clusters => $all_clusters,
                #only_cluster => $cluster->{name},

                #fontname => '',
                #show_datatypes => 1,
                #show_sizes => 1,
                #join_pk_only => 1,
                #skip_fields => [ 'trun' ],
            },

        ) or die SQL::Translator->error;
        $translator->translate;
        exit;
    }

    print "Running for full schema:\n";
    my $out_file = './temp/schema.' . $output_type;
    my $translator = SQL::Translator->new(
        filename  => $input_file,
        parser => 'MySQL',
        producer => 'TTGraphViz',
        debug => $debug,
        producer_args => {
            out_file => $out_file,
            output_type => $output_type,
            layout => 'neato',
            add_color => 0,
            show_constraints => 1,

            width => 20,
            height => 16,
            fontsize => 18,

            node => {
                shape => 'record',
                style => 'filled',
                fillcolor => 'blanchedalmond',
                #fontcolor => 'white',
                color => 'red',
            },

            #cluster => $cluster,


            #fontname => '',
            #show_datatypes => 1,
            #show_sizes => 1,
            #join_pk_only => 1,
            #skip_fields => [ 'trun' ],
        },
    ) or die SQL::Translator->error;
    $translator->translate;


# TODO - use AutoDia?
# dia - DiaUml - .xml
} elsif ( $to eq 'dia' ) { # || $to eq 'ALL'
    my $translator = SQL::Translator->new(
        filename       => $input_file,
        from           => 'MySQL',
        to             => 'DiaUml',
    ) or die SQL::Translator->error;
}
