#!/usr/bin/perl

use strict;
use warnings;
#use warnings FATAL => 'all';

use CGI qw/:standard :cgi-lib/;
use CGI::Carp qw(fatalsToBrowser);

use Time::HiRes qw(time sleep);
use Data::Dumper;

use lib qw(../server/lib);
use TapTinder::DB::Show;

use FindBin qw/$RealBin/;
$RealBin .= '/';

our $db;
our $par;
our $view_def;


sub get_db {
    my $conf_fpath = $RealBin . '../server/conf/dbconf.pl';
    my $conf = require $conf_fpath;

    croak "Config loaded from '$conf_fpath' is empty.\n" unless $conf;

    my $db = TapTinder::DB::Show->new();
    $db->connect( $conf->{db} );
    return $db;
}


sub start {
    return do_show() if !$par->{ac} || $par->{ac} eq 'show';
    return do_show_ttest() if $par->{ac} eq 'ttest';

    print "Content-type: text/plain\n\n";
    print "Unknown param 'ac'.";
    return 1;
}

    
sub db_error {
    my ( $msg ) = @_;

    $msg = '' unless defined $msg;
    $msg .= $db->{dbh}->errstr;
    $msg .= "\n\n";
    my $trace = Devel::StackTrace->new;
    $msg .= $trace->as_string;
    croak $msg;
}


sub prepare_view_def {
    my ( $raw_view_def ) = @_;

    $view_def = {
        'dbcolname_to_sql_rownum' => {},
        'colsql' => '',
        'raw' => $raw_view_def,
    };

    my $sql = '';
    my $row_num = 0;
    for ( my $num = 1; $num <= $#$raw_view_def; $num += 2 ) {
        my $val = $raw_view_def->[$num];
        if ( ref $val ) {
            if ( ref $val eq 'ARRAY' ) {
                $val = $val->[1];
            } else {
                $val = undef;
            }
        }
        if ( defined $val ) {
            $view_def->{dbcolname_to_sql_rownum}->{ $val } = $row_num;
            $sql .= ', ' if $row_num > 0;
            $sql .= $val;
            $row_num++;
        }
    }
    $view_def->{colsql} = $sql;

    #print_dump( [ $sql, cnum('rev.rev_num') ] );

    return $view_def;
}


sub cnum {
    my ( $col_name ) = @_;
    return $view_def->{dbcolname_to_sql_rownum}->{ $col_name };
}


sub table_head {
    my ( $view_def ) = @_;
    
    return "<table class=diff cellpadding=3 cellspacing=3>\n";
}


sub table_row_names {
    my ( $view_def ) = @_;
    
    my $html = "<tr class=>\n";
    my $names = [];
    for ( my $num = 0; $num <= $#{$view_def->{raw}}; $num += 2 ) {
        my $col_name = $view_def->{raw}->[$num];
        if ( defined $col_name ) { 
            ( $col_name ) ? ( $html .= "<th>$col_name</th>\n" ) : ( $html .= '<th>&nbsp;</th>' );
        }
    }
    $html .= "</tr>\n";
    return $html;
}


sub num_diff {
    my $dbcolname = shift;
    my $param = shift;
    my ( $row_num, $prow, $row, $class ) = @_;

    my $html = '<td';
    my $class;

    my $rownum = cnum( $dbcolname );
    my $pval = $prow->[ $rownum ];
    my $val  = $row->[ $rownum ];

    ((not defined $val) || (not defined $pval) || $pval <= $val) ? ($class = 'ok') : ($class = 'err');
    $html .= qq{ class="$class"};
    $html .= '>';
    $html .= $pval;
    $html .= "</td>\n";
    return $html;
}


sub cf_num_diff_and_ahref {
    my $dbcolname = shift;
    my $param = shift;
    my ( $row_num, $prow, $row ) = @_;
    
    my $rownum = cnum( $dbcolname );
    my $pval = $prow->[ $rownum ];
    my $val  = $row->[ $rownum ];
    
    my $html = '<td';
    my $worse = 1;
    $worse = 0 if (not defined $val) || (not defined $pval) || $pval <= $val;
    my $changed = 0;
    $changed = 1 if (defined $val) && (defined $pval) && $pval != $val;

    my $class = ( 'ok', 'err' )[$worse];
    $html .= qq{ class="$class"};
    $html .= '>';
    $html .= $pval;

    if ( $changed ) {
        $html .= "&nbsp;";
        my $trun_id1 = $prow->[ cnum('trun.trun_id') ];
        my $trun_id2 = $row->[ cnum('trun.trun_id') ];
        $html .= qq{<a href="?ac=ttest&amp;trun_id1=$trun_id1&amp;trun_id2=$trun_id2&amp;trest_id=$param">..</a>};
    }
    $html .= "</td>\n";
    return $html;
}

sub cf_trest_diff {
    my $dbcolname = shift;
    my $for_trun_id = shift;
    my ( $row_num, $prow, $row ) = @_;
    
    my $trun_id = $prow->[ cnum( $dbcolname ) ];
    if ( $trun_id != $for_trun_id ) {
        return "<td>&nbsp;</td>\n";
    }
    
    return "<td>" . $prow->[ cnum( 'res.title') ] . "</td>\n";


    my $rownum = cnum( $dbcolname );
    my $pval = $prow->[ $rownum ];
    my $val  = $row->[ $rownum ];
    
    my $html = '<td';
    my $worse = 1;
    $worse = 0 if (not defined $val) || (not defined $pval) || $pval <= $val;
    my $changed = 0;
    $changed = 1 if (defined $val) && (defined $pval) && $pval != $val;

    my $class = ( 'ok', 'err' )[$worse];
    $html .= qq{ class="$class"};
    $html .= '>';
    $html .= $pval;

    if ( $changed ) {
        $html .= "&nbsp;";
        my $trun_id1 = $prow->[ cnum('trun.trun_id') ];
        my $trun_id2 = $row->[ cnum('trun.trun_id') ];
    }
    $html .= "</td>\n";
    return $html;
}

sub checkbox {
    my ( $row_num, $prow, $row, $class ) = @_;

    return qq{<td><input name="selected_fld[]" value="$row_num"  id="aaa$row_num" type=checkbox /></td>\n};
}


sub table_row {
    my ( $row_num, $prow, $row ) = @_;
    
    my $html = '';

    $html .= "<tr ";
    my $class = '';
     $class .= ( $row_num % 2 == 0 ) ? 'odd' : 'even';
    $html .= qq{class="$class"};
    $html .= '>';
    
    my $table_row_num = 0;
    for ( my $num = 0; $num <= $#{$view_def->{raw}}; $num += 2 ) {
        my $val = $view_def->{raw}->[$num+1];
        unless ( defined $view_def->{raw}->[$num] ) {
            $table_row_num++ if defined $val && ref $val ne 'CODE';
            next;
        }
       
        if ( defined $val ) {
            if ( ref $val eq 'CODE' ) {
                $html .= $val->( $num, @_ );

            } elsif ( ref $val eq 'ARRAY' ) {
                $html .= $val->[0]->( $val->[1], $val->[2], @_ );
                $table_row_num++;

            } else {
                $html .= "<td>";
                $html .= ( defined $prow->[$table_row_num] ? $prow->[$table_row_num] : '&nbsp;' );
                $html .= "</td>\n";
                $table_row_num++;
            }
        } else {
            $html .= "<td>&nbsp;</td>\n";
        }
    }
    $html .= "</tr>\n";

    if ( defined $row && $prow->[cnum('rev.rev_num')] - $row->[cnum('rev.rev_num')] > 1 ) {
        $html .= "<tr><td colspan=5>&nbsp;</td></tr>\n";
    }

    return $html;
}


sub table_foot {
    return "</table>\n";
}


sub print_dump {
    print "<pre>\n";
    print Dumper( @_ );
    print "</pre>\n";
}



sub do_show_ttest {
    require $RealBin . 'templ/head.pl';

    my $trest_id = $par->{trest_id} || 0;
    my $trun_id1 = $par->{trun_id1};
    my $trun_id2 = $par->{trun_id2};

    my $rev_num1 = $db->get_trun_rev_num( $trun_id1 );
    my $rev_num2 = $db->get_trun_rev_num( $trun_id2 );
    
    # show lower rev_num col first
    if ( $rev_num1 > $rev_num2 ) {
        ( $trun_id1, $trun_id2 ) = ( $trun_id2, $trun_id1 );
        ( $rev_num1, $rev_num2 ) = ( $rev_num2, $rev_num1 );
    }
    
    my $trun_id_to_rev_num = {
        $trun_id1 => $rev_num1,
        $trun_id2 => $rev_num2,
    };
    
    
    my $raw_view_def = [
        'id',  'rt.rep_test_id',
        'Test file', 'rf.sub_path',
        'Num', 'rt.number',      
        'Name', 'rt.name',
        $rev_num1, [ \&cf_trest_diff, 'trun.trun_id', $trun_id1 ],
        $rev_num2, [ \&cf_trest_diff, 'trun.trun_id', $trun_id2 ],
        undef,  'res.title',
        undef,  'trun.trun_id',
        undef,  'res.title',
    ];
    $view_def = prepare_view_def( $raw_view_def );
    
    #print_dump( [ $cols_sql, $view_def ] );

    
    # TODO, rep_path_id
    my $sth = $db->{dbh}->prepare( qq{
        select $view_def->{colsql}
          from ttest, rep_test rt, rep_file rf, trun, trest res
         where ( ttest.trun_id = ? or ttest.trun_id = ? )
           and ttest.trest_id = ?
           and rt.rep_test_id = ttest.rep_test_id
           and rf.rep_file_id = rt.rep_file_id
           and trun.trun_id = ttest.trun_id
           and res.trest_id = ttest.trest_id
         order by rf.sub_path, rt.number
    } );
    return db_error() if $db->{dbh}->err;


    my @bv = ( $trun_id1, $trun_id2, $trest_id );
    $sth->execute(@bv);
    return db_error() if $db->{dbh}->err;

    print table_head( $view_def );
    my $row_num = 0;
    my ( $row, $prev_row );
    while ( $row = $sth->fetchrow_arrayref ) {
        print table_row_names( $view_def ) if $row_num % 25 == 0;
        #print_dump( $row );
        if ( defined $prev_row ) {
            print table_row( $row_num, $prev_row, $row, 1 );
        }
        $prev_row = [ @$row ];
        $row_num++;
        last unless $row;
    }
    if ( $db->{dbh}->err ) {
        return db_error();
    } else {
        print table_row( $row_num, $prev_row, $row, 1 );
    }
    print table_foot();

    require $RealBin . 'templ/foot.pl';
    return 1;
}


sub do_show {    
    require $RealBin . 'templ/head.pl';
    
    sub sub_details {
        my ( $row ) = @_;
        "<td>----</td>\n";
    };
    
    my $raw_view_def = [
        '',         [ \&checkbox, 'trun.trun_id' ],
        'Revision', 'rev.rev_num',
        'Author',   'rep_author.rep_login',      
        'Archname', 'machine.archname',
        'Not seen', [ \&cf_num_diff_and_ahref, 'trun.num_notseen', 0 ],
        'Failed',   [ \&cf_num_diff_and_ahref, 'trun.num_failed',  1 ],
        'Unknown',  [ \&cf_num_diff_and_ahref, 'trun.num_unknown', 2 ],
        'Todo',     'trun.num_todo',
        'Bonus',    [ \&cf_num_diff_and_ahref, 'trun.num_bonus', 4 ],
        'Skip',     'trun.num_skip',
        'Ok',       'trun.num_ok',
        'Details',  \&sub_details,
    ];
    $view_def = prepare_view_def( $raw_view_def );
    
    #print_dump( [ $cols_sql, $view_def ] );

    # TODO    
    my $rep_id = 1;
    my $max_rev_num = $db->get_max_rev_num( $rep_id );
    
    # TODO, rep_path_id
    my $sth = $db->{dbh}->prepare( qq{
        select $view_def->{colsql}
          from build, trun, rev, machine, rep_author
         where build.rep_path_id = 1
           and rev.rev_id = build.rev_id
           and rev.rev_num >= ?
           and rev.rev_num <= ?
           and trun.build_id = build.build_id
           and machine.machine_id = build.machine_id
           and rep_author.rep_author_id = rev.author_id
         order by rev.rev_num desc
    } );
    return db_error() if $db->{dbh}->err;

    my $num_to_show = $par->{num} || 25;
    my $rev_num_to = $par->{revt} || $max_rev_num;

    my @bv = ( $rev_num_to - $num_to_show + 1, $rev_num_to );
    $sth->execute(@bv);
    return db_error() if $db->{dbh}->err;

    print table_head( $view_def );
    my $row_num = 0;
    my ( $row, $prev_row );
    while ( $row = $sth->fetchrow_arrayref ) {
        print table_row_names( $view_def ) if $row_num % 25 == 0;
        #print_dump( $row );
        if ( defined $prev_row ) {
            print table_row( $row_num, $prev_row, $row );
        }
        $prev_row = [ @$row ];
        $row_num++;
        last unless $row;
    }
    if ( $db->{dbh}->err ) {
        return db_error();
    } else {
        print table_row( $row_num, $prev_row, $row );
    }
    print table_foot();
    
    print 
        qq{<a href="?revt=},
        ($rev_num_to - $num_to_show + 1),
        ( $par->{num} ? '&amp;num=' . $par->{num} : '' ),
        qq{">prev</a>\n};

    print 
        qq{<a href="?revt=},
        ($rev_num_to + $num_to_show - 1),
        ( $par->{num} ? '&amp;num=' . $par->{num} : '' ),
        qq{">next</a>\n};
    

    require $RealBin . 'templ/foot.pl';
    return 1;
}


sub test {
    require $RealBin . 'templ/head.pl';
    print "<pre>";
    print $RealBin;
    print "</pre>";
    require $RealBin . 'templ/foot.pl';
    return 1;
}
#test(); exit;


$db = get_db();
$par = Vars();
start();
