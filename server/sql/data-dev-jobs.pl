use strict;
use warnings;
use utf8;

return sub {
    my ( $schema, $delete_all, $data ) = @_;

    my $master_tr1_rref_id = $schema->resultset('rref')->find(
        {
            'me.name' => 'master',
            'rcommit_id.rep_id' => 1, # default repo fro tt-tr1 project, see data-dev.pl
        },
        {
            join => 'rcommit_id',
        }
    )->id;
    return 0 unless $master_tr1_rref_id;

    my $master_tr2_rref_id = $schema->resultset('rref')->find(
        {
            'me.name' => 'master',
            'rcommit_id.rep_id' => 2, # default repo fro tt-tr2 project, see data-dev.pl
        },
        {
            join => 'rcommit_id',
        }
    )->id;
    return 0 unless $master_tr2_rref_id;

    my $master_tr3_rref_id = $schema->resultset('rref')->find(
        {
            'me.name' => 'master',
            'rcommit_id.rep_id' => 3, # default repo fro tt-tr3 project, see data-dev.pl
        },
        {
            join => 'rcommit_id',
        }
    )->id;
    return 0 unless $master_tr3_rref_id;
    

    # table: job
    $schema->resultset('job')->delete_all() if $delete_all;
    $schema->resultset('job')->populate([
        [ qw/ job_id client_min_ver priority name descr / ],
        [ 1, 257, 1, 'tr1 A',       undef    ],
        [ 2, 257, 2, 'tr1, tr2 A',  undef    ],
        [ 3, 257, 3, 'tr1, tr3 A',  undef    ],
        [ 4, 257, 4, 'tr1 B',       undef    ],
    ]);

 
    # table: jobp
    $schema->resultset('jobp')->delete_all() if $delete_all;
    $schema->resultset('jobp')->populate([
        [ qw/ jobp_id job_id rref_id `order` name descr max_age depends_on_id extends / ],
        [ 1, 1, $master_tr1_rref_id, 1, 'sole',           undef,     3*30*24, undef, 0    ],
        [ 2, 2, $master_tr1_rref_id, 1, 'base',           undef,     3*30*24, undef, 0    ],
        [ 3, 2, $master_tr2_rref_id, 2, 'external tests', undef,     5*30*24,     2, 1    ],
        [ 4, 3, $master_tr1_rref_id, 1, 'base',           undef,       10*24, undef, 0    ],
        [ 5, 3, $master_tr3_rref_id, 2, 'related part',   undef,    12*30*24,     4, 0    ],
        [ 6, 4, $master_tr1_rref_id, 1, 'sole',           undef,       undef, undef, 0    ],
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

=pod

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

    return 1;
};
