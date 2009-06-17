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
    my ( $self, $c, $params, @args ) = @_;

    my $pr = $self->get_page_params( $params );

    # TODO
    my $rep_path_id = 1;
    # TODO last 100
    my $rev_num_from = 3700;

    # load revision info
    my $rs_revs = $c->model('WebDB::rev_rep_path')->search( {
        'rep_path_id' => $rep_path_id,
    }, {
        select => [ qw/
            rev_id.rev_id rev_id.rev_num rev_id.date rev_id.msg
            author_id.rep_author_id author_id.rep_login
        / ],
        as => [ qw/
            rev_id rev_num date msg
            rep_author_id rep_login
        / ],
        join => [ { 'rev_id' => 'author_id' } ],
        order_by => [ 'rev_id.rev_num DESC' ],
        page => 1,
        rows => 100,
        #offset => 0,
    } );

    my @revs = ();
    while (my $row_obj = $rs_revs->next) {
        my %row = ( $row_obj->get_columns() );
        push @revs, \%row;
    }
    $c->stash->{revs} = \@revs;

    # load make results
    my $plus_rows = [ qw/ machine_id rev_id status_id status_name web_fpath /];
    my $search_conf = {
        'select' => $plus_rows,
        'as'     => $plus_rows,
        bind   => [
            $rep_path_id, # rep_path_id
            $rev_num_from, # rev_num
            $rep_path_id, # rep_path_id
        ],
    };

    my $rs = $c->model('WebDB')->schema->resultset( 'BuildStatus' )->search( {}, $search_conf );

    #use Time::HiRes qw(time); my $time_start = time();

    my %ress = ();
    my %machines = ();
    while (my $row_obj = $rs->next) {
        my %row = ( $row_obj->get_columns() );
        my $machine_id = $row{machine_id};
        $ress{ $row{rev_id} }->{ $machine_id } = \%row;
        $machines{ $machine_id }++;
    }
    #$c->stash->{times}->{1} = time() - $time_start; $self->dumper( $c, $c->stash->{times} );

    $c->stash->{ress} = \%ress;
    $c->stash->{machines} = \%machines;

    $self->dumper( $c, \%machines );
    $self->dumper( $c, \@revs );
    $self->dumper( $c, \%ress );
}


=head1 SEE ALSO

L<TapTinder::Web>, L<Catalyst::Controller>

=head1 AUTHOR

Michal Jurosz <mj@mj41.cz>

=head1 LICENSE

This file is part of TapTinder. See L<TapTinder> license.

=cut


1;
