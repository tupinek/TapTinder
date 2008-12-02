package CatalystX::Controller::TableBrowser;

use strict;
use warnings;
use base 'Catalyst::Controller';

our $VERSION = '0.003';

use Data::Page::HTML qw/get_pager_html/;
use Data::Dumper; # TODO - needed only for debug mode

=head1 NAME

CatalystX::Controller::TableBrowser - base for your table browser Catalyst controller

=head1 SYNOPSIS

  package TapTinder::Web::Controller::Table;
  use base 'CatalystX::Controller::TableBrowser';

  sub db_schema_base_class_name {
      return 'WebDB';
  }

  sub db_schema_class_name {
      return 'TapTinder::Web::Model::WebDB';
  }

  sub index : Path  {
      my $self = shift;
      return $self->base_index( @_ );
  }

  1;

=head1 DESCRIPTION

Use database schema (L<DBIx::Class>) metadata (L<DBIx::Class::ViewMD>) to create
table browser cotroller for your L<Catalyst> application.

=cut


sub db_schema_base_class_name {
    return 'MyAppDB';
}


sub db_schema_class_name {
    return 'MyApp::Model::MyAppDB';
}


sub use_complex_search_by_id {
    return 1;
}


sub dumper {
    my ( $self, $c, $ra_data, $prefix_text ) = @_;
    $c->stash->{ot} .= $prefix_text . Dumper( $ra_data );
}


sub base_index  {
    my ( $self, $c, $table_name, @args ) = @_;

    $c->stash->{ot} = '';

    # show table list
    return $self->show_table_list( $c ) if !$table_name;

    # show table data
    $c->stash->{template} = 'table/data.tt2';
    $c->stash->{table_name} = $table_name;
    $c->stash->{index_uri} = $c->uri_for()->as_string,

    # user defined parameters (another one is table_name)
    my $pr = {
        rows => 15,
        page => undef,
        selected_ids => undef,
    };
    $self->set_pr( $pr, $args[0] ) if $args[0];

    my $schema = $self->get_schema( $c );
    $self->is_table_orserr( $c, $schema, $table_name ) or return;

    $c->stash->{msgs} = [];
    my $cols_allowed = [ $self->get_allowed_cols( $c, $schema, $table_name ) ];

    my $rels = $self->get_rels( $c, $schema, $table_name );
    $c->stash->{rels} = $rels;

    $c->stash->{uri_for_related} = $self->default_rs_uri_for_related($c);
    $self->dumper( $c, [ $rels ], 'rels: ' );

    my $view_class = $self->db_schema_class_name.'::'.$table_name;
    $c->stash->{col_names} = $cols_allowed;
    $c->stash->{col_titles} = $view_class->titles || $self->col_names_to_titles( $cols_allowed );

    $self->prepare_data_orserr( $c, $schema, $table_name, $cols_allowed, $pr ) or return;

    #$self->dumper( $c, [ $c->stash ], 'stash' );
}


sub get_schema {
    my ( $self, $c ) = @_;
    return $c->model( $self->db_schema_base_class_name )->schema;
}


sub show_table_list {
    my ( $self, $c ) = @_;

    my $schema = $self->get_schema($c);
    $c->stash->{template} =  $c->action->namespace . '/index.tt2';

    my @tables = $schema->sources;
    my @tables_hash = ();
    foreach my $table_name ( sort @tables ) {
        push @tables_hash, {
            name => $table_name,
            uri => $c->uri_for( $table_name )->as_string
        };
    }
    $c->stash->{tables} = \@tables_hash;
    return;
}


sub set_pr {
    my ( $self, $pr, $args ) = @_;

    my @parts = split( ',', $args );
    foreach my $part ( @parts ) {
        if ( $part =~ m/^ page-(\d+) $/x ) {
            $pr->{page} = $1;
            next;
        }
        if ( $part =~ m/^ rows-(\d+) $/x ) {
            $pr->{rows} = $1;
            next;
        }
        if ( $part =~ m/^ id-(\S+) $/x ) {
            my $matched = $1;
            if ( $matched =~ /-/ ) {
                $pr->{selected_ids} = [ split('-',$matched) ];
            } else {
                $pr->{selected_ids} = [ $matched ];
            }
            #$self->dumper( $c, [ \@selected_id ] );
            next;
        }
    }
}


sub is_table_orserr {
    my ( $self, $c, $schema, $table_name ) = @_;

    my @tables = $schema->sources;

    my $ok = 0;
    my $ci_name = undef;
    foreach my $table ( @tables ) {
        if ( $table eq $table_name ) {
            $ok = 1;
            last;
        }
        if ( uc($table) eq uc($table_name) ) {
            $ci_name = $table;
        }
    }
    if ( !$ok ) {
        my $msg = "Table '$table_name' doesn't exists";
        if ( $ci_name ) {
            $msg .= '. Did you mean \'<a href="' . $c->uri_for( $ci_name ) . '">' . $ci_name . "</a>'";
        }
        $msg .= ".\n";
        $c->stash->{error} = $msg;
        return 0;
    }
    return 1;
}


sub get_allowed_cols {
    my ( $self, $c, $schema, $table_name ) = @_;

    my $view_class = $self->db_schema_class_name.'::'.$table_name;

    my @cols;
    # TODO
    #my $maybe_cols_ra = $schema->source($table_name)->cols_in_table_view;
    my $maybe_cols_ra = $view_class->cols_in_table_view;
    @cols = @{$maybe_cols_ra} if $maybe_cols_ra;
    @cols = $schema->source( $table_name )->columns unless @cols;

    if ( !$view_class->can('restricted_cols') ) {
        my $msg = "VieDef for table '$table_name' missing. Try '__PACKAGE__->load_components(qw/ViewMD/);' inside package '$view_class'.";
        $c->stash->{error} = $msg;
        return;
    }


    my $restricted_cols = $view_class->restricted_cols;
    my @msgs = ();
    my @cols_allowed;
    if ( $restricted_cols ) {
        my $msg = '';
        @cols_allowed = ();
        my @temp_cols_restricted = ();
        foreach my $col ( @cols ) {
            if ( $restricted_cols->{$col} ) {
                push @temp_cols_restricted, $col;
            } else {
                push @cols_allowed, $col;
            }
        }
        if ( scalar @temp_cols_restricted > 0 ) {
            $msg = "Acces denied to show column" . ( scalar @temp_cols_restricted > 1 ? 's' : '' ) . ' ';
            if ( scalar @temp_cols_restricted == 1 ) {
                $msg .= "'$temp_cols_restricted[0]'";
            } elsif ( scalar @temp_cols_restricted == 2 ) {
                $msg .= "'" . join( "' and '", @temp_cols_restricted ) . "'";
            } elsif ( scalar @temp_cols_restricted == 3 ) {
                my $last = pop @temp_cols_restricted;
                $msg .= "'" . join( "', '", @temp_cols_restricted ) . "' and '$last'";
            }
            $msg .= " in table '$table_name'.\n";
            push @{$c->stash->{msgs}}, $msg;
        }

    } else {
        @cols_allowed = @cols;
    }
    return @cols_allowed;
}


sub get_rels {
    my ( $self, $c, $schema, $table_name ) = @_;

    my $rels = {};
    my @raw_rels = $schema->source($table_name)->relationships;
    $self->dumper( $c, [ $rels ], 'raw rels: ' );
    foreach my $rel_name ( @raw_rels ) {
        my $info = $schema->source($table_name)->relationship_info( $rel_name );
        $self->dumper( $c, [ $info ], "raw rel info for '$rel_name': " );

        next if defined $info->{attrs}->{join_type} && $info->{attrs}->{join_type} eq 'LEFT';

        my $fr_table = $info->{source};
        $fr_table =~ s/.*\:([^\:]+)$/$1/;

        my $fr_col = (keys %{$info->{cond}})[0];
        $fr_col =~ s/^foreign\.//;

        my $col = (values %{$info->{cond}})[0];
        $col =~ s/^self\.//;

        if ( 0 ) {
            $self->dumper( $c, [ $info ], "rels: $col ($rel_name) --> $fr_table.$fr_col ... " );
        }

        $rels->{$col} = [ $fr_table, $fr_col ];
    }
    return $rels;
}


sub prepare_data_orserr {
    my ( $self, $c, $schema, $table_name, $cols_allowed, $pr ) = @_;

    # only page num - show page
    # only id
    # * if complex searh -> find page with id, show page and highlight id
    # * else -> only one id
    # page num and id - show page and highlight id

    my $use_complex_search_by_id = $self->use_complex_search_by_id();
    my $rs;

    my $search_type = undef;
    my $search_conf = {
        columns => $cols_allowed,
        rows => $pr->{rows},
    };

    my $primary_cols = [ $schema->source($table_name)->primary_columns ];
    my $page_navigation_params_part_prefix = '';

    if ( defined $pr->{selected_ids} ) {

        $search_conf->{where} = {};

        # komplex search for page or page already defined by param
        if ( $use_complex_search_by_id || $pr->{page} ) {
            $search_type = 'one row';

            if ( $pr->{page} ) {
                $search_conf->{page} = $pr->{page};

            } else {
                my $pn_search_conf = { %$search_conf };
                $pn_search_conf->{where} = {};
                my $num = 0;
                foreach my $pr_col_name ( @$primary_cols ) {
                    $pn_search_conf->{where}->{$pr_col_name} = { '<=', $pr->{selected_ids}->[ $num ] };
                    $num++;
                }
                $pn_search_conf->{page} = 1;

                $self->dumper( $c, [ { pr => $pr, search_conf => $pn_search_conf } ], 'find page num select ' );
                my $rs_find_page_num = $c->model($self->db_schema_base_class_name.'::'.$table_name)->search( undef, $pn_search_conf );

                $search_conf->{page} = $rs_find_page_num->pager->last_page;
                $pr->{page} = $rs_find_page_num->pager->last_page;
            }

            my $num = 0;
            foreach my $pr_col_name ( @$primary_cols ) {
                $page_navigation_params_part_prefix .= 'id-' . $pr->{selected_ids}->[ $num ];
                $num++;
            }


        } else {
            $search_type = 'one row';

            my $num = 0;
            foreach my $pr_col_name ( @$primary_cols ) {
                $search_conf->{where}->{$pr_col_name} = $pr->{selected_ids}->[ $num ];
                $num++;
            }
            $search_conf->{page} = 1;
            $pr->{page} = 1;
        }

    } else {
        $pr->{page} = 1 unless defined $pr->{page};

        $search_type = 'page';
        $search_conf->{page} = $pr->{page};
    };

    $self->dumper( $c, [ { pr => $pr, search_conf => $search_conf } ], 'final select ' );
    $rs = $c->model($self->db_schema_base_class_name.'::'.$table_name)->search( undef, $search_conf );
    if ( $pr->{page} > $rs->pager->last_page && $rs->pager->last_page > 0 ) {
        $pr->{page} = $rs->pager->last_page;
        # redirect
        my $uri = $c->uri_for( $table_name, 'page-'.$pr->{page} );
        $c->response->redirect( $uri );
        return;
    }

    my @rows = ();
    while (my $row = $rs->next) {
        my $id_uri_part = 'id';
        $id_uri_part .= '-' . $row->get_column($_) foreach @$primary_cols;
        my $row_data = { $row->get_columns };
        my $row_info = {
            data => $row_data,
            uri => $c->uri_for( $table_name, $id_uri_part )->as_string,
        };
        if ( defined $pr->{selected_ids} ) {
            if ( scalar @{$pr->{selected_ids}} > 1 ) {
                # TODO
            } else {
                $row_info->{selected} = 1 if $row_data->{ $primary_cols->[0] } == $pr->{selected_ids}->[0];
            }
        }
        push @rows, $row_info;
    }
    $c->stash->{rows} = \@rows;

    unless ( scalar @rows ) {
        if ( $search_type eq 'one row' ) {
            $c->stash->{data_error} = 'Item not found.';
            return 0;
        }
        if ( $search_type eq 'page' ) {
            $c->stash->{data_error} = 'Table is empty.';
            return 0;
        }
    }

    my $params_part = '';
    $params_part .= $page_navigation_params_part_prefix . ',' if $page_navigation_params_part_prefix;
    $params_part .= 'page-';
    $self->dumper( $c, [ $params_part ] );
    my $page_uri_prefix = $c->uri_for( $table_name, $params_part )->as_string;
    $c->stash->{pager_html} = get_pager_html( $rs->pager, $page_uri_prefix );
    return 1;
}


sub default_rs_uri_for_related {
    my ( $self, $c ) = @_;

    my $action_ns = $c->action->namespace;
    return sub {
        my ( $rel_data, $id ) = @_;
        return $c->uri_for( '/' . $action_ns, $rel_data->[0], 'id-'.$id )->as_string;
    };
}

sub col_names_to_titles {
    my ( $self, $ra ) = @_;

    my @titles = ();
    foreach my $name ( @$ra ) {
        my $title = $name;
        $title =~ s/_/ /g;
        #$title = ucfirst( $title );
        #$title =~ s/id$/ID/;
        push @titles, $title;
    }
    return \@titles;
}


=head1 SEE ALSO

L<Catalyst::Controller>, L<DBIx::Class::ViewMD>

=head1 AUTHOR

Michal Jurosz <mj@mj41.cz>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
