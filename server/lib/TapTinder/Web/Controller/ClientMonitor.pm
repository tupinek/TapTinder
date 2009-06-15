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

    my $pr = $self->get_page_params( $params );

    my $plus_rows = [ qw/ msession_id client_rev start_time machine_id machine_name cpuarch osname archname last_cmd_finish_time max_mslog_id /];
    my $search_conf = {
        'select' => $plus_rows,
        'as'     => $plus_rows,
        bind   => [],
        page => $pr->{page},
        rows => $pr->{rows} || 20,
        offset => $pr->{offset} || 0,
    };

    my $rs = $c->model('WebDB')->schema->resultset( 'MSessionStatus' )->search( {}, $search_conf );

    # ToDo - haven't time to find right solution
    my $date_from = DateTime->now( time_zone => 'GMT' );
    $date_from->add( hours => -1.5 );
    my $date_from_str = $date_from->ymd . ' ' . $date_from->hms;
    #$self->dumper( $c, $date_from_str );

    my @states = ();
    while (my $state = $rs->next) {
        my %state_rows = ( $state->get_columns() );

        my $mslog_row = $c->model('WebDB::mslog')->find(
            {
                'mslog_id' => $state_rows{max_mslog_id},
            }, {
               join => 'msstatus_id',
               select => [ qw/ me.mslog_id me.change_time msstatus_id.name / ],
               as => [ qw/ mslog_id mslog_change_time msstatus_name / ],
            }
        );

        my %mslog = $mslog_row->get_columns;
        if ( $mslog{mslog_change_time} gt $date_from_str ) {
            push @states, { %state_rows, %mslog };
        }
        #$self->dumper( $c, \%mslog );
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
