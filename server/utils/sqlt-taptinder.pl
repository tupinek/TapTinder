use strict;
use warnings;

use SQL::Translator;

my $to = $ARGV[0] || 'dbix';
my $input_file = './temp/schema-raw-create.sql' || $ARGV[1];
my $debug = $ARGV[2] || 0;

print "to: $to, input '$input_file', debug: $debug\n" if $debug;

# package - DBIx::Class - .pm
if ( $to eq 'dbix' || $to eq 'ALL' ) {
    my $translator = SQL::Translator->new( 
        filename  => $input_file,
        parser    => 'MySQL',
        producer  => 'DBIx::Class::File',
        producer_args => {
            prefix => 'TapTinder::DB::Schema',
        },
    ) or die SQL::Translator->error;
    my $out_fn = './lib/TapTinder/DB/Schema.pm';
    my $fh;
    open ( $fh, '>', $out_fn ) || die $!;
    print $fh $translator->translate;
    close $fh;


# graph - GraphViz - .png
} elsif ( $to eq 'graph' || $to eq 'ALL' ) {
    my $translator = SQL::Translator->new( 
        filename  => $input_file,
        parser => 'MySQL',
        producer => 'GraphViz',
        debug => $debug,
        producer_args => {
            out_file => './temp/schema.png',
            #output_type => 'png',
            #layout => 'neato',
            add_color => 1,
            show_constraints => 1,

            width => 18,
            height => 16,
            fontsize => 18,

            #fontname => '',
            #show_datatypes => 1,
            #show_sizes => 1,
            #join_pk_only => 1,
            skip_fields => [ 'trun' ],
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


  