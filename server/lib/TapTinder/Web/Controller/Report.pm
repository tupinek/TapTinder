package TapTinder::Web::Controller::Report;

use strict;
use warnings;
use base 'Catalyst::Controller::BindLex';

use Data::Page::HTML qw/get_pager_html/;
use DBIx::Dumper qw/Dumper dump_row/;

=head1 NAME

TapTinder::Web::Controller::Report - Catalyst Controller

=head1 DESCRIPTION

Catalyst controller for TapTinder web reports. The actions for reports browsing.

=head1 METHODS

=cut

=head2 index

=cut

sub index : Path  {
    my ( $self, $c, $p_project, $par1, $par2, @args ) = @_;
    my $p_rep_path;
    my $params;

    my $ot : Stashed = '';
    #$ot = Dumper( { p_project => $p_project, par1 => $par1, par2 => $par2, args => \@args } );

    my $project_name = undef;

    my $is_index = 0;
    $is_index = 1 if !$p_project; # project list
    # project name found
    if ( $p_project ) {
        $project_name = $p_project;
        $project_name =~ s{^pr-}{};
        $c->stash->{project_name} = $project_name;
    }

    # project name, nothing else
    if ( !$par1 ) {
        $is_index = 1;
    # project name and parameters
    } elsif ( $par1 =~ /^(page|rows)\-/ ) {
        $params = $par1;
        $is_index = 1;
    # probably rep_path name
    } else {
        $p_rep_path = $par1;
        $params = $par2 if $par2;
    }

    # default page listing values
    my $pr = {
        page => 1,
        rows => ( $is_index ) ? 15 : 10,
    };
    if ( $params ) {
        # try to set page, rows, ... values from url params
        my @parts = split( ',', $params );
        foreach my $part ( @parts ) {
            if ( $part =~ m/^ page-(\d+) $/x ) {
                $pr->{page} = $1;
                next;
            }
            if ( $part =~ m/^ rows-(\d+) $/x ) {
                $pr->{rows} = $1;
                next;
            }
        }
        $pr->{page} = 1 if $pr->{page} < 1;
    }


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

            my $plus_cols = [ qw/ max_rev_num rev_id author_id date rep_login /];

            my $search_conf = {
                '+select' => $plus_cols,
                '+as' => $plus_cols,
                bind  => [ $project_data->{rep_id} ],
                rows  => $pr->{rows},
            };
            if ( $project_name ) {
                $search_conf->{page} = $pr->{page};
            }
            my $rs_rp = $c->model('WebDB')->schema->resultset( 'ActiveRepPathList' )->search( {}, $search_conf );

            if ( $project_name ) {
                my $base_uri = '/' . $c->action->namespace . '/pr-' . $project_name . '/page-';
                my $page_uri_prefix = $c->uri_for( $base_uri )->as_string;
                $c->stash->{pager_html} = get_pager_html( $rs_rp->pager, $page_uri_prefix );
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


    # project path selected

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
        $c->stash->{error} = "Rep_path '$project_name' for project '$rep_path_db' not found.";
        return;
    }
    my $rep_path_id = $rs->rep_path_id ;
    my $project_id = $rs->get_column('project_id') ;

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

    #$ot .= "rep_path_id: $rep_path_id\n\n";

    $rs = $c->model('WebDB::rev')->search(
        {
            'get_rev_rep_path.rep_path_id' => $rep_path_id,
            'get_build.rep_path_id' => $rep_path_id,
        },
        {
            join => [
                'get_rev_rep_path',
                {
                    'get_build' => [
                        { msession_id => 'machine_id', },
                        'conf_id',
                        { get_trun => 'conf_id', },
                    ],
                },
                'author_id',
            ],
            'where' => '',
            'select' => [qw/
                me.rev_id
                me.rev_num
                me.date
                me.author_id
                author_id.rep_login

                machine_id.machine_id
                machine_id.name
                machine_id.cpuarch
                machine_id.osname
                machine_id.archname

                conf_id.build_conf_id
                conf_id.cc
                conf_id.devel
                conf_id.optimize

                get_trun.trun_id
                get_trun.num_notseen
                get_trun.num_failed
                get_trun.num_unknown
                get_trun.num_todo
                get_trun.num_bonus
                get_trun.num_skip
                get_trun.num_ok

                conf_id_2.trun_conf_id
                conf_id_2.harness_args
            /],
            'as' => [qw/
                rev_id
                rev_num
                date
                author_id
                rep_login

                machine_id
                machine_name
                cpuarch
                osname
                archname

                build_conf_id
                cc
                devel
                optimize

                trun_id
                num_notseen
                num_failed
                num_unknown
                num_todo
                num_bonus
                num_skip
                num_ok

                trun_conf_id
                harness_args
            /],
            order_by => 'rev_num DESC',
            page => $pr->{page},
            rows => $pr->{rows},
        }
    );
    my @test_runs = ();
    while (my $trun = $rs->next) {
        my %cols = ( $trun->get_columns() );
        push @test_runs, \%cols;
        #$ot .= dump_row( $trun ) . "\n";
        #$ot .= Dumper( \%cols ) . "\n";
    }
    $c->stash->{test_runs} = \@test_runs;

    $c->stash->{project_id} = $project_id;
    $c->stash->{rep_path_id} = $rep_path_id;

    $c->stash->{rep_path_nice} = $path_nice;
    $c->stash->{rep_path_type} = $path_type;
    my $path_full = $path_nice;
    $path_full = $path_type . ' ' . $path_full if $path_type;
    $c->stash->{rep_path_full} = $path_full;

    my $base_uri = '/' . $c->action->namespace . '/' . $p_project . '/' . $p_rep_path . '/page-';
    my $page_uri_prefix = $c->uri_for( $base_uri )->as_string;
    $c->stash->{pager_html} = get_pager_html( $rs->pager, $page_uri_prefix );
}


=head1 SEE ALSO

L<TapTinder::Web>, L<Catalyst::Controller>

=head1 AUTHOR

Michal Jurosz <mj@mj41.cz>

=head1 LICENSE

This file is part of TapTinder. See L<TapTinder> license.

=cut


1;
