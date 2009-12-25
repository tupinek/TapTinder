use strict;
use warnings;

use Carp qw(carp croak verbose);
use FindBin qw($RealBin);

use lib "$RealBin/../lib";

use SQL::Translator;

use Data::Dumper;
sub mdump {
    my $dumper = Data::Dumper->new( \@_ );
    $dumper->Purity(1)->Terse(1)->Deepcopy(1);
    print $dumper->Dump;
}


my $to = $ARGV[0] || 'dbix';
my $input_file = $ARGV[1] || './temp/schema-raw-create.sql';
my $ver = $ARGV[2] || 3;

print "to: $to, input '$input_file', ver $ver\n" if $ver >= 3;


# package - DBIx::Class - .pm
if ( $to eq 'dbix' || $to eq 'ALL' ) {
    my $translator = SQL::Translator->new(
        filename  => $input_file,
        parser    => 'MySQL',
        producer  => 'DBIx::Class::FileMJ',
        producer_args => {
            prefix => 'TapTinder::DB::Schema',
            base_class_name => 'TapTinder::DB::DBIxClassBase',
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
    $output_type = 'svg';

    my $tr = SQL::Translator->new(
        parser    => 'MySQL',
        filename  => $input_file,
    ) or die SQL::Translator->error;

    # Mined from $tr->translate method
    my $data = $tr->data;
    $tr->parser->( $tr, $$data );

    # Invoke an anonymous subroutine directly
    my $schema = $tr->schema;
    my @tables = $schema->get_tables;

    # Get tags and tags shortcuts for tables.
    my $tags_tables = {};
    my $tags_shortcuts = {};
    foreach my $table ( @tables ) {
        my $comment = $table->comments;
        my $table_name = $table->name;
        
        print $table_name . "\n" if $ver >= 3;
        print "  comment: '$comment'\n" if $ver >= 4;
        my @tags = ();
        my $found = 0;
        if ( my ( $tags_part ) = $comment =~ m/ Tag\: \s* ([^\.]+) \s* (?:\.|$) /isx ) {
            print "  tags str: '$tags_part'\n" if $ver >= 4;
            my @raw_tags = split( ',', $tags_part );
            print '  raw: ' . join(', ', @raw_tags ) . "\n" if $ver >= 4;
            foreach my $tag ( @raw_tags ) {
                $tag =~ s/^\s+//;
                $tag =~ s/\s+$//;
                $tags_tables->{ $tag } = [] unless exists $tags_tables->{ $tag };
                $found = 1;
                push @{ $tags_tables->{ $tag } }, $table_name;
            }
        }
        
        print "  found: $found\n" if $ver >= 4;
        unless ( $found ) {
            my $tag = '_no_tags';
            push @{ $tags_tables->{ $tag } }, $table_name;
        }
        
        print "\n" if $ver >= 3;
    }
    #mdump( $tags_tables ); exit;


    my $tag_colors = [
        [ qw/ Moccasin burlywood4 / ],
        [ qw/ BurlyWood SaddleBrown / ],
        [ qw/ YellowGreen darkgoldenrod4 / ],
        [ qw/ cadetblue cadetblue4 / ],
        [ qw/ LightCoral FireBrick / ],
        [ qw/ LightSalmon Crimson / ],
        [ qw/ Pink DeepPink / ],
        [ qw/ Coral OrangeRed / ],
        [ qw/ Khaki brown4 / ],
        [ qw/ RoyalBlue MidnightBlue / ],
        [ qw/ Plum deeppink4 / ],
        [ qw/ PaleGreen LimeGreen / ],
        [ qw/ PaleTurquoise dodgerblue3 / ],
        [ qw/ Grey DimGray / ],
    ];


    my $all_clusters = [];
    my $tag_num = 0;
    foreach my $tag ( keys %$tags_tables ) {
        push @$all_clusters, {
            name => $tag,
            tables => $tags_tables->{ $tag },
            colors => $tag_colors->[ $tag_num ],
        };
        $tag_num++;
    }
    

    my $out_dir = './temp/schema';
    mkdir( $out_dir ) unless -d $out_dir;

    my %out_files_map = (
        'as_png' => 'png',
        'as_cmapx' => 'cmap',
        'as_svg' => 'svg',
    );
    if ( 1 ) {
        foreach my $cluster_num ( 0..$#$all_clusters ) {

            my $cluster = $all_clusters->[ $cluster_num ];
            my $cluster_name = $cluster->{name};

            my $out_files = {};
            foreach my $method_name ( keys %out_files_map ) {
                my $out_file_basename = $cluster->{name};
                my $file_type = $out_files_map{ $method_name };
                my $t_out_dir = $out_dir . '/' . 'cluster-' . $file_type;
                unless ( -d $t_out_dir ) {
                    mkdir( $t_out_dir ) or croak "Can't create directory '$t_out_dir': $!\n";
                }
                my $out_file = $t_out_dir . '/' . $out_file_basename .  '.' . $file_type;
                $out_files->{$method_name} = $out_file;
            }

            print "Running for $cluster->{name} ($cluster->{filename_infix}).\n";
            my $translator = SQL::Translator->new(
                filename  => $input_file,
                parser => 'MySQL',
                producer => 'TTGraphViz',
                debug => ( $ver >= 6 ),

                producer_args => {
                    out_files => $out_files,
                    output_type => $output_type,
                    name => $cluster_name,

                    #layout => 'neato',
                    layout => 'dot',
                    add_color => 0,
                    show_constraints => 1,

                    #width => 22,
                    #height => 18,
                    fontsize => 18,

                    all_clusters => $all_clusters,
                    only_clusters => $cluster->{name},
                    filter_no_cluster_fields_out => 1,
                    filter_in_related_tables => 1,
                    filter_no_cluster_fields_in => 1,

                    table_name_url_prefix => 'http://dev.taptinder.org/wiki/DB_Schema#',

                    #fontname => '',
                    #show_datatypes => 1,
                    #show_sizes => 1,
                    #join_pk_only => 1,
                    #skip_fields => [ 'trun' ],
                },

            ) or die SQL::Translator->error;
            $translator->translate;
            #exit;
        }
    }

    my $out_files = {};
    foreach my $method_name ( keys %out_files_map ) {
        my $file_type = $out_files_map{$method_name};
        my $out_file = $out_dir . '/' . 'schema' .  '.' . $file_type;
        $out_files->{$method_name} = $out_file;
    }

    print "Running for full schema.\n";
    my $translator = SQL::Translator->new(
        filename  => $input_file,
        parser => 'MySQL',
        producer => 'TTGraphViz',
        debug => ( $ver >= 6 ),
        producer_args => {
            out_files => $out_files,
            output_type => $output_type,
            name => 'schema',

            layout => 'dot',
            #layout => 'neato',
            add_color => 0,
            show_constraints => 1,

            width => 30,
            height => 20,
            fontsize => 18,

            node => {
                shape => 'record',
                style => 'filled',
                fillcolor => 'blanchedalmond',
                #fontcolor => 'white',
                color => 'red',
            },

            all_clusters => $all_clusters,

            table_name_url_prefix => 'http://dev.taptinder.org/wiki/DB_Schema#',

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
