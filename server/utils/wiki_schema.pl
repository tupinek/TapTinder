#! perl

# server> perl utils/wiki_schema.pl sql/schema.wiki 1 > sql/schema.sql

use strict;
use warnings;

use Carp qw(carp croak verbose);


sub slurp_file {
    my $fp = shift;
    open( my $fh, '<', $fp ) or croak $!;
    local $/ = undef;
    return <$fh>;
}

                       
sub get_sources {
    my ( $text, $part_name, $rh_source_types, $debug ) = @_;

    my $line_num = 1;
    my $res;
    my $part_level = 0;
    my @source_level = ();
    my $res_text = '';
    my $new_source_part = 0;

    PARSER: {
        if ( $text =~ /\G( \<\!\-\-\s*PARSE\s+PART\s+(\S+?)\s+(BEGIN|END)\s*\-\-\> )/gscx )
        { 
            my $full_c = $1;
            my $type = $2;
            my $begin_end = $3;
            if ( $begin_end eq 'BEGIN' ) {
                $part_level++;
            }
            else {
                $part_level--;
            }
            print "line_num: $line_num\n" if $debug > 1;
            print "  type: $type, begin_end: $begin_end\n" if $debug > 1;
            $line_num += ($full_c =~ tr/\n//);
            redo PARSER;
        }

        if ( $text =~ /\G( \<source\s+lang=\"*(\S+?)\"*\s*\>\s*\n? )/gscx ) {
            my $full_c = $1;
            my $source_type = $2;
            push @source_level, $source_type;
            $new_source_part = 1;
            print "line_num: $line_num, source begin: $source_type\n" if $debug > 1;
            print "  new levels: @source_level\n" if $debug && @source_level > 1;
            $line_num += ($full_c =~ tr/\n//);
            redo PARSER;
        }

        if ( $text =~ /\G( \<\/source\>\s*\n? )/gscx ) {
            my $full_c = $1;
            print "line_num: $line_num, source end\n" if $debug > 1;
            pop @source_level;
            print "  new levels: @source_level\n" if $debug > 1 && @source_level >= 1;
            $line_num += ($full_c =~ tr/\n//);
            redo PARSER;
        }

        if ( $text =~ /\G( [^\<]+ )/gscx || $text =~ /\G( . )/gscx ) {
            my $full_c = $1;
            print "line_num: $line_num\n" if $debug > 1;
            
            if ( $part_level && @source_level > 0 ) {
                #print $full_c if $debug > 1;
                if ( exists $rh_source_types->{ $source_level[-1] } ) {
                    if ( $new_source_part ) {
                        $res_text .= "\n\n" if $res_text ne '';
                        $res_text .= "-- line: $line_num\n" if $debug > 0;
                    }
                    $new_source_part = 0;
                    $res_text .= $full_c;
                    print "  OK\n" if $debug > 1;
                } else {
                    print "  SKIPPED\n" if $debug > 1;
                }
            }
            
            $line_num += ($full_c =~ tr/\n//);
            redo PARSER;
        }
    }
    
    print "\n\n" if $debug > 1;
    return $res_text;
}


sub get_table_list {
    my ( $text, $debug ) = @_;

    my @tables = ();
    PARSER: {
        if ( $text =~ /\G( CREATE\s+TABLE\s+`?(\S+?)`?\s+\(\s* )/gscx )
        { 
            my $table = $2;
            print "$table\n" if $debug > 1;
            push @tables, $table;
        }
        if ( $text =~ /\G( [^C]+ )/gscx ) {
            redo PARSER;
        }
        if ( $text =~ /\G( . )/gscx ) {
            redo PARSER;
        }
    }
    
    return \@tables;
}


sub print_tables_for_sql {
    my ( $tables ) = @_;

    my $num = 0;
    foreach my $table ( sort @$tables ) {
        print ", " if $num > 0;
        print '`' . $table . '`';
        $num++;
    }
}


my $in_fpath = $ARGV[0] || 'sql/schema.wiki';
my $debug = $ARGV[1] || 0;
my $content = slurp_file( $in_fpath );
my $create_sql = get_sources( $content, 'DBCREATE', { 'sql' => 1, }, $debug );
my $ra_tables = get_table_list( $create_sql, $debug );

print "-- Do not edit this file.\n";
print "-- Generated from: '$in_fpath'";
print "\n\n";

print "-- table list:\n";
print "-- ";
print_tables_for_sql( $ra_tables );
print "\n\n";

print "-- Drop all tables:\n";
#print "-- ";
print "SET FOREIGN_KEY_CHECKS=0; DROP TABLE IF EXISTS ";
print_tables_for_sql( $ra_tables );
print ";";
print "\n\n";

print "$create_sql\n";