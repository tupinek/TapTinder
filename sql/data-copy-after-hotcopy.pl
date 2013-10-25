use strict;
use warnings;
use utf8;

use FindBin;
use File::Spec;
use Cwd 'abs_path';


return sub {
    my ( $schema ) = @_;
    
    my $server_data_dir = abs_path( 
        File::Spec->catdir( $FindBin::Bin, '..', '..', 'server-data' )
    );


    # table: params
    $schema->resultset('param')->search({
        'param_type_id' => 2, # delete all old 'instance-name' rows
    })->delete_all;
    $schema->resultset('param')->populate([
        [ qw/ param_type_id value / ],
        [ 2, 'ttcopy' ],
    ]);

    
    # Update ttprod paths add new paths and fill new data to path_select.

    my $fspath_rs = $schema->resultset('fspath');
    while ( my $fspath_row = $fspath_rs->next ) {
        my $odata = { $fspath_row->get_columns };
        $fspath_row->update({
            'web_path' => $odata->{web_path} . '-ttprod',
            'name' => $odata->{name} . ' link to ttprod',
            'descr' => $odata->{descr} . ' (link to data from ttprod instance)',
        });
    }

    my $fspath_cmdout_rs = $fspath_rs->create({
        'path' => $server_data_dir.'/cmdout',
        'web_path' => 'file/cmdout',
        'public' => 1,
        'created' => \'NOW()',
        'deleted' => undef,
        'name' => 'dir-cmdout',
        'descr' => 'dir for command outputs (client whitch runs on ttcopy instance)'
    });
    my $fspath_cmdout_id = $fspath_cmdout_rs->id;

    my $fspath_archive_rs = $fspath_rs->create({
        'path' => $server_data_dir.'/archive',
        'web_path' => 'file/archive',
        'public' => 1,
        'created' => \'NOW()',
        'deleted' => undef,
        'name' => 'dir-archive',
        'descr' => 'dir for archives (extracted on ttcopy instance)'
    });
    my $fspath_archive_id = $fspath_archive_rs->id;


    $schema->resultset('fspath_select')->delete_all();
    my $fspath_select_rs = $schema->resultset('fspath_select');
    my $rep_rs = $schema->resultset('rep');
    while ( my $rep_row = $rep_rs->next ) {
        $fspath_select_rs->create({
            fsfile_type_id => 1,
            rep_id => $rep_row->id,
            fspath_id => $fspath_cmdout_id,
        });

        $fspath_select_rs->create({
            fsfile_type_id => 2,
            rep_id => $rep_row->id,
            fspath_id => $fspath_archive_id,
        });
    }

    
    # New bot.
    $schema->resultset('ibot_log')->delete_all();
    $schema->resultset('ichannel_conf')->delete_all();
    $schema->resultset('ichannel')->delete_all();
    $schema->resultset('ibot')->delete_all();

    $schema->resultset('ibot')->populate([
        [ qw/ ibot_id nick full_name server port operator_id / ],
        [ 1, 'ttbot-copy', 'TapTinder bot (copy).', 'irc.freenode.org', 6667, 1  ],
    ]);

    $schema->resultset('ichannel')->populate([
        [ qw/ ichannel_id name / ],
        [     1, '#taptinder-bottest1'  ],
        [     2, '#taptinder-bottest2'  ],
    ]);

    $schema->resultset('ichannel_conf')->populate([
        [ qw/ ichannel_conf_id ibot_id ichannel_id errors_only ireport_type_id jobp_cmd_id max_age / ],
        [  1, 1, 1, 1, 1, 4,   7*24  ],
        [  2, 1, 2, 1, 1, 4,   7*24  ],
    ]);


    # Set new passwords and other private data.
    # ToDo


    return 1;
};
