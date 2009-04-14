-- data for stable TapTinder instance - Parrot and Rakudo testing

start transaction;

SET FOREIGN_KEY_CHECKS=0;


-- delete old data

delete from user;
delete from farm;
delete from machine;
delete from project;
delete from rep;

delete from job;
delete from jobp;
delete from jobp_cmd;
delete from machine_job_conf;

delete from fspath;
delete from fspath_select;

-- insert new data

INSERT INTO user ( user_id, login, passwd, first_name, last_name, active, created, last_login )
VALUES (
    1, 'mj41', substring(MD5(RAND()), -8), 'Michal', 'Jurosz', 1, NOW(), NULL
);


INSERT INTO farm ( farm_id, name, has_same_hw, has_same_sw, `desc`  )
VALUES (
    1, 'vutbr.cz web cluster',   1, 1, 'Some computer power is always available.' ), (
    2, 'vutbr.cz tapir cluster', 1, 0, 'Dedicated to TapTinder.'
);


INSERT INTO machine ( machine_id, name, user_id, passwd, `desc` , created, ip, cpuarch, osname, archname, disabled, prev_machine_id, farm_id )
VALUES (
    1, 'shreck1',           1, substring(MD5(RAND()), -8), NULL, NOW(), '147.229.2.90',   'i386',   'linux',   'i386-linux-thread-multi',  0, NULL, 1      ), (
    2, 'shreck2',           1, substring(MD5(RAND()), -8), NULL, NOW(), '147.229.2.90',   'i386',   'linux',   'i386-linux-thread-multi',  0, NULL, 1      ), (
    3, 'shreck3',           1, substring(MD5(RAND()), -8), NULL, NOW(), '147.229.2.90',   'i386',   'linux',   'i386-linux-thread-multi',  0, NULL, 1      ), (
    4, 'ent',               1, substring(MD5(RAND()), -8), NULL, NOW(), '147.229.2.49',   'i386',   'linux',   'i386-linux-thread-multi',  1, NULL, NULL   ), (
    5, 'pc-jurosz (new)',   1, substring(MD5(RAND()), -8), NULL, NOW(), '147.229.5.124',  'i386',   'MSWin32', 'MSWin32-x86-multi-thread', 0, NULL, NULL   ), (
    6, 'tapir1',            1, substring(MD5(RAND()), -8), NULL, NOW(), '147.229.191.11', 'x86_64', 'linux',   'i386-linux-thread-multi',  0, NULL, 2      ), (
    7, 'tapir2',            1, substring(MD5(RAND()), -8), NULL, NOW(), '147.229.191.12', 'x86_64', 'linux',   'i386-linux-thread-multi',  0, NULL, 2
);


INSERT INTO project ( project_id, name, url, `desc`  )
VALUES (
    1, 'Parrot', 'http://www.parrot.org/', 'Parrot is a virtual machine designed to efficiently compile and execute bytecode for dynamic languages. Parrot currently hosts a variety of language implementations in various stages of completion, including Tcl, Javascript, Ruby, Lua, Scheme, PHP, Python, Perl 6, APL, and a .NET bytecode translator.'  ), (
    2, 'Pugs', 'http://www.pugscode.org/', 'Pugs is an implementation of Perl 6, written in Haskell. Pugs repository contains many others Perl 6 related projects (Synopsis, official Perl 6 test suite).'
);


INSERT INTO rep ( rep_id, project_id, active, name, path, `desc`, default_layout  )
VALUES (
    1, 1, 1, 'default', 'https://svn.parrot.org/parrot/', '', 1    ), (
    2, 2, 1, 'default', 'http://svn.pugscode.org/pugs/',  '', 0
);


INSERT INTO job ( job_id, client_min_rev, priority, name, `desc` )
VALUES (
    1, 257, 1, 'Parrot make only',  NULL    ), (
    2, 257, 2, 'Parrot test',       NULL
);

INSERT INTO jobp ( jobp_id, job_id, rep_path_id, `order`, name, `desc`, max_age, depends_on_id, extends )
VALUES (
    1, 1, 1, 1, 'sole', NULL,    7*24,  NULL, 0  ), (
    2, 2, 1, 1, 'sole', NULL,   31*24,  NULL, 0
);

INSERT INTO jobp_cmd ( jobp_cmd_id, jobp_id, `order`, cmd_id )
VALUES (
     1, 1, 1, 1  ), (
     2, 1, 2, 2  ), (
     3, 1, 3, 4  ), (
     4, 1, 4, 5  ), (

     6, 2, 1, 1 ), (
     7, 2, 2, 2 ), (
     8, 2, 3, 4 ), (
     9, 2, 4, 5 ), (
    10, 2, 5, 6
);


INSERT INTO machine_job_conf ( machine_job_conf_id, machine_id, rep_id, rep_path_id, job_id, priority )
VALUES (
    1, 5, NULL, NULL, 1,    1  ), (
    2, 6, 1,    NULL, NULL, 1  ), (
    3, 6, NULL, NULL, 2,    2  ), (
    4, 7, 1,    NULL, NULL, 1  ), (
    5, 7, NULL, NULL, 2,    2
);

INSERT INTO fspath ( fspath_id, path, web_path, public, created, deleted, name, `desc` )
VALUES (
    1, '/home/jurosz/tt/server-data/cmdout', 'file/cmdout', 1, NOW(), null, 'dir-cmdout', 'dir for command outputs'  ), (
    2, '/home/jurosz/tt/server-data/patch',  'file/patch',  1, NOW(), null, 'dir-patch',  'dir for patches'
);

INSERT INTO fspath_select ( fspath_select_id, fsfile_type_id, rep_path_id, fspath_id )
VALUES (
    1, 1, 1, 1  ), (
    2, 2, 1, 1  ), (
    3, 3, 1, 2
);

commit;
