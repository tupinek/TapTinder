package Bot::BasicBot::Pluggable::Module::TapTinderBot;

use base qw(Bot::BasicBot::Pluggable::Module);
use warnings;
use strict;

use Data::Dumper;
use Carp qw(carp croak verbose);

our $tick_counter = 0;

=head1 NAME

Bot::BasicBot::Pluggable::Module::TapTinderBot - report status

=head1 IRC USAGE

...

=cut

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
    my ( $self, $debug ) = @_;
    $self->{loop_num}++;

    my $sql = <<'SQLEND';
        select ichc.ibot_id,
               ichc.ichannel_id,
               ichc.ireport_type_id,
               ichc.ichannel_conf_id,
               ich.name as channel,
               m.machine_id,
               m.name as machine_name,
               m.archname,
               jp.rep_path_id,
               c.name as cmd_name,
               p.name as project_name,
               rp.path as rep_path,
               mjp.rev_id,
               r.rev_num,
               ra.rep_login as author_login,
               cs.name as status_name,
               mjpc.msjobp_cmd_id,
               concat(fsp.web_path, '/', fsf.name) as web_fpath,
               (
                 select 1
                   from ibot_log ibl
                  where ibl.ibot_id = ichc.ibot_id
                    and ibl.ichannel_conf_id = ichc.ichannel_conf_id
                    and ibl.rep_path_id = rp.rep_path_id
                    and ibl.rev_id = r.rev_id
                  limit 1
               ) as reported
          from ichannel_conf ichc,
               ichannel ich,
               jobp_cmd jpc,
               jobp jp,
               cmd c,
               job j,
               msjobp_cmd mjpc,
               msjobp mjp,
               rev r,
               rep_author ra,
               msjob mj,
               msession ms,
               machine m,
               rep_path rp,
               rep rep,
               project p,
               cmd_status cs,
               fsfile fsf,
               fspath fsp
         where ichc.ibot_id = ? -- <<<
           and ich.ichannel_id = ichc.ichannel_id
           and jpc.jobp_cmd_id = ichc.jobp_cmd_id
           and jp.jobp_id = jpc.jobp_id
           and c.cmd_id = jpc.cmd_id
           and j.job_id = jp.job_id
           and mjpc.jobp_cmd_id = ichc.jobp_cmd_id
           and ( mjpc.status_id = 4 or mjpc.status_id = 6 )
           and ( ichc.errors_only = 0 or mjpc.status_id = 6 )
           and mjp.msjobp_id = mjpc.msjobp_id
           and mjp.jobp_id = jp.jobp_id
           and r.rev_id = mjp.rev_id
           and ( ichc.max_age is null or DATE_SUB(CURDATE(), INTERVAL ichc.max_age HOUR) <= r.date )
           and ra.rep_author_id = r.author_id
           and mj.msjob_id = mjp.msjob_id
           and mj.job_id = j.job_id
           and ms.msession_id = mj.msession_id
           and m.machine_id = ms.machine_id
           and rp.rep_path_id = jp.rep_path_id
           and rep.rep_id = rp.rep_id
           and p.project_id = rep.project_id
           and cs.cmd_status_id = mjpc.status_id
           and fsf.fsfile_id = mjpc.output_id
           and fsp.fspath_id = fsf.fspath_id
         order by ichc.ichannel_id, ichc.ireport_type_id, rp.rep_path_id, r.rev_num
SQLEND

    my $ba = [ $self->{ibot_id} ];

    my $dbh = $self->{schema}->storage->dbh;
    my $sth = $dbh->prepare( $sql );
    $sth->execute( @$ba );

    my $max_revs = {};
    while ( my $row = $sth->fetchrow_hashref() ) {
        #print Dumper( $row ) if $debug;
        my $key =
              $row->{ichannel_id} . '-'
            . $row->{ireport_type_id} . '-'
            . $row->{archname} . '-'
            . $row->{rep_path_id} . '-'
            . $row->{status_name}
        ;
        if ( (not exists $max_revs->{$key}) || $row->{rev_num} > $max_revs->{$key}->{rev_num} ) {
            $max_revs->{$key} = { %$row };
        }
    }
    print Dumper( $max_revs ) if $debug;

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
