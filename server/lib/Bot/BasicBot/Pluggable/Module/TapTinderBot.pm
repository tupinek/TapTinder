=head1 NAME

Bot::BasicBot::Pluggable::Module::TapTinderBot - report status

=head1 IRC USAGE

...

=cut

package Bot::BasicBot::Pluggable::Module::TapTinderBot;
use base qw(Bot::BasicBot::Pluggable::Module);
use warnings;
use strict;

use Data::Dumper;
use Carp qw(carp croak verbose);

our $tick_counter = 0;

sub init {
    my $self = shift;

    $self->{loop_num} = 0;
    $self->set('user_tick', "1") unless defined ( $self->get('user_tick') );
}


sub tick {
    my $self = shift;

    my $period = $self->get('user_tick');
    my $tick_counter++;
    return if ( $tick_counter < $period);
    $tick_counter = 0;
    return $self->_check_news();
}

sub _save_done {
    my ( $self, $ibot_id, $ichannel_conf_id, $rep_path_id, $rev_id ) = @_;

    return $self->{schema}->resultset('ibot_log')->create({
        ibot_id => $ibot_id,
        ichannel_conf_id => $ichannel_conf_id,
        rep_path_id => $rep_path_id,
        rev_id => $rev_id,
    });
}


sub _check_news {
    my ( $self ) = @_;
    $self->{loop_num}++;

    my $search_conf = { 'me.ibot_id' => $self->{ibot_id} };
    my $search_attrs = {
        'select' => [ qw/
            ibot_id ichannel_id channel ichannel_conf_id ireport_type_id machine_id machine_name
            archname rep_path_id project_name rep_path cmd_name rev_id
            rev_num author_login status_name msjobp_cmd_id web_fpath
            reported
        / ],
    };

    my $rs = $self->{schema}->resultset( 'BotReportStatus' )->search( $search_conf, $search_attrs );

    my $max_revs = {};
    while ( my $row = $rs->next ) {
        my %cols = $row->get_columns;
        my $key =
              $cols{ichannel_id} . '-'
            . $cols{ireport_type_id} . '-'
            . $cols{archname} . '-'
            . $cols{rep_path_id} . '-'
            . $cols{status_name}
        ;
        if ( (not exists $max_revs->{$key}) || $cols{rev_num} > $max_revs->{$key}->{rev_num} ) {
            $max_revs->{$key} = { %cols };
        }
    }
    # print Dumper( $max_revs );

    foreach my $key ( keys %$max_revs ) {
        next if $max_revs->{$key}->{reported};

        my $channel_name = $max_revs->{$key}->{channel};
        unless ( exists $self->{Bot}->{channel_data}->{$channel_name} ) {
            carp "Bot not started for channel '$channel_name'.";
            next;
        }
        my $data = $max_revs->{$key};

        my $msg = '';
        #$msg .= "$data->{author_login}: ";
        $msg .= "$data->{project_name} $data->{rep_path}";
        $msg .= " r$data->{rev_num} $data->{archname}";

        # build report
        if ( $data->{ireport_type_id} == 1 ) {
            $msg .= " $data->{cmd_name} $data->{status_name}";
            $msg .= " " . $self->{server_base_url} . $data->{web_fpath};
            $msg .= " ( " . $self->{server_base_url} . "/buildstatus/pr-" . $data->{project_name} . "/rp-" . $data->{rep_path} . " )";
            $msg .= " (debug: $self->{loop_num})" if $self->{irc_debug};
            $self->tell( $channel_name, $msg );

        # ttest report
        } elsif ( $data->{ireport_type_id} == 2 ) {
            # ToDo
            # $self->tell( $channel_name, $msg );
        }

        $self->_save_done( $data->{ibot_id}, $data->{ichannel_conf_id}, $data->{rep_path_id}, $data->{rev_id} );
    }

    return $self;
}


sub help {
    return "Gives TapTinder report status.";
}


sub _my_init {
    my ( $self, $ibot_id, $schema, $server_base_url, $ver, $debug ) = @_;
    $self->{ibot_id} = $ibot_id;
    $self->{schema} = $schema;
    $self->{server_base_url} = $server_base_url;
    $self->{ver} = $ver;
    $self->{debug} = $debug;
    $self->{irc_debug} = $debug;
    return $self;
}


=head1 SEE ALSO

L<TapTinder>, L<Bot::BasicBot::Pluggable>

=head1 AUTHOR

Michal Jurosz <mj@mj41.cz>

=head1 LICENSE

This file is part of TapTinder. See L<TapTinder> license.

=cut

1;
