use strict;
use warnings;
use utf8;

return sub {
    my ( $schema, $delete_all, $data ) = @_;
    
    # table: user
    $schema->resultset('user')->delete_all() if $delete_all;
    $schema->resultset('user')->populate([
        [ qw/ user_id login passwd first_name last_name irc_nick active created last_login / ],
        [ 1, 'mj41', \'substring(MD5(RAND()), -8)', 'Michal', 'Jurosz', 'mj41', 1, \'NOW()', undef ],
    ]);


    # table: farm
    $schema->resultset('farm')->delete_all() if $delete_all;
    $schema->resultset('farm')->populate([
        [ qw/ farm_id name has_same_hw has_same_sw descr / ],
        [ 1, 'tapir cluster', 1, 0, 'Dedicated to TapTinder.' ],
    ]);


    # table: machine
    $schema->resultset('machine')->delete_all() if $delete_all;
    $schema->resultset('machine')->populate([
        [ qw/ machine_id name user_id passwd descr created ip cpuarch osname archname disabled prev_machine_id farm_id / ],
        [ 5, 'pc-jurosz2',    1, \'substring(MD5(RAND()), -8)', undef, \'NOW()', '147.229.5.124',  'i386',   'MSWin32', 'MSWin32-x86-multi-thread', 0, undef, undef   ],
        [ 6, 'tapir1',        1, \'substring(MD5(RAND()), -8)', undef, \'NOW()', '147.229.191.11', 'x86_64', 'linux',   'i386-linux-thread-multi',  0, undef, 1       ],
        [ 7, 'tapir2',        1, \'substring(MD5(RAND()), -8)', undef, \'NOW()', '147.229.191.12', 'x86_64', 'linux',   'i386-linux-thread-multi',  0, undef, 1       ]
    ]);


    # table: project
    $schema->resultset('project')->delete_all() if $delete_all;
    $schema->resultset('project')->populate([
        [ qw/ project_id name url descr / ],
        [ 1, 'tt-tr1', 'http://dev.taptinder.org/wiki/TapTinder-tr1', 'TapTinder test repository 1' ],
        [ 2, 'tt-tr2', 'http://dev.taptinder.org/wiki/TapTinder-tr2', 'TapTinder test repository 2' ],
        [ 3, 'tt-tr3', 'http://dev.taptinder.org/wiki/TapTinder-tr3', 'TapTinder test repository 3' ],
    ]);

 
    # table: rep
    $schema->resultset('rep')->delete_all() if $delete_all;
    $schema->resultset('rep')->populate([
        [ qw/ rep_id project_id active name repo_url descr / ],
        [ 1, 1, 1, 'default', 'git://github.com/mj41/tt-tr1.git', 'Default repository', ],
        [ 2, 2, 1, 'default', 'git://github.com/mj41/tt-tr2.git', 'Default repository', ],
        [ 3, 3, 1, 'default', 'git://github.com/mj41/tt-tr3.git', 'Default repository', ],
    ]);


    # table: fspath
    $schema->resultset('fspath')->delete_all() if $delete_all;
    $schema->resultset('fspath')->populate([
        [ qw/ fspath_id path web_path public created deleted name descr / ],
        [ 1, '/home/jurosz/dev-tt/server-data/cmdout', 'file/cmdout', 1, \'NOW()', undef, 'dir-cmdout', 'dir for command outputs'  ],
        [ 2, '/home/jurosz/dev-tt/server-data/patch',  'file/patch',  1, \'NOW()', undef, 'dir-patch',  'dir for patches'          ],
    ]);

 
    # table: fspath_select
    $schema->resultset('fspath_select')->delete_all() if $delete_all;
    $schema->resultset('fspath_select')->populate([
        [ qw/ fspath_select_id fsfile_type_id rep_id fspath_id / ],
        [ 1, 1, 1, 1  ],
        [ 2, 1, 2, 1  ],
        [ 3, 1, 3, 1  ],

        [ 4, 2, 1, 1  ],
        [ 5, 2, 2, 1  ],
        [ 6, 2, 3, 1  ],

        [ 7, 3, 1, 2  ],
        [ 8, 3, 2, 2  ],
        [ 9, 3, 3, 2  ],
    ]);

 
    # table: ibot
    $schema->resultset('ibot')->delete_all() if $delete_all;
    $schema->resultset('ibot')->populate([
        [ qw/ ibot_id nick full_name server port operator_id / ],
        [ 1, 'ttbot-dev', 'TapTinder bot (dev).', 'irc.freenode.org', 6667, 1 ],
    ]);

 
    # table: ichannel
    $schema->resultset('ichannel')->delete_all() if $delete_all;
    $schema->resultset('ichannel')->populate([
        [ qw/ ichannel_id name / ],
        [ 1, '#taptinder-bottest1'    ],
        [ 2, '#taptinder-bottest2'    ],
    ]);

=pod 
    # table: ichannel_conf
    $schema->resultset('ichannel_conf')->delete_all() if $delete_all;
    $schema->resultset('ichannel_conf')->populate([
        [ qw/ ichannel_conf_id ibot_id ichannel_id errors_only ireport_type_id jobp_cmd_id max_age / ],
        [ 1, 1, 1, 1, 1,  4, 14*24      ],
        [ 2, 1, 1, 0, 1,  9,  7*24      ],
        [ 3, 1, 1, 1, 2, 10,  undef     ],

        [ 4, 1, 2, 1, 1,  9,  7*24      ],
    ]);
=cut

    return 1;
};
