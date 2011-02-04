package TapTinder::Web::Controller::BuildStatus;

use strict;
use warnings;
use base 'TapTinder::Web::ControllerBase';

=head1 NAME

TapTinder::Web::Controller::BuildStatus - Catalyst Controller

=head1 DESCRIPTION

Catalyst controller for TapTinder. Shows build status.

=head1 METHODS

=head2 index

=cut

sub index : Path  {
    my ( $self, $c, $p_project, $par1, $par2, @args ) = @_;

    my ( $is_index, $project_name, $params ) = $self->get_projname_params( $c, $p_project, $par1, $par2 );
    my $ref_name = undef; # ToDo
    $ref_name = 'master' unless $ref_name;
    my $pr = $self->get_page_params( $params );
    $self->dumper( $c, { par1 => $par1, par2 => $par2, args => \@args, } );

    my $search = { 
        'me.name' => $ref_name,
        'me.active' => 1,
        'rep_id.active' => 1,
        'project_id.name' => $project_name,
    };
    my $project_rs = $c->model('WebDB::rref')->search( $search,
        {
            join => { 'rcommit_id' => { 'rep_id' => 'project_id', }, },
            'select' => [qw/ me.rref_id me.name   rcommit_id.rcommit_id rep_id.rep_id rep_id.github_url project_id.project_id project_id.name project_id.url /],
            'as' =>     [qw/ rref_id    rref_name rcommit_id            rep_id        github_url        project_id            project_url    /],
        }
    );
    my $project_row = $project_rs->next;
    return 1 unless $project_row;
    
    my $project_info = { $project_row->get_columns };
    $c->stash->{project_info} = $project_info;
    $self->dumper( $c, $project_info );

    my $rref_id = $project_info->{rref_id};

    my $jobp_id = undef;
    if ( $par2 ) {
        ( $jobp_id ) = $par2 =~ /^jp\-(\d+)$/;
    }
    unless ( $jobp_id ) {
        my $search_wui_build = {
            'project_id' => $project_info->{project_id},
        };
        my $wui_build_rs = $c->model('WebDB::wui_build')->search( $search_wui_build, {} );
        my $jobp_row = $wui_build_rs->next;
        return 0 unless $jobp_row;
        $jobp_id = $jobp_row->get_column('jobp_id');
    }
    
    my $cmd_id = 5;
    if ( $args[0] ) {
        ( $cmd_id ) = $args[0] =~ /^c\-(\d+)$/;
    }
    
    $self->dadd( $c, "jobp_id: $jobp_id\n" );
    $self->dadd( $c, "rref_id: $rref_id\n" );


    my $rs_rcommits = $c->model('WebDB::rref_rcommit')->search( {
        'me.rref_id' => $rref_id,
    }, {
        select => [ qw/
            me.rcommit_id rcommit_id.committer_time rcommit_id.msg sha_id.sha
            author_id.rauthor_id author_id.rep_login
        / ],
        as => [ qw/
            rcommit_id date msg sha
            rep_author_id rep_login
        / ],
        join => { 'rcommit_id' => [ 'author_id', 'sha_id' ], },
        order_by => [ 'rcommit_id.committer_time DESC' ],
        page => 1,
        rows => 100,
        #offset => 0,
    } );

    my @rcommits = ();
    while ( my $row_obj = $rs_rcommits->next ) {
        push @rcommits, { $row_obj->get_columns() };
    }
    #$self->dumper( $c, \@rcommits );
    if ( scalar @rcommits <= 0 ) {
        return 1;
    }
    
    my $commit_time_from = $rcommits[-1]->{date};
    my $commit_time_to = $rcommits[0]->{date};
    $self->dadd( $c, "Commit time from $commit_time_from to $commit_time_to.\n" );

    my $cols = [ qw/ 
        machine_id
        rcommit_id
        status_id
        status_name
        web_fpath
    / ];

    my $sql = "
    from (
       select ms.machine_id,
              rc.rcommit_id,
              mjpc.status_id,
              cs.name as status_name,
              concat(fsp.web_path, '/', fsf.name) as web_fpath
         from rref_rcommit rrc,
              rcommit rc,
              jobp jp,
              jobp_cmd jpc,
              msjobp mjp,
              msjobp_cmd mjpc,
              cmd_status cs,
              msjob mj,
              msproc msp,
              msession ms,
              fsfile fsf,
              fspath fsp
        where rrc.rref_id = ?
          and rc.rcommit_id = rrc.rcommit_id
          and rc.committer_time >= str_to_date(?,'%Y-%m-%d %H:%i:%s')
          and rc.committer_time <= str_to_date(?,'%Y-%m-%d %H:%i:%s')
          and jp.jobp_id = ? -- only this job
          and jpc.jobp_id = jp.jobp_id
          and jpc.cmd_id = ? -- only this cmd
          and mjp.rcommit_id = rc.rcommit_id
          and mjp.jobp_id = jp.jobp_id
          and mjpc.jobp_cmd_id = jpc.jobp_cmd_id
          and mjpc.msjobp_id = mjp.msjobp_id
          and cs.cmd_status_id = mjpc.status_id
          and fsf.fsfile_id = mjpc.output_id
          and fsp.fspath_id = fsf.fspath_id
          and mj.msjob_id = mjp.msjobp_id
          and msp.msproc_id = mj.msproc_id
          and ms.msession_id = msp.msession_id
    ) a_f
   "; # end sql

    my $ba = [ 
        $rref_id,
        $commit_time_from, 
        $commit_time_to,
        $jobp_id, # jp.jobp_id
        $cmd_id, # jpc.cmd_id
    ];
    my $all_rows = $self->edbi_selectall_arrayref_slice( $c, $cols, $sql, $ba );
    #$self->dumper( $c, $all_rows );

    my %ress = ();
    my %machines = ();
    foreach my $row ( @$all_rows ) {
        my $machine_id = $row->{machine_id};
        $ress{ $row->{rcommit_id} }->{ $machine_id } = $row;
        $machines{ $machine_id }++;
    }

    $c->stash->{rcommits} = \@rcommits;
    $c->stash->{ress} = \%ress;
    $c->stash->{machines} = \%machines;


    if ( 1 ) {
        $self->dumper( $c, \%machines );
        $self->dumper( $c, \@rcommits );
        #$self->dumper( $c, $rev_num_from );
        $self->dumper( $c, \%ress );
    }
    
}


=head1 SEE ALSO

L<TapTinder::Web>, L<Catalyst::Controller>

=head1 AUTHOR

Michal Jurosz <mj@mj41.cz>

=head1 LICENSE

This file is part of TapTinder. See L<TapTinder> license.

=cut


1;
