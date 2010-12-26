package TapTinder::Web::ControllerBase;

use strict;
use warnings;
use base 'Catalyst::Controller';

use Data::Page::HTML qw();
use DBIx::Dumper qw();
use Data::Dumper qw();

=head1 NAME

TapTinder::Web::Controller::Report - Catalyst Controller

=head1 DESCRIPTION

Base class for some TapTinder::Web::Controller::*.

=head1 METHODS


=head2 dadd

Add string to stash->{ot}.

=cut

sub dadd {
    my $self = shift;
    my $c = shift;
    my $str = shift;
    $c->stash->{ot} .= $str;
}


=head2 dumper

Dumper to stash->{ot} or directly to STDERR.

=cut

sub dumper {
    my $self = shift;
    my $c = shift;

    return unless $c->log->is_debug;

    foreach my $val ( @_ ) {
        my $var_type = ref($val);
        if ( $var_type =~ /^TapTinder\:\:Web\:\:Model/ ) {
            $c->stash->{ot} .= "dump_row:\n";
            $c->stash->{ot} .= DBIx::Dumper::dump_row( $val );
        } else {
            #$c->stash->{ot} .= "normal dumper: \n";
            $c->stash->{ot} .= Data::Dumper::Dumper( $val );
        }
    }

    # Change next line to 1  to see debug on server side too.
    if ( 1 ) {
        return 1 unless $c->stash->{ot};
        print STDERR $c->stash->{ot} . "\n";
        $c->stash->{ot} = '';
    }

    return 1;
}


=head2 get_select_mdata

Return meta data for SQL select part.

=cut

sub edbi_get_select_mdata {
    my ( $self, $c, $cols, $sql_base, $conf ) = @_;

    my $cols_sql_str = '';
    #$cols_sql_str = join( q{, }, @$cols );
    my $name_to_pos = {};
    my $pos_to_name = [];

    foreach my $col_num ( 0..$#$cols ) {
        $cols_sql_str .= ",       \n" if $cols_sql_str;

        my $col_def = $cols->[ $col_num ];
        if ( ref $col_def eq 'ARRAY' ) {
            my $col = $col_def->[1];
            $cols_sql_str .= $col_def->[0] . ' as ' . $col;
            $name_to_pos->{ $col } = $col_num;
            $pos_to_name->[ $col_num ] = $col;

        } else {
            my $col = $col_def;
            $cols_sql_str .= $col;
            if ( $conf->{with_prefix} ) {
                my $esc_col = $col;
                $esc_col =~ tr{\.}{\__};
                $cols_sql_str .= ' as ' . $esc_col;
                $name_to_pos->{ $esc_col } = $col_num;
                $pos_to_name->[ $col_num ] = $esc_col;
            } else {
                $name_to_pos->{ $col } = $col_num;
                $pos_to_name->[ $col_num ] = $col;
            }
        }
    }

    my $sql = "select $cols_sql_str $sql_base";
    return ( $sql, $name_to_pos, $pos_to_name ); 
}


=head2 edbi_run_dbh_do

eDBI run dbh_do method.

=cut

sub edbi_run_dbh_do {
    my ( $self, $c, $method_name, $cols, $sql_base, $ba, $conf ) = @_;

    my $sql = undef;
    my $name_to_pos = [];
    my $pos_to_name = [];
    
    my $prepare_cols = ( defined $cols );

    if ( $prepare_cols ) {
        ( $sql, $name_to_pos, $pos_to_name ) = $self->edbi_get_select_mdata(
            $c, $cols, $sql_base, $conf
        );

    } else {
        $sql = $sql_base;
    }

    #my $data = $schema->storage->dbh->selectall_arrayref( $sql, {}, @$ba );
    my $schema = $c->model('WebDB')->schema;
    
    if ( $schema->storage->debug ) {
        print STDERR $sql;
        print STDERR "\n" if $sql !~ m{\n\s*$}s;
        print STDERR 'me: ' . join( ', ', @$ba ) . "\n";
    }
    
    my $data = $schema->storage->dbh_do(
        sub { return $_[1]->$method_name( $_[2], {}, @{$_[3]} ); }, $sql, $ba
    );

    unless ( $data ) {
        my $str = $schema->storage->dbh->errstr;
        if ( $str ) {
            print STDERR $str;
        }
    }
    
    my $rh = {};
    if ( $prepare_cols ) {
        $rh = {
            'data' => $data,
            'n2p' => $name_to_pos,
            'p2n' => $pos_to_name,
        };
    } else {
        $rh = {
            'data' => $data,
        };
    }

    if ( 0 ) {
        $rh->{sql} = $sql;
        $self->dumper( $c, $rh );
    }

    return $rh;
}


=head2 edbi_selectall_arrayref

Run eDBI selectall_arrayref.

=cut

sub edbi_selectall_arrayref {
    my $self = shift;
    my $c = shift;

    my $do_data = $self->edbi_run_dbh_do( $c, 'selectall_arrayref', @_ );
    return $do_data->{data};
}


=head2 edbi_selectrow_hashref

Run eDBI selectrow_hashref.

=cut

sub edbi_selectrow_hashref {
    my $self = shift;
    my $c = shift;

    my $do_data = $self->edbi_run_dbh_do( $c, 'selectrow_hashref', @_ );
    return $do_data->{data};
}


=head2 get_projname_params

...

=cut

sub get_projname_params {
    my ( $self, $c, $p_project, $par1, $par2 ) = @_;


    my $is_index = 0;
    my $project_name = undef;
    my $params;

    $is_index = 1 if !$p_project; # project list
    # project name found
    if ( $p_project ) {
        $project_name = $p_project;
        $project_name =~ s{^pr-}{};
        $c->stash->{project_name} = $project_name;
    }
    $c->stash->{project_uri} = $c->uri_for( '/' . $c->action->namespace . '/pr-'.$project_name.'/' );

    # project name, nothing else
    if ( !$par1 ) {
        $is_index = 1;
    # project name and parameters
    } elsif ( $par1 =~ /^(page|rows|offset)\-/ ) {
        $params = $par1;
        $is_index = 1;
    # probably rep_path name
    } else {
        $params = $par2 if $par2;
    }

    $self->dumper( $c, { p_project => $p_project, par1 => $par1, par2 => $par2, } );
    $self->dumper( $c, { is_index => $is_index, project_name => $project_name, params => $params, } );

    return ( $is_index, $project_name, $params );
}


sub get_page_params {
    my ( $self, $params ) = @_;

    # default page listing values
    my $pr = {
        page => 1,
    };
    if ( $params ) {
        # try to set page, rows, ... values from url params
        my @parts = split( ',', $params );
        foreach my $part ( @parts ) {
            if ( $part =~ m/^ page-(\d+) $/x ) {
                $pr->{page} = $1;
                next;
            }
            if ( $part =~ m/^ (rows|offset)-(\d+) $/x ) {
                $pr->{$1} = $2;
                next;
            }
        }
        $pr->{page} = 1 if $pr->{page} < 1;
    }
    return $pr;
}


sub get_pager_html {
    my $self = shift;
    return Data::Page::HTML::get_pager_html( @_ );
}


=head2 get_fspath_select_row

Return fspath_select columns hash for fsfile_type_id and rep_id.

=cut

sub get_fspath_select_row {
    my ( $self, $c, $fsfile_type_id, $rep_id ) = @_;

    my $rs = $c->model('WebDB::fspath_select')->search( {
        'me.fsfile_type_id' => $fsfile_type_id,
        'me.rep_id' => $rep_id,
    }, {
        select => [ 'fspath_id.fspath_id', 'fspath_id.path', 'fspath_id.name',  ],
        as => [ 'fspath_id', 'path', 'name',  ],
        join => [ 'fspath_id' ],
    } );
    my $row = $rs->next;
    return undef unless $row;
    my $row_data = { $row->get_columns() };
    return $row_data;
}



=head1 SEE ALSO

L<TapTinder::Web>, L<Catalyst::Controller>

=head1 AUTHOR

Michal Jurosz <mj@mj41.cz>

=head1 LICENSE

This file is part of TapTinder. See L<TapTinder> license.

=cut


1;
