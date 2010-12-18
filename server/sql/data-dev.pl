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
        [ qw/ rep_id project_id active name path descr / ],
        [ 1, 1, 1, 'default', 'tt-tr1', 'Defautl repository', ],
        [ 2, 2, 1, 'default', 'tt-tr2', 'Defautl repository', ],
        [ 3, 3, 1, 'default', 'tt-tr3', 'Defautl repository', ],
    ]);

=pod
    # table: job
    $schema->resultset('job')->delete_all() if $delete_all;
    $schema->resultset('job')->populate([
        [ qw/ job_id client_min_rev priority name descr / ],
        [ 1, 257, 1, 'tr1 A',     undef    ],
        [ 2, 257, 2, 'tr1, tr2',  undef    ],
        [ 3, 257, 3, 'tr1, tr3',  undef    ],
        [ 4, 257, 4, 'tr1 B',     undef    ],
    ]);

 
    # table: jobp
    $schema->resultset('jobp')->delete_all() if $delete_all;
    $schema->resultset('jobp')->populate([
        [ qw/ jobp_id job_id rref_id `order` name descr max_age depends_on_id extends / ],
        [ 1, 1, 1, 1, 'sole',           undef,     3*30*24, undef, 0    ],
        [ 2, 2, 1, 1, 'base',           undef,     3*30*24, undef, 0    ],
        [ 3, 2, 2, 2, 'external tests', undef,     5*30*24,     2, 1    ],
        [ 4, 3, 1, 1, 'base',           undef,       10*24, undef, 0    ],
        [ 5, 3, 3, 2, 'related part',   undef,    12*30*24,     4, 0    ],
        [ 6, 4, 1, 1, 'sole',           undef,       undef, undef, 0    ],
    ]);

 
    # table: jobp_cmd
    $schema->resultset('jobp_cmd')->delete_all() if $delete_all;
    $schema->resultset('jobp_cmd')->populate([
        [ qw/ jobp_cmd_id jobp_id `order` cmd_id / ],
        [ 1, 1, 1, 1 ],
        [ 2, 1, 2, 2 ],
        [ 3, 1, 3, 4 ],
        [ 4, 1, 4, 5 ],
        [ 5, 1, 5, 6 ],


        [ 6,  2, 1, 1 ],
        [ 7,  2, 2, 2 ],
        [ 8,  2, 3, 4 ],
        [ 9,  2, 4, 5 ],
        [ 10, 2, 5, 6 ],

        [ 11, 3, 1, 1 ],
        [ 12, 3, 2, 2 ],
        [ 13, 3, 3, 6 ],


        [ 14, 4, 1, 1 ],
        [ 15, 4, 2, 2 ],
        [ 16, 4, 3, 4 ],
        [ 17, 4, 4, 5 ],
        [ 18, 4, 5, 6 ],

        [ 19, 5, 1, 1 ],
        [ 20, 5, 2, 2 ],
        [ 21, 5, 3, 4 ],
        [ 22, 5, 4, 5 ],
        [ 23, 5, 5, 6 ],

        [ 24, 6, 1, 1 ],
        [ 25, 6, 2, 2 ],
        [ 26, 6, 3, 4 ],
        [ 27, 6, 4, 5 ],
    ]);

 
    # table: machine_job_conf
    $schema->resultset('machine_job_conf')->delete_all() if $delete_all;
    $schema->resultset('machine_job_conf')->populate([
        [ qw/ machine_job_conf_id machine_id rep_id rref_id job_id priority / ],
        [ 1, 5, undef, undef, 1,    1   ],

        [ 2, 6, 1,    undef, undef, 1   ],
        [ 3, 6, undef, undef, 2,    2   ],

        [ 4, 7, 1,    undef, undef, 1   ],
        [ 5, 7, 1,    undef, undef, 2   ],
        [ 6, 7, undef, undef, undef, 3  ],
    ]);

=cut
 
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
