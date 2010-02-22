package CatalystX::Controller::CWebMagic;

use strict;
use warnings;
use base 'Catalyst::Controller';

our $VERSION = '0.004';

use Data::Page::HTML;
use Data::Dumper; # TODO - needed only for debug mode

=head1 NAME

CatalystX::Controller::CWebMagic - Base CWebMagic CatalysX Controller

=head1 SYNOPSIS

  package MyProject::Web::Controller::CWM;
  use base 'CatalystX::Controller::CWebMagic';

  sub db_schema_base_class_name {
      return 'WebDB';
  }

  sub db_schema_class_name {
      return 'MyProject::Web::Model::WebDB';
  }

  sub index : Path  {
      my $self = shift;
      return $self->base_index( @_ );
  }

  1;

=head1 DESCRIPTION

Use database schema (L<DBIx::Class>) with (L<DBIx::Class::CWebMagic>) metadata
to see web magic in your L<Catalyst> application.

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


sub get_prepare_conf {
    my ( $self, $c ) = @_;

    return {};

    # Testing
    return {
        # 'skip_tables' => [ 'log', ],
        # 'these_tables' => [ 'mconf_sec_kv', 'mconf_sec', 'mconf', ],
        # 'cwm_conf' => {
        #    'mconf_change' => {
        #        'date' => 'G',
        #    },
        #},
    };
}


sub debug_suffix {
    my ( $self, $msg, $caller_back ) = @_;
    $caller_back = 1 unless defined $caller_back;

    $msg =~ s/[\n\s]+$//;

    my $has_new_line = 0;
    $has_new_line = 1 if $msg =~ /\n/;

    my $caller_line = (caller 0+$caller_back)[2];
    my $caller_sub = (caller 1+$caller_back)[3];
    $caller_sub =~ s{^CatalystX?\:\:([^\:]+)\:\:}{};

    $msg .= " ";
    $msg .= "(" unless $has_new_line;
    $msg .= "$caller_sub on line $caller_line";
    $msg .= ')' unless $has_new_line;
    $msg .= ".\n";
    $msg .= "\n" if $has_new_line;
    return $msg;
}


sub dump {
    my ( $self, $c, $prefix_text, $data, $caller_back ) = @_;

    return unless $c->log->is_debug;

    if ( (not defined $data) && $prefix_text =~ /^\n$/ ) {
        $c->stash->{ot} .= $prefix_text;
        return 1;
    }

    $caller_back = 0 unless defined $caller_back;
    if ( defined $prefix_text ) {
        $prefix_text .= ' ';
    } else {
        $caller_back = 0;
        $prefix_text = '';
    }

    my $ot = $prefix_text;
    if ( defined $data ) {
        local $Data::Dumper::Indent = 1;
        local $Data::Dumper::Purity = 1;
        local $Data::Dumper::Terse = 1;
        local $Data::Dumper::Sortkeys = 1;
        $ot .= Data::Dumper->Dump( [ $data ], [] );
    }

    if ( $caller_back >= 0 ) {
        $ot = $self->debug_suffix( $ot, $caller_back+1 );
    }

    $c->stash->{ot} .= $ot;
    return 1;
}


sub dump_rs {
    my ( $self, $c, $rs ) = @_;

    return unless $c->log->is_debug;

    my $chunk = $rs->as_query;
    my $nice_sql = $$chunk->[0];

    $nice_sql =~ s{SELECT }{   SELECT }gs;
    $nice_sql =~ s{ LEFT JOIN }{\nLEFT JOIN }gs;
    $nice_sql =~ s{ (?<!LEFT )JOIN }{\n     JOIN }gs;
    $nice_sql =~ s{ ON }{\n       ON }gs;
    $nice_sql =~ s{ AND }{\n      AND }gs;
    $nice_sql =~ s{ WHERE }{  WHERE }gs;
    $nice_sql =~ s{ORDER BY}{\n    ORDER BY}gs;
    $nice_sql =~ s{LIMIT}{\n    LIMIT}gs;

    $nice_sql =~ s{\,}{\,\n         }gs;
    $nice_sql =~ s{\n+}{\n}gs;

    $nice_sql =~ s{^\(}{\n}gs;
    $nice_sql =~ s{\)$}{\n}gs;


    $self->dump( $c, 'sql', $nice_sql, 1 );
    $self->dump( $c, 'bind', $$chunk->[1], 1 );
    return 1;
}


sub warn {
    my ( $self, $c, $msg ) = @_;
    $msg = '' unless defined $msg;

    $msg = "[!!!] Warning: " . $msg;
    $msg = $self->debug_suffix( $msg, 2 );
    warn( $msg );

    return 1 unless $c->log->is_debug;

    $c->stash->{ot} .= $msg;
    return 1;
}


sub get_cwm_types_to_select {
    my ( $self ) = @_;
    return {
        'G' => 1,
        'S' => 1,
        'CG' => 1,
        'CS' => 1,
        'D' => 1,
    };
}


sub get_cwm_types_to_colspan {
    my ( $self ) = @_;
    return {
        'G' => 1,
        'CG' => 1,
    };
}


sub _rec_get_base_cwm_configs {
    my (
        $self,
        $c, $schema, $table_name, $cwm_conf, $search_conf,
        $view_conf, $rel_name, $tmp, $deep
    ) = @_;

    my $debug = 0;

    my $cols_allowed = [ $self->get_allowed_cols( $c, $schema, $table_name ) ];

    my ( $ar_primary_cols, $primary_cols ) = $self->get_primary_cols( $c, $schema, $table_name );

    my $foreign_cols = $self->get_foreign_cols( $c, $schema, $table_name );

    my $cwm_types_to_select = $self->get_cwm_types_to_select();
    my $cwm_types_to_colspan = $self->get_cwm_types_to_colspan();

    unless ( defined $view_conf->{levels}->[ $deep ] ) {
        $view_conf->{levels}->[ $deep ] = [];
    }

    my $alias_name = $rel_name;
    if ( exists $tmp->{alias}->{$alias_name} ) {
        $alias_name .= '_2';
        while ( exists $tmp->{alias}->{$alias_name} ) {
            # ToDo
            $alias_name = $alias_name++;
        }
        $self->dump($c, "alias: '$alias_name'");
    }
    $tmp->{alias}->{$alias_name} = $rel_name;
    unless ( defined $tmp->{offsets}->[ $deep ] ) {
        $tmp->{offsets}->[ $deep ] = $tmp->{offsets}->[ $deep-1 ];
    }

    $view_conf->{primary_cols}->{$alias_name} = $ar_primary_cols;


    my $join = undef;
    my $col_num = 0;
    my $colspan = 0;

    foreach my $cn ( @$cols_allowed ) {
        unless ( exists $cwm_conf->{$table_name}->{$cn} ) {
            $self->warn( $c, "cwm_conf not found for table:'$table_name', col:'$cn'" );
            next;
        }

        my $col_cwm_type = $cwm_conf->{$table_name}->{$cn};
        next unless exists $cwm_types_to_select->{ $col_cwm_type };

        my $full_col_name = $alias_name.'.'.$cn;
        push @{ $search_conf->{select} }, $full_col_name;

        my $full_col_num = $#{ $search_conf->{select} };
        $view_conf->{sel_cpos}->{$full_col_name} = $full_col_num;
        push @{ $search_conf->{as} }, $alias_name.'_'.$cn;

        my $view_item_conf = {
            alias_name => $alias_name,
            table_name => $table_name,
            col_name => $cn,
            deep => $deep,
        };

        if ( $debug ) {
            $view_item_conf->{_cwm_type} = $col_cwm_type;
        }


        my $is_foreign = 0;
        my $foreign_to_self = 0;
        if ( exists $foreign_cols->{$cn} ) {
            next if exists $tmp->{table}->{$table_name}->{$cn};
            $tmp->{table}->{$table_name}->{$cn} = 1;

            my ( $fr_table, $fr_col, $fr_rel_name ) = @{ $foreign_cols->{$cn} };
            next unless exists $cwm_conf->{$fr_table};
            $self->dump( $c, "$deep $table_name.$cn ($col_cwm_type)" );

            if ( $fr_table eq $table_name ) {
                $foreign_to_self = 1;
                $view_item_conf->{foreign_table_name} = $fr_table;
                $view_item_conf->{foreign_as_normal} = 1;

            } elsif ( $deep >= 2 ) {
                $view_item_conf->{foreign_table_name} = $fr_table;
                $view_item_conf->{foreign_limit} = 1;

            } else {
                my ( $fr_join, $fr_colspan, $fr_colspan_sum ) = $self->_rec_get_base_cwm_configs(
                    $c, $schema, $fr_table, $cwm_conf, $search_conf,
                    $view_conf, $fr_rel_name, $tmp, $deep + 1
                );

                $is_foreign = 1;
                $colspan += $fr_colspan_sum;
                $view_item_conf->{foreign_table_name} = $fr_table;
                $view_item_conf->{colspan} = $fr_colspan_sum;
                $view_item_conf->{_fr_colspan} = $fr_colspan;

                unless ( defined $join ) {
                    $join = $fr_join;
                } else {
                    $join = [ $join ] unless ref $join eq 'ARRAY';
                    push @$join, $fr_join;
                }
            }
        }

        if ( ( $foreign_to_self && $col_cwm_type ne 'S' )
             || exists $primary_cols->{$cn}
             || exists $cwm_types_to_colspan->{ $col_cwm_type }
             || ( $col_cwm_type eq 'S' && $view_conf->{primary_table_name} eq $table_name )
        ) {
            $view_item_conf->{show} = 1;
            my $index = $tmp->{offsets}->[ $deep ];
            if ( $view_conf->{levels}->[ $deep ]->[ $index ] ) {
                $self->dump( $c, "going to rewrite $deep -> $index by $view_item_conf->{col_name}" );
            }
            $view_conf->{levels}->[ $deep ]->[ $index ] = $view_item_conf;

            if ( $debug && $deep <= 10 ) {
                my $sum = $tmp->{offsets}->[ $deep ];
                $self->dump( $c, "$deep -> $sum ($col_num) $view_item_conf->{col_name} -- colspan $colspan -- is_foreign $is_foreign" );
                #$self->dump( $c, '$view_item_conf', $view_item_conf );
                #$self->dump( $c, '$view_conf->{levels}', $view_conf->{levels} );
                #$self->dump( $c, "\n" );
            }

            $tmp->{offsets}->[ $deep ]++;

            $col_num++;
            unless ( $is_foreign ) {
                $colspan++;
                if ( $col_num > 0 ) {
                    my $max_deep = $#{ $tmp->{offsets} };
                    foreach my $tmp_deep ( $deep+1..$max_deep ) {
                        $tmp->{offsets}->[ $tmp_deep ]++;
                    }
                }
            }
        }

        unless ( $is_foreign ) {
            push @{ $view_conf->{cols} }, $view_item_conf;
        }

    }


    if ( $deep > 0 ) {
        unless ( defined $join ) {
            $join = $rel_name;
        } else {
            $join = { $rel_name => $join, };
        }
    }

    #$self->dump( $c, "finish deep $deep, \$tmp->{offsets}", $tmp->{offsets} );

    return ( $join, $col_num, $colspan );
}


sub get_base_cwm_configs {
    my ( $self, $c, $schema, $table_name, $cwm_conf, $debug ) = @_;

    my $use_row_spans = 1;

    my $search_conf = {
        select => [],
        as => [],
    };

    my $view_conf = {
        levels => [],
        cols => [],
        col_nums => {},
        primary_cols => {},
        primary_table_name => $table_name,
        use_row_spans => $use_row_spans,
    };
    my $tmp = {
        'alias' => {},
        'table' => {},
        'offsets' => [ 0 ],
    };

    my ( $join, $col_num, $colspan ) = $self->_rec_get_base_cwm_configs(
        $c, $schema, $table_name, $cwm_conf, $search_conf,
        $view_conf, 'me', $tmp, 0,
    );
    $search_conf->{join} = $join if defined $join;


    # Fill $view_conf->levels with remaining undefs.
    my $level0_colspan_sum = 0;
    my $level_conf = $view_conf->{levels}->[0];
    foreach my $lc ( @$level_conf ) {
        if ( exists $lc->{colspan} ) {
            $level0_colspan_sum += $lc->{colspan};
            next;
        }
        $level0_colspan_sum++;
    }
    $view_conf->{all_colspan_sum} = $level0_colspan_sum;

    my $last_deep_index = $#{ $view_conf->{levels} };
    foreach my $deep ( 1..$last_deep_index ) {

        my $level_conf = $view_conf->{levels}->[ $deep ];
        my $colspan = 0;
        foreach my $lc ( @$level_conf ) {
            if ( exists $lc->{colspan} ) {
                $colspan += $lc->{colspan};
                next;
            }
            $colspan++;
        }

        #$self->dump( $c, "deep $deep : $colspan $level0_colspan_sum" );
        foreach my $num ( $colspan..$level0_colspan_sum-1 ) {
            push @{ $view_conf->{levels}->[ $deep ] }, {};
        }
    }

    if ( $use_row_spans ) {
        foreach my $deep ( 0..$last_deep_index-1 ) {
            my $level_conf = $view_conf->{levels}->[ $deep ];
            foreach my $lc_num ( 0..$#$level_conf ) {
                my $lc = $level_conf->[ $lc_num ];
                next unless %$lc;
                next if exists $lc->{foreign_table_name} && (not exists $lc->{foreign_as_normal});
                my $rowspan = $last_deep_index - $deep + 1;
                $self->dump($c,"$deep $lc_num $lc->{col_name}, rowspan $rowspan\n");
                $lc->{rowspan} = $rowspan;
            }
        }
    }

    $self->dump( $c, '$view_conf->{levels}', $view_conf->{levels} );


    if ( $debug || $c->log->is_debug ) {
        #$self->dump( $c, '$cwm_conf', $cwm_conf );
        $self->dump( $c, '$search_conf', $search_conf );
        $self->dump( $c, '$view_conf', $view_conf );
        $self->dump( $c, '$view_conf->levels', $view_conf->{levels} );
        $self->dump( $c, '$view_conf->cols', $view_conf->{cols} );
        $self->dump( $c, '$tmp', $tmp );
    }

    return ( $search_conf, $view_conf );
}


sub get_header_html {
    my ( $self, $c, $schema, $view_conf ) = @_;

    my $levels = $view_conf->{levels};

    my $html = '';
    foreach my $level_num ( 0..$#$levels ) {
        $html .= "<tr>\n";
        foreach my $col_conf ( @{ $levels->[$level_num]} ) {
            next if $view_conf->{use_row_spans} && not %$col_conf;
            next if exists $col_conf->{show} && not $col_conf->{show};

            $html .=
                '<th'
                . ( exists $col_conf->{colspan} ? ' colspan="'.$col_conf->{colspan}.'"' : '' )
                . ( exists $col_conf->{rowspan} ? ' rowspan="'.$col_conf->{rowspan}.'"' : '' )
                . '>'
            ;

            my $val = $col_conf->{col_name} || '&nbsp;';
            if ( exists $col_conf->{colspan} ) {
                my $fr_table_uri = $c->uri_for( $col_conf->{foreign_table_name},  )->as_string;
                $val = '<a href="' . $fr_table_uri . '">' . $val . '</a>';
            }

            $html .= $val;
            $html .= "</th>\n";

            #$self->dump( $c, "col_conf level $level_num", $col_conf );
        }
        $html .= "</tr>\n";
    }
    return $html;
}


sub get_content_html {
    my ( $self, $c, $schema, $table_name, $view_conf, $rows, $pr ) = @_;

    my $html = '';

    my $main_primary_cols = $view_conf->{primary_cols}->{me};

    my $css_class_name = 'even';
    foreach my $row_num ( 0..$#$rows ) {
        my $row_data = $rows->[ $row_num ];
        my $uris_done = {};

        my $row_is_selected = 0;
        if ( defined $pr->{selected_ids} ) {
            if ( scalar @{$pr->{selected_ids}} > 1 ) {
                # ToDo - more then one primary key
            } else {
                my $sel_cpos = $view_conf->{sel_cpos}->{ 'me.'. $main_primary_cols->[0] };
                if ( $row_data->[ $sel_cpos ] == $pr->{selected_ids}->[0] ) {
                    $row_is_selected = 1;
                }
            }
        }

        $html .=
            '<tr class="'
            . $css_class_name
            . ( $row_is_selected ? ' marked' : '' )
            . '">'
            . "\n"
        ;
        foreach my $vc ( @{ $view_conf->{cols} } ) {
            next if $view_conf->{use_row_spans} && not %$vc;
            next unless $vc->{show};

            my $alias_name = $vc->{alias_name};
            my $col_name = $alias_name . '.' . $vc->{col_name};
            my $sel_cpos = $view_conf->{sel_cpos}->{ $col_name };
            my $val = $row_data->[ $sel_cpos ] || '&nbsp;';

            if ( $table_name ne $vc->{table_name} && not exists $uris_done->{$alias_name} ) {
                my $primary_cols = $view_conf->{primary_cols}->{$alias_name};
                my $id_uri_part = 'id';
                foreach my $col_name ( @$primary_cols ) {
                    my $id = $row_data->[ $view_conf->{sel_cpos}->{$alias_name.'.'.$col_name} ];
                    $id_uri_part .= '-' . $id if $id;
                }
                my $row_uri = $c->uri_for( $vc->{table_name}, $id_uri_part )->as_string;
                if ( $row_uri ) {
                    $val = '<a href="' . $row_uri . '">' . $val . '</a>';
                }
                $uris_done->{$alias_name} = 1;
            }

            $html .= '<td>';
            $html .= $val;
            $html .= "</td>\n";
        }
        $html .= "</tr>\n";

        if ( $css_class_name eq 'even' ) {
            $css_class_name = 'odd';
        } else {
            $css_class_name = 'even';
        }
    }

    return $html;
}



sub base_index  {
    my ( $self, $c, $table_name, @args ) = @_;

    $c->stash->{ot} = '';

    # show table list
    return $self->show_table_list( $c ) if !$table_name;

    # show table data
    $c->stash->{template} = 'cwm/data.tt2';
    $c->stash->{table_name} = $table_name;
    $c->stash->{index_uri} = $c->uri_for()->as_string,

    # user defined parameters (another one is table_name)
    my $pr = {
        rows => 15,
        page => undef,
        selected_ids => undef,
    };
    $self->set_pr( $pr, $args[0] ) if $args[0];
    # $self->dump( $c, '$pr', $pr );

    my $schema = $self->get_schema( $c );
    $self->is_table_orserr( $c, $schema, $table_name ) or return;

    $c->stash->{msgs} = [];

    # todo - do once (in "compile stage") only
    $self->init_default_cwm_config( $c, $schema );

    my $prepare_conf = $self->get_prepare_conf( $c );

    my ( $ar_primary_cols, $primary_cols ) = $self->get_primary_cols( $c, $schema, $table_name );
    my $cwm_conf = $self->prepare_own_cwm_conf( $c, $schema, $prepare_conf, $table_name, $primary_cols );


    my $use_complex_search_by_id = $self->use_complex_search_by_id();

    # debug - testing
    # 0 .. no debug
    # 1 .. do not run sql
    # 2 .. run sql, but show only query
    my $sql_prepare_debug = 0;
    my ( $search_conf, $view_conf ) = $self->get_base_cwm_configs(
        $c, $schema, $table_name, $cwm_conf, $sql_prepare_debug
    );


    my @me_ar_primary_cols = ();
    foreach my $cn ( @$ar_primary_cols ) {
        push @me_ar_primary_cols, 'me.'. $cn;
    }
    $search_conf->{order_by} = \@me_ar_primary_cols;


    $search_conf->{rows} = $pr->{rows};

    my $page_navigation_params_part_prefix = '';

    my $search_type = undef;
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
                foreach my $pr_col_name ( @me_ar_primary_cols ) {
                    $pn_search_conf->{where}->{$pr_col_name} = { '<=', $pr->{selected_ids}->[ $num ] };
                    $num++;
                }
                $pn_search_conf->{page} = 1;

                $self->dump( $c, [ { pr => $pr, search_conf => $pn_search_conf } ], 'find page num select ' );
                my $rs_find_page_num = $c->model($self->db_schema_base_class_name.'::'.$table_name)->search( undef, $pn_search_conf );

                $search_conf->{page} = $rs_find_page_num->pager->last_page;
                $pr->{page} = $rs_find_page_num->pager->last_page;
            }

            my $num = 0;
            foreach my $pr_col_name ( @me_ar_primary_cols ) {
                $page_navigation_params_part_prefix .= 'id-' . $pr->{selected_ids}->[ $num ];
                $num++;
            }


        } else {
            $search_type = 'one row';

            my $num = 0;
            foreach my $pr_col_name ( @me_ar_primary_cols ) {
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

    return 1 if $sql_prepare_debug == 1; # debug

    my $rs = $c->model($self->db_schema_base_class_name.'::'.$table_name)->search( undef, $search_conf );
    # debug
    if ( $sql_prepare_debug == 2 ) {
        $self->dump_rs( $c, $rs );
        return 1;
    }


    if ( $pr->{page} > $rs->pager->last_page && $rs->pager->last_page > 0 ) {
        $pr->{page} = $rs->pager->last_page;
        # redirect
        my $uri = $c->uri_for( $table_name, 'page-'.$pr->{page} );
        $c->response->redirect( $uri );
        return 1;
    }



    my $rows = [ $rs->cursor->all ];
    #$self->dump( $c, 'rows', $rows );

    my $header_html = $self->get_header_html( $c, $schema, $view_conf );
    my $content_html = $self->get_content_html( $c, $schema, $table_name, $view_conf, $rows, $pr );

    $c->stash->{table_header_html} = $header_html;
    $c->stash->{table_content_html} = $content_html;

    $c->stash->{rows} = $rows;

    $c->stash->{col_names} = $search_conf->{as};

    $c->stash->{all_colspan_sum} = $view_conf->{all_colspan_sum};
    unless ( scalar @$rows ) {
        if ( $search_type eq 'one row' ) {
            $c->stash->{data_error} = 'Item not found.';
            return 0;
        }
        if ( $search_type eq 'page' ) {
            $c->stash->{data_error} = 'Table is empty.';
            return 0;
        }
    }

    $c->stash->{uri_for_related} = $self->default_rs_uri_for_related( $c );
    #$c->stash->{data_for_related} = $self->default_rs_data_for_related( $c, $rels, $ft_data_conf );

    my $params_part = '';
    $params_part .= $page_navigation_params_part_prefix . ',' if $page_navigation_params_part_prefix;
    $params_part .= 'page-';
    $self->dump( $c, [ $params_part ] );
    my $page_uri_prefix = $c->uri_for( $table_name, $params_part )->as_string;
    $c->stash->{pager_html} = Data::Page::HTML::get_pager_html( $rs->pager, $page_uri_prefix );
    return 1;
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
        # ToDo
        #next if $schema->source($table_name)->{extra};
        next if $table_name =~ /^[A-Z]/;
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
        if ( $part =~ m/^ page[\-\=](\d+) $/x ) {
            $pr->{page} = $1;
            next;
        }
        if ( $part =~ m/^ rows[\-\=](\d+) $/x ) {
            $pr->{rows} = $1;
            next;
        }
        if ( $part =~ m/^ id[\-\=](\S+) $/x ) {
            my $matched = $1;
            if ( $matched =~ /[\-\=]/ ) {
                $pr->{selected_ids} = [ split(/[\-\=]/,$matched) ];
            } else {
                $pr->{selected_ids} = [ $matched ];
            }
            #$self->dump( $c, 'selected_id', \@selected_id );
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


sub get_primary_cols {
    my ( $self, $c, $schema, $table_name ) = @_;
    my $ar_primary_cols = [ $schema->source($table_name)->primary_columns ];
    my $primary_cols = { map { $_ => 1 } @$ar_primary_cols };
    return ( $ar_primary_cols, $primary_cols );
}


sub get_foreign_cols {
    my ( $self, $c, $schema, $table_name ) = @_;

    my $foreign_cols = {};
    my @raw_rels = $schema->source($table_name)->relationships;
    foreach my $rel_name ( @raw_rels ) {
        my $info = $schema->source($table_name)->relationship_info( $rel_name );
        if ( (not defined $info->{attrs}->{join_type}) || $info->{attrs}->{join_type} ne 'LEFT' ) {
            my $fr_table = $info->{source};
            $fr_table =~ s/.*\:([^\:]+)$/$1/;

            my $fr_col = (keys %{$info->{cond}})[0];
            $fr_col =~ s/^foreign\.//;

            my $col = (values %{$info->{cond}})[0];
            $col =~ s/^self\.//;

            $foreign_cols->{ $col } = [ $fr_table, $fr_col, $rel_name ];
        }
    }

    return $foreign_cols;
}


sub get_cols_and_restricted_cols {
    my ( $self, $c, $schema, $table_name ) = @_;

    my $view_class = $self->db_schema_class_name.'::'.$table_name;
    my @cols = $schema->source( $table_name )->columns;

    if ( !$view_class->can('cwm_col_auth') ) {
        my $msg = "CWebMagic for table '$table_name' missing. Try '__PACKAGE__->load_components(qw/CWebMagic/);' inside package '$view_class'.";
        $c->stash->{error} = $msg;
        return undef;
    }

    my $restricted_cols = $view_class->cwm_col_auth;
    foreach my $col_name ( keys %$restricted_cols ) {
        # R - restricted
        if ( $restricted_cols->{$col_name} ne 'R' ) {
            delete $restricted_cols->{$col_name};
        }
    }

    return ( \@cols, $restricted_cols );
}


sub get_allowed_cols {
    my ( $self, $c, $schema, $table_name ) = @_;

    my ( $cols, $restricted_cols ) = $self->get_cols_and_restricted_cols( $c, $schema, $table_name );

    my @msgs = ();
    my @cols_allowed;
    if ( $restricted_cols ) {
        my $msg = '';
        @cols_allowed = ();
        my @temp_cols_restricted = ();
        foreach my $col ( @$cols ) {
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
        @cols_allowed = @$cols;
    }
    return @cols_allowed;
}


sub get_rels {
    my ( $self, $c, $schema, $table_name ) = @_;

    my $rels = {};
    my @raw_rels = $schema->source($table_name)->relationships;
    $self->dump( $c, 'raw rels', \@raw_rels );
    foreach my $rel_name ( @raw_rels ) {
        my $info = $schema->source($table_name)->relationship_info( $rel_name );
        $self->dump( $c, "raw rel info for '$rel_name'", $info );

        my $fr_table = $info->{source};
        $fr_table =~ s/.*\:([^\:]+)$/$1/;

        my $fr_col = (keys %{$info->{cond}})[0];
        $fr_col =~ s/^foreign\.//;

        my $col = (values %{$info->{cond}})[0];
        $col =~ s/^self\.//;

        my $type;
        if ( defined $info->{attrs}->{join_type} && $info->{attrs}->{join_type} eq 'LEFT' ) {
            # many foreign tables columns can poin to one self column
            $type = 'in';
            $rels->{in} = [] unless defined $rels->{in};
            push @{$rels->{in}}, [ $col, $fr_table, $fr_col ];
        } else {
            # one self column can point only to one foreign table column
            $type = 'out';
            $rels->{out}->{$col} = [ $fr_table, $fr_col ];
        }

        #$self->dump( $c, "rel $type: $col ($rel_name) --> $fr_table.$fr_col ... ", $info );
    }

    return $rels;
}


sub init_default_cwm_config {
    my ( $self, $c, $schema, $in_cwm_conf ) = @_;

    my $cwm_conf = {};
    my @tables = $schema->sources;


    my $default_col_types = {
        'first_name' => 'G',
        'last_name' => 'G',
        'login' => 'G',
        'name' => 'G',

        'passwd' => 'R',
        'password' => 'R',
    };

    foreach my $table_name ( sort @tables ) {
        # ToDo
        # next if $schema->source($table_name)->{extra};
        next if $table_name =~ /^[A-Z]/;

        my ( $ar_primary_cols, $primary_cols ) = $self->get_primary_cols( $c, $schema, $table_name );
        my $foreign_cols = $self->get_foreign_cols( $c, $schema, $table_name );
        my ( $cols, $restricted_cols ) = $self->get_cols_and_restricted_cols( $c, $schema, $table_name );

        my $view_class = $self->db_schema_class_name.'::'.$table_name;
        my $schema_col_types = $view_class->cwm_col_type;

        foreach my $col_name ( @$cols ) {
            if ( exists $restricted_cols->{ $col_name } ) {
                $cwm_conf->{ $table_name }->{ $col_name } = 'R';

            } elsif ( exists $in_cwm_conf->{ $table_name }->{ $col_name } ) {
                $cwm_conf->{ $table_name }->{ $col_name } = $in_cwm_conf->{ $table_name }->{ $col_name };

            } elsif ( exists $schema_col_types->{ $col_name } ) {
                $cwm_conf->{ $table_name }->{ $col_name } = $schema_col_types->{ $col_name };

            } elsif ( exists $primary_cols->{ $col_name } ) {
                $cwm_conf->{ $table_name }->{ $col_name } = 'S';

            } elsif ( exists $foreign_cols->{ $col_name } ) {
                if ( $foreign_cols->{ $col_name }->[0] eq $table_name ) {
                    $cwm_conf->{ $table_name }->{ $col_name } = 'S';
                } else {
                    $cwm_conf->{ $table_name }->{ $col_name } = 'G';
                }

            } elsif ( exists $default_col_types->{ $col_name } ) {
                $cwm_conf->{ $table_name }->{ $col_name } = $default_col_types->{ $col_name };

            } else {
                $cwm_conf->{ $table_name }->{ $col_name } = 'S';
            }
        }
    }

    #$self->dump( $c, 'default cwm_conf', $cwm_conf );
    $self->{cwm_conf} = $cwm_conf;
    return 1;
}


sub prepare_own_cwm_conf {
    my ( $self, $c, $schema, $prepare_conf, $table_name, $primary_cols ) = @_;

    return $self->{cwm_conf} unless $prepare_conf;

    # ToDo
    my $cwm_conf = {};
    my $tables = undef;
    if ( exists $prepare_conf->{these_tables} ) {
        $tables = $prepare_conf->{these_tables};
    } else {
        $tables = [ keys %{ $self->{cwm_conf} } ];
    }

    my $skip_tables = {};
    foreach my $table_name (@{ $prepare_conf->{skip_tables} } ) {
       $skip_tables->{ $table_name } = 1;
    }
    foreach my $table_name ( @$tables ) {
        next if exists $skip_tables->{ $table_name };
        foreach my $col_name ( keys %{ $self->{cwm_conf}->{ $table_name } } ) {
            if ( exists $prepare_conf->{cwm_conf}->{ $table_name }->{ $col_name } ) {
                $cwm_conf->{ $table_name }->{ $col_name } = $prepare_conf->{cwm_conf}->{ $table_name }->{ $col_name };

            } elsif ( exists $primary_cols->{ $col_name } ) {
                $cwm_conf->{ $table_name }->{ $col_name } = 'G';

            } else {
                $cwm_conf->{ $table_name }->{ $col_name } = $self->{cwm_conf}->{ $table_name }->{ $col_name };
            }
        }
    }

    return $cwm_conf;
}


sub default_rs_uri_for_related {
    my ( $self, $c ) = @_;

    my $action_ns = $c->action->namespace;
    return sub {
        my ( $type, $rel_data, $id ) = @_;
        if ( $type eq 'out' ) {
            return $c->uri_for( '/' . $action_ns, $rel_data->[0], 'id-'.$id )->as_string;
        }
        return $c->uri_for( '/' . $action_ns, $rel_data->[1] )->as_string;
    };
}


sub default_rs_data_for_related {
    my ( $self, $c, $rels, $ft_data_conf ) = @_;

    return sub {
        my ( $self_col_name, $row ) = @_;
        my $fr_table_name = $rels->{out}->{$self_col_name}->[0];
        my $fr_col_name = $rels->{out}->{$self_col_name}->[1];

        if ( not $ft_data_conf->{ $self_col_name } ) {
            return $row->{'me_'.$self_col_name};
        }

        my $ft_cols_sub = $ft_data_conf->{ $self_col_name }->[0];
        my $ra_ft_cols = $ft_data_conf->{ $self_col_name }->[1];
        my @data = ();
        foreach my $ft_col_name ( @$ra_ft_cols ) {
            my $ft_col_name_as = $ft_col_name;
            push @data, $row->{$ft_col_name_as};
        }
        my $text = '';
        my $num = 0;
        foreach my $val ( @data ) {
            $text .= ' ' if $num > 0;
            if ( defined $val ) {
                $text .= $val;
            } else {
                $text .= '-';
            }
            $num++;
        }
        return $text;
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

L<Catalyst::Controller>, L<DBIx::Class::CWebMagic>

=head1 AUTHOR

Michal Jurosz <mj@mj41.cz>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
