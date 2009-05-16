package TapTinder::Web::Controller::Report;

use strict;
use warnings;
use base 'TapTinder::Web::ControllerBase';

=head1 NAME

TapTinder::Web::Controller::Report - Catalyst Controller

=head1 DESCRIPTION

Catalyst controller for TapTinder web reports. The actions for reports browsing.

=head1 METHODS

=cut


sub action_do {
    my ( $self, $c ) = @_;

    $self->dumper( $c, $c->request->params );
    my @selected_trun_ids = grep { defined $_; } map { $_ =~ /^trun-(\d+)/; $1; } keys %{$c->request->params};
    #$self->dumper( $c, \@selected_trun_ids );
    unless ( scalar @selected_trun_ids ) {
        $c->stash->{error} = "Please select some test results. One to show failing tests. More to show diff.";
        #$c->response->redirect( ); # TODO
        return;
    }

    if ( scalar(@selected_trun_ids) == 1 ) {
        return $self->action_do_one( $c, $selected_trun_ids[0] );
    }
    return $self->action_do_many( $c, \@selected_trun_ids );
}


sub get_trun_infos {
    my ( $self, $c, $ra_trun_ids ) = @_;

    my $rs_trun_info = $c->model('WebDB::trun')->search(
        {
            trun_id => $ra_trun_ids,
        },
        {
            join => {
                'msjobp_cmd_id' => [
                    'status_id',
                    { msjobp_id => [
                        'jobp_id',
                        { 'rev_id' => 'author_id' },
                        { msjob_id => [
                            { msession_id => { 'machine_id' => 'user_id', }, },
                            'job_id',
                        ], },
                    ], },
                    { 'jobp_cmd_id' => 'cmd_id' },
                ],
            },
            '+select' => [qw/
                rev_id.rev_id rev_id.rev_num rev_id.date rev_id.msg
                author_id.rep_login
                status_id.name status_id.desc
                cmd_id.name jobp_id.name job_id.name
                machine_id.machine_id machine_id.name machine_id.osname machine_id.cpuarch
                user_id.first_name user_id.last_name user_id.login
            /],
            '+as' => [qw/
                rev_id rev_num rev_date rev_msg
                rev_author_rep_login
                mjpc_status mjpc_status_desc
                jobp_cmd_name jobp_name job_name
                machine_id machine_name machine_osname machine_cpuarch
                user_first_name user_last_name user_login
            /],
            order_by => 'rev_id.rev_num',
        }
    );
    my @trun_infos = ();
    while (my $trun_info = $rs_trun_info->next) {
        my %row = ( $trun_info->get_columns() );
        push @trun_infos, \%row;
    }
    #$self->dumper( $c, \@trun_infos );
    return @trun_infos;
}


sub get_ttest_rs {
    my ( $self, $c, $ra_trun_ids ) = @_;

    my $rs = $c->model('WebDB::ttest')->search(
        {
            trun_id => $ra_trun_ids,
        },
        {
            join => [
                { rep_test_id => 'rep_file_id' },
            ],
            '+select' => [qw/
                rep_test_id.rep_file_id
                rep_test_id.number
                rep_test_id.name

                rep_file_id.rep_path_id
                rep_file_id.sub_path
                rep_file_id.rev_num_from
                rep_file_id.rev_num_to
            /],
            '+as' => [qw/
                rep_file_id
                test_number
                test_name

                rep_path_id
                sub_path
                rev_num_from
                rev_num_to
            /],
            order_by => [ 'rep_file_id.sub_path', 'me.rep_test_id' ],
        }
    );
    return $rs;
}


sub get_trest_infos {
    my ( $self, $c ) = @_;

    #$self->dumper( $c, $c->model('WebDB::build') );
    my $rs_trest_info = $c->model('WebDB::trest')->search;
    my %trest_infos = ();
    while (my $trest_info = $rs_trest_info->next) {
        my %row = ( $trest_info->get_columns() );
        $trest_infos{ $trest_info->trest_id } = \%row;
    }
    #$self->dumper( $c, \%trest_infos );
    return %trest_infos;
}


sub action_do_one {
    my ( $self, $c, $trun_id ) = @_;

    my $ra_selected_trun_ids = [ $trun_id ];
    my @trun_infos = $self->get_trun_infos( $c, $ra_selected_trun_ids ) ;
    #$c->stash->{trun_infos} = \@trun_infos;

    my $rs = $self->get_ttest_rs( $c, $ra_selected_trun_ids ) ;
    my @ress = ();
    while (my $res_info = $rs->next) {
        my %row = ( $res_info->get_columns() );

        my $to_base_report = 0;
        my $trest_id = $row{trest_id};
        # 1 not seen, 2 failed, 5 bonus
        $to_base_report = 1 if $trest_id == 1 || $trest_id == 2 || $trest_id == 5;
        next unless $to_base_report;

        my %res = (
            $row{trun_id} => $trest_id,
        );

        delete $row{trest_id};
        delete $row{trun_id};
        push @ress, {
            file => { %row },
            results => { %res },
        };
    }

    $self->dumper( $c, \@ress );
    $c->stash->{ress} = \@ress;

    my %trest_infos = $self->get_trest_infos( $c ) ;
    $c->stash->{trest_infos} = \%trest_infos;

    $c->stash->{template} = 'report/diff.tt2';
    return;
}


sub action_do_many {
    my ( $self, $c, $ra_selected_trun_ids ) = @_;

    my @trun_infos = $self->get_trun_infos( $c, $ra_selected_trun_ids ) ;
    $c->stash->{trun_infos} = \@trun_infos;
    $self->dumper( $c, \@trun_infos );

    # Get all ttest and related rep_test and rep_file info from database.
    # Ok results aren't saved.
    my $rs = $self->get_ttest_rs( $c, $ra_selected_trun_ids ) ;

    my @ress = ();
    my $prev_rt_id = 0;
    my %res_cache = ();
    my %res_ids_sum = ();
    my $num_of_res = scalar @$ra_selected_trun_ids;
    my %row;
    my %prev_row = ();
    my $same_rep_path_id = 1;
    # $rs is ordered by ttest.rep_test_id


    # We need $prev_row, $row and info if next row will be defined.
    my $res = undef;
    my $res_next = $rs->next;
    my $num = 1;
    TTEST_NEXT: while ( 1 ) {
        # First run of while loop.
        unless ( defined $res ) {
            # Nothing found.
            last TTEST_NEXT unless defined $res_next;
        }

        # Use previous rs to get row.
        $res = $res_next;
        $self->dumper( $c, $res );
        $res_next = $rs->next;

        if ( defined $res ) {
            %row = ( $res->get_columns() );
            $same_rep_path_id = 0 if %prev_row && $row{rep_path_id} != $prev_row{rep_path_id};
        }

        # Find if results are same.
        if ( (not defined $res) || $prev_rt_id != $row{rep_test_id} ) {
            my $are_same = 1;
            if ( $prev_rt_id ) {
                $are_same = 0 if scalar( keys %res_ids_sum ) > 1;
                if ( $are_same ) {
                    TTEST_SAME: while (  my ( $k, $v ) = each(%res_ids_sum) ) {
                        if ( $num_of_res != $v ) {
                            $are_same = 0;
                            last TTEST_SAME;
                        }
                    }
                }
            }

            # Remember not different results.
            unless ( $are_same ) {
                #$self->dumper( $c, \%res_ids_sum );
                #$self->dumper( $c, \@res_cache );
                delete $prev_row{trest_id};
                delete $prev_row{trun_id};
                #$self->dumper( $c, \%prev_row );

                my $to_base_report = 0;
                foreach my $trun_info ( @trun_infos ) {
                    if ( exists $res_cache{ $trun_info->{trun_id} } ) {
                        my $trest_id = $res_cache{ $trun_info->{trun_id} };
                        # 1 not seen, 2 failed, 5 bonus
                        $to_base_report = 1 if ( $trest_id == 1 || $trest_id == 2 || $trest_id == 5 );
                        next;
                    }
                    if ( $trun_info->{rev_num} >= $prev_row{rev_num_from}
                         && ( !$prev_row{rev_num_to} || $trun_info->{rev_num} <= $prev_row{rev_num_to} )
                       )
                    {
                        $res_cache{ $trun_info->{trun_id} } = 6;

                    } else {
                        $to_base_report = 1;
                    }
                    #my $trun_
                }
                if ( $to_base_report ) {
                    #$self->dumper( $c, \%res_cache );
                    push @ress, {
                        file => { %prev_row },
                        results => { %res_cache },
                    };
                }
            }

            last TTEST_NEXT unless defined $res;

            %prev_row = %row;
            $prev_rt_id = $row{rep_test_id};
            %res_cache = ();
            %res_ids_sum = ();
        }


        # another test
        $res_cache{ $row{trun_id} } = $row{trest_id};
        $res_ids_sum{ $row{trest_id} }++;
        $num++;

    } # TTEST_NEXT: while ( 1 ) {

    $self->dumper( $c, \@ress );
    $c->stash->{same_rep_path_id} = $same_rep_path_id;
    $c->stash->{ress} = \@ress;

    my %trest_infos = $self->get_trest_infos( $c ) ;
    $c->stash->{trest_infos} = \%trest_infos;

    $c->stash->{template} = 'report/diff.tt2';
    return;
}

=head2 index

=cut

sub index : Path  {
    my ( $self, $c, $p_project, $par1, $par2, @args ) = @_;
    my $ot : Stashed = '';

    my ( $is_index, $project_name, $params ) = $self->get_projname_params( $c, $p_project, $par1, $par2 );
    my $pr = $self->get_page_params( $params );

    $c->model('WebDB')->storage->debug(1);

    if ( $is_index ) {
        my $search = { active => 1, };
        $search->{'project_id.name'} = $project_name if $project_name;
        my $rs = $c->model('WebDB::rep')->search( $search,
            {
                join => [qw/ project_id /],
                'select' => [qw/ rep_id project_id.name project_id.url /],
                'as' => [qw/ rep_id name url /],
            }
        );

        my @projects = ();
        my %rep_paths = ();

        while (my $row = $rs->next) {
            my $project_data = { $row->get_columns };

            my $plus_rows = [ qw/ max_rev_num rev_id author_id date rep_login /];

            my $search_conf = {
                '+select' => $plus_rows,
                '+as' => $plus_rows,
                bind  => [ $project_data->{rep_id} ],
                rows  => $pr->{rows} || 15,
            };
            if ( $project_name ) {
                $search_conf->{page} = $pr->{page};
            }
            my $rs_rp = $c->model('WebDB')->schema->resultset( 'ActiveRepPathList' )->search( {}, $search_conf );

            if ( $project_name ) {
                my $base_uri = '/' . $c->action->namespace . '/pr-' . $project_name . '/page-';
                my $page_uri_prefix = $c->uri_for( $base_uri )->as_string;
                $c->stash->{pager_html} = $self->get_pager_html( $rs_rp->pager, $page_uri_prefix );
            }

            my $row_project_name = $project_data->{name};
            $rep_paths{ $row_project_name } = [];

            while (my $row_rp = $rs_rp->next) {
                my $row_rp_data = { $row_rp->get_columns };
                my $path = $row_rp_data->{path};
                $path =~ s{\/$}{};
                my ( $path_nice, $path_report_uri, $path_type );
                my $path_report_uri_base = $c->uri_for( '/' . $c->action->namespace, 'pr-' . $row_project_name, 'rp-' )->as_string;

                # branches, tags
                if ( my ( $bt, $name ) = $path =~ m{^(branches|tags)\/(.*)$} ) {
                    if ( $bt eq 'branches' ) {
                        $path_type = 'branch';
                    } elsif ( $bt eq 'tags' ) {
                        $path_type = 'tag';
                    }
                    $path_nice = $name;

                    $path_report_uri = $path;
                    $path_report_uri =~ s{\/}{-};
                    $path_report_uri = $path_report_uri_base . $path_report_uri;
                # trunk
                } else {
                    $path_type = '';
                    $path_nice = $path;
                    $path_report_uri = $path_report_uri_base . $path;
                }
                $row_rp_data->{path_type} = $path_type;
                $row_rp_data->{path_nice} = $path_nice;
                $row_rp_data->{path_report_uri} = $path_report_uri;
                push @{ $rep_paths{ $row_project_name } }, $row_rp_data;
            }

            push @projects, $project_data;
        }
        $c->stash->{projects} = \@projects;
        $c->stash->{rep_paths} = \%rep_paths;
        $c->stash->{template} = 'report/index.tt2';

        return;
    }

    if ( $par1 =~ /^do/ ) {
        return $self->action_do( $c );
    }

    # project path selected
    my $p_rep_path = $par1;
    my $rep_path_simple = $p_rep_path;
    $rep_path_simple =~ s{^rp-}{};
    my $rep_path_db = $rep_path_simple;
    $rep_path_db =~ s{-}{\/}g;
    $rep_path_db .= '/';

    $c->stash->{rep_path_param} = $p_rep_path;
    $c->stash->{template} = 'report/report.tt2';

    my $rs = $c->model('WebDB::rep_path')->find(
        {
            path => $rep_path_db,
            'project_id.name' => $project_name
        },
        {
            join => { rep_id => 'project_id', },
            '+select' => [qw/ project_id.project_id /],
            '+as'     => [qw/ project_id /],
        }
    );
    unless ( $rs ) {
        $c->stash->{error} = "Rep_path '$rep_path_db' for project '$project_name' not found.";
        return;
    }
    my $rep_path_id = $rs->rep_path_id ;
    my $project_id = $rs->get_columns('project_id') ;

    my ( $path_nice, $path_type );
    # branches, tags
    if ( my ( $bt, $name ) = $rep_path_simple =~ m{^(branches|tags)\-(.*)$} ) {
        if ( $bt eq 'branches' ) {
            $path_type = 'branch ';
        } elsif ( $bt eq 'tags' ) {
            $path_type = 'tag ';
        }
        $path_nice = $name;

    # trunk
    } else {
        $path_type = '';
        $path_nice = $rep_path_simple;
    }

    #$self->dadd( $c, "rep_path_id: $rep_path_id\n\n" );
    $rs = $c->model('WebDB::rev')->search(
        {
            'get_rev_rep_path.rep_path_id' => $rep_path_id,
        },
        {
            join => [
                'get_rev_rep_path',
                'author_id',
            ],
            'select' => [qw/
                get_rev_rep_path.rep_path_id
                me.rev_id
                me.rev_num
                me.date
                me.author_id
                author_id.rep_login
             /],
            'as' => [qw/
                rep_path_id
                rev_id
                rev_num
                date
                author_id
                rep_login
            /],
            order_by => 'me.rev_num DESC',
            page => $pr->{page},
            rows => $pr->{rows} || 5,
            offset => $pr->{offset} || 0,
        }
    );

    my $build_search = {
        join => [
            { msjobp_cmd_id => [
                { msjobp_id => [
                    'jobp_id', { msjob_id => { msession_id => 'machine_id', } },
                ] },
                { output_id => 'fspath_id', },
                { outdata_id => 'fspath_id', },
            ], },
        ],
        'select' => [qw/
            machine_id.machine_id
            machine_id.name
            machine_id.cpuarch
            machine_id.osname
            machine_id.archname

            me.trun_id
            me.msjobp_cmd_id
            me.parse_errors
            me.not_seen
            me.failed
            me.todo
            me.skip
            me.bonus
            me.ok

            output_id.name
            fspath_id.web_path
            outdata_id.name
            fspath_id_2.web_path
        /],
        'as' => [qw/
            machine_id
            machine_name
            cpuarch
            osname
            archname

            trun_id
            msjobp_cmd_id
            parse_errors
            not_seen
            failed
            todo
            skip
            bonus
            ok

            output_fname
            output_web_path
            outdata_fname
            outdata_web_path
        /],
        order_by => 'machine_id',

    };

    my @revs = ();
    my $builds = {};
    while (my $rev = $rs->next) {
        my %rev_rows = ( $rev->get_columns() );

        my $rs_build = $c->model('WebDB::trun')->search(
            {
                'me.trun_status_id' => 2, # ok
                'jobp_id.rep_path_id' => $rev_rows{rep_path_id},
                'msjobp_id.rev_id' => $rev_rows{rev_id},
            },
            $build_search
        );
        push @revs, \%rev_rows;

        while (my $build = $rs_build->next) {
            my %build_rows = ( $build->get_columns() );
            $self->dumper( $c, \%build_rows );
            push @{$builds->{ $rev_rows{rev_id} }->{ $rev_rows{rep_path_id} }}, \%build_rows;
        }
    }
    #$c->stash->{dump} = sub { return Dumper( \@_ ); };
    #$self->dumper( $c, $builds );
    $c->stash->{revs} = \@revs;
    $c->stash->{builds} = $builds;

    $c->stash->{project_id} = $project_id;
    $c->stash->{rep_path_id} = $rep_path_id;

    $c->stash->{rep_path_nice} = $path_nice;
    $c->stash->{rep_path_type} = $path_type;
    my $path_full = $path_nice;
    $path_full = $path_type . ' ' . $path_full if $path_type;
    $c->stash->{rep_path_full} = $path_full;

    my $base_uri = '/' . $c->action->namespace . '/' . $p_project . '/' . $p_rep_path . '/page-';
    my $page_uri_prefix = $c->uri_for( $base_uri )->as_string;
    $c->stash->{pager_html} = $self->get_pager_html( $rs->pager, $page_uri_prefix );
}


=head1 SEE ALSO

L<TapTinder::Web>, L<Catalyst::Controller>

=head1 AUTHOR

Michal Jurosz <mj@mj41.cz>

=head1 LICENSE

This file is part of TapTinder. See L<TapTinder> license.

=cut


1;
