package TapTinder::Web::Controller::ClientMonitor;

use strict;
use warnings;
use base 'TapTinder::Web::ControllerBase';

=head1 NAME

TapTinder::Web::Controller::ClientMonitor - Catalyst Controller

=head1 DESCRIPTION

Catalyst controller for TapTinder client state monitoring.

=head1 METHODS

=head2 index

=cut

sub index : Path  {
    my ( $self, $c, $params, @args ) = @_;
    my $ot : Stashed = '';

    my $pr = $self->get_page_params( $params );

    my $search = {
        join => [
            'machine_id',
        ],
        'select' => [qw/
            me.msession_id
            me.client_rev
            me.start_time

            machine_id.machine_id
            machine_id.name
            machine_id.cpuarch
            machine_id.osname
            machine_id.archname
        /],
        'as' => [qw/
            msession_id
            client_rev
            start_time

            machine_id
            machine_name
            cpuarch
            osname
            archname
        /],
        order_by => [ 'machine_id', 'start_time' ],
        page => $pr->{page},
        rows => $pr->{rows} || 5,
        offset => $pr->{offset} || 0,
    };


    my $rs = $c->model('WebDB::msession')->search(
        {
            'me.end_time' => undef,
            'me.abort_reason_id' => undef,
        },
        $search
    );

    my @states = ();
    while (my $state = $rs->next) {
        my %state_rows = ( $state->get_columns() );
        push @states, \%state_rows;
    }
    $c->stash->{states} = \@states;

    my $base_uri = '/' . $c->action->namespace . '/page-';
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
