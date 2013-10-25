use strict;
use warnings;
use utf8;
use FindBin;
use File::Spec;
use Cwd 'abs_path';


return sub {
    my ( $schema, $delete_all, $data ) = @_;
    
    # table: user
    $schema->resultset('user')->populate([
        [ qw/ user_id login passwd first_name last_name irc_nick active created last_login / ],
        [ 2, 'coke', \'substring(MD5(RAND()), -8)', 'Will', 'Coleda', 'Coke', 1, \'NOW()', undef ],
    ]);


    # table: machine
    $schema->resultset('machine')->populate([
        [ qw/ machine_id name user_id passwd descr created ip cpuarch osname archname disabled prev_machine_id farm_id / ],
        [ 10, 'coke-darwin',  2, \'substring(MD5(RAND()), -8)', undef, \'NOW()', '',  'x86_64', 'darwin',  'i386-linux-thread-multi',  0, undef, undef   ],
    ]);

    # Parrot, Rakudo
    my $master_parrot_rref_rs = $schema->resultset('rref')->find(
        {
            'me.name' => 'master',
            'rcommit_id.rep_id' => 4, # default repo for tt-tr3 project, see data-dev.pl
        },
        {
            join => 'rcommit_id',
        }
    );
    my $master_parrot_rref_id = undef;
    $master_parrot_rref_id = $master_parrot_rref_rs->id if defined $master_parrot_rref_rs;



    # table: wconf_session
    $schema->resultset('wconf_session')->populate([
        [ qw/ wconf_session_id machine_id processes_num / ],
        [ 10, 10, 1  ],
    ]);


    # table: wconf_job
    $schema->resultset('wconf_job')->populate([
        [ qw/ wconf_job_id  wconf_session_id  rep_id                  rref_id  job_id  priority  / ],
        [               10,               10,      4,  $master_parrot_rref_id,      1,        1    ],
    ]);

    return 1;
};
