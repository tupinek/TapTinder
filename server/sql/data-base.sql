start transaction;

SET FOREIGN_KEY_CHECKS=0;

-- delete data inserted below
delete from user;
delete from machine;
delete from farm;
delete from project;
delete from rep;
delete from trest;
delete from rep_change_type;
delete from param_type;
delete from param;
delete from msstatus;
delete from msabort_reason;
delete from fsfile_type;

-- delete job tables
delete from job;
delete from job_part;
delete from command;
delete from job_part_command;
delete from command_status;

-- delete data from tables imported by cron/repository-update.pl
delete from rep_author;
delete from rep_path;
delete from rev;
delete from rev_rep_path;
delete from rep_file;
delete from rep_file_change;
delete from rep_file_change_from;

-- delete others
delete from patch;
delete from fsfile;
delete from fspath;
delete from fspath_select;

-- delete submited tests
delete from msession;
delete from msjob;
delete from msjob_command;
delete from mslog;

delete from build;
delete from build_conf;
delete from trun;
delete from trun_conf;
delete from rep_test;
delete from tfile;
delete from ttest;
delete from tskipall_msg;
delete from tdiag_msg;


SET FOREIGN_KEY_CHECKS=1;

INSERT INTO param_type ( param_type_id, name, `desc` )
VALUES (
1, 'db_version', 'Version number of TapTinder database.'
);

INSERT INTO param ( param_id, param_type_id, value )
VALUES (
1, 1, '0.0.03'
);


INSERT INTO user ( user_id, login, passwd, first_name, last_name, active, created, last_login )
VALUES (
1, 'mj41', substring(MD5(RAND()), -8), 'Michal', 'Jurosz', 1, NOW(), NULL
);


INSERT INTO farm ( farm_id, name, has_same_hw, has_same_sw, `desc`  )
VALUES (
1, 'vutbr.cz web cluster', 1, 1, 'some computer power is always availible'
);


INSERT INTO machine ( machine_id, name, user_id, passwd, `desc`, created, ip, cpuarch, osname, archname, disabled, prev_machine_id, farm_id )
VALUES (
1, 'dbtest', 1, substring(MD5(RAND()), -8), NULL, NOW(), '147.229.2.84', 'i386', 'linux', 'i386-linux-thread-multi', 0, NULL, NULL
);


INSERT INTO machine ( machine_id, name, user_id, passwd, `desc`, created, ip, cpuarch, osname, archname, disabled, prev_machine_id, farm_id )
VALUES (
2, 'pc-jurosz', 1, substring(MD5(RAND()), -8), NULL, NOW(), '147.229.5.124', 'i386', 'MSWin32', 'MSWin32-x86-multi-thread', 0, NULL, NULL
);

INSERT INTO machine ( machine_id, name, user_id, passwd, `desc` , created, ip, cpuarch, osname, archname, disabled, prev_machine_id, farm_id )
VALUES (
3, 'shreck1', 1, substring(MD5(RAND()), -8), NULL, NOW(), '147.229.2.90', 'i386', 'linux', 'i386-linux-thread-multi', 1, NULL, 1
);

INSERT INTO machine ( machine_id, name, user_id, passwd, `desc` , created, ip, cpuarch, osname, archname, disabled, prev_machine_id, farm_id )
VALUES (
4, 'shreck2', 1, substring(MD5(RAND()), -8), NULL, NOW(), '147.229.2.90', 'i386', 'linux', 'i386-linux-thread-multi', 1, NULL, 1
);

INSERT INTO machine ( machine_id, name, user_id, passwd, `desc` , created, ip, cpuarch, osname, archname, disabled, prev_machine_id, farm_id )
VALUES (
5, 'shreck3', 1, substring(MD5(RAND()), -8), NULL, NOW(), '147.229.2.90', 'i386', 'linux', 'i386-linux-thread-multi', 1, NULL, 1
);

INSERT INTO machine ( machine_id, name, user_id, passwd, `desc` , created, ip, cpuarch, osname, archname, disabled, prev_machine_id, farm_id )
VALUES (
6, 'ent', 1, substring(MD5(RAND()), -8), NULL, NOW(), '147.229.2.49', 'i386', 'linux', 'i386-linux-thread-multi', 1, NULL, 1
);

INSERT INTO machine ( machine_id, name, user_id, passwd, `desc` , created, ip, cpuarch, osname, archname, disabled, prev_machine_id, farm_id )
VALUES (
7, 'pc-jurosz (new)', 1, substring(MD5(RAND()), -8), NULL, NOW(), '147.229.5.124', 'i386', 'MSWin32', 'MSWin32-x86-multi-thread', 0, NULL, NULL
);


INSERT INTO project ( project_id, name, url, `desc`  )
VALUES (
1, 'Parrot', 'http://www.parrotcode.org/', 'Parrot is a virtual machine designed to efficiently compile and execute bytecode for dynamic languages. Parrot currently hosts a variety of language implementations in various stages of completion, including Tcl, Javascript, Ruby, Lua, Scheme, PHP, Python, Perl 6, APL, and a .NET bytecode translator.'
);


INSERT INTO rep ( rep_id, project_id, active, name, path, `desc`  )
VALUES (
1, 1, 1, 'parrot repository', 'http://svn.perl.org/parrot/', ''
);


INSERT INTO trest ( trest_id, name, `desc` )
VALUES (
0, 'not seen', NULL
), (
1, 'failed', NULL
), (
2, 'unknown', NULL
), (
3, 'todo', NULL
), (
4, 'bonus', NULL
), (
5, 'skip', NULL
), (
'6', 'ok', NULL
);


INSERT INTO rep_change_type ( rep_change_type_id, abbr, `desc` )
VALUES (
1, 'A', 'added'
), (
2, 'M', 'modified'
), (
3, 'D', 'deleted'
), (
4, 'R', 'replacing'
);


INSERT INTO msstatus ( msstatus_id, name, `desc` )
VALUES (
1, 'unknown status', NULL
), (
2, 'msession just created', NULL
), (
3, 'waiting for new job', NULL
), (
4, 'running command', NULL
), (
5, 'stop by user', NULL
), (
6, 'stop by web server', NULL
), (
7, 'stop by anything else', NULL
);


INSERT INTO msabort_reason ( msabort_reason_id, name, `desc` )
VALUES (
1, 'unknown reason', NULL
), (
2, 'bad client behavior', NULL
), (
3, 'deprecated client revision', NULL
);


INSERT INTO fsfile_type ( fsfile_type_id, name, `desc` )
VALUES (
1, 'command output', NULL
), (
2, 'patch', NULL
);


INSERT INTO job ( job_id, rep_id, rep_path_id, client_min_rev, priority, name, `desc` )
VALUES (
1, 1, NULL, 150, 1, 'Parrot only', NULL
), (
2, 1, NULL, 150, 1, 'Parrot and Rakudo', NULL
);


INSERT INTO job_part ( job_part_id, job_id, `order`, name, `desc` )
VALUES (
1, 1, 1, 'sole', NULL
), (
2, 2, 1, 'Parrot', NULL
), (
3, 2, 2, 'Rakudo spectests', NULL
);


INSERT INTO command ( command_id, name, `desc` )
VALUES (
1, 'get_src', 'clean source code checkout/update'
), (
2, 'prepare', 'preparing job environment (copy clean -> temp, check temp, create dir for results, chdir)'
), (
3, 'patch', 'applying patch'
), (
4, 'perl_configure', 'running command - perl Configure.pl'
), (
5, 'make', 'running command - make'
), (
6, 'trun ', 'running command - perl t/taptinder_harness --yaml'
), (
7, 'test', 'running command - make test'
), (
8, 'smolder', 'running command - make smolder'
), (
9, 'bench', 'running command - perl utils/benchmark.pl'
), (
10, 'install', 'running command - make install'
), (
11, 'clean', 'cleaning machine, e.g. after install'
), (
12, 'externtests', 'external source code test checkout/update'
);


INSERT INTO job_part_command ( job_part_command_id, job_part_id, `order`, command_id )
VALUES (
1, 1, 1, 1
), (
2, 1, 2, 2
), (
3, 1, 3, 4
), (
4, 1, 4, 5
), (
5, 1, 5, 6
), (


6, 2, 1, 1
), (
7, 2, 2, 2
), (
8, 2, 3, 4
), (
9, 2, 4, 5
), (
10, 2, 5, 6
), (

12, 3, 1, 2
), (
15, 3, 2, 11
), (
14, 3, 3, 6

);


INSERT INTO command_status ( command_status_id, name, `desc` )
VALUES (
1, 'running', NULL
), (
2, 'ok', 'finished ok'
), (
3, 'stopped', NULL
), (
4, 'error', 'finished with error'
);

commit;

