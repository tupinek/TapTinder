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

    my $date_from = DateTime->now( time_zone => 'GMT' );
    my $second_back = 1.5*60*60 + ( $date_from->second );
    if ( 0 && $c->log->is_debug  ) {
        $second_back = 7*24*60*60 + ( $date_from->second );
    }
    $date_from->add(
        # 1.5 hours old and caching each minute.
        seconds => -$second_back,
    );
    my $date_from_str = $date_from->ymd . ' ' . $date_from->hms;
    #$self->dumper( $c, $date_from_str );

    my $plus_rows = [ qw/
        msession_id client_rev start_time machine_id machine_name
        cpuarch osname archname last_finished_msjobp_cmd_id
        max_mslog_id
        mslog_id mslog_change_time msstatus_name
        last_cmd_name last_cmd_end_time
        last_cmd_rev_num last_cmd_rep_path last_cmd_author last_cmd_project_name
    /];
    # $mslog{mslog_change_time} gt $date_from_str
    my $search_conf = {
        'select' => $plus_rows,
        'as'     => $plus_rows,
        bind   => [ $date_from_str ],
        page => $pr->{page},
        rows => $pr->{rows} || 50,
        offset => $pr->{offset} || 0,
        result_class => 'DBIx::Class::ResultClass::HashRefInflator',
    };

    my $rs = $c->model('WebDB')->schema->resultset( 'MSessionStatus' )->search( {}, $search_conf );

    my @states = $rs->all;
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
