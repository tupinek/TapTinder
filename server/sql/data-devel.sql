-- data for devel TapTinder instance - TapTinder self testing and development

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
    1, 'TapTinder-tr1', 'http://dev.taptinder.org/wiki/TapTinder-tr1', 'TapTinder test repository 1' ), (
    2, 'TapTinder-tr2', 'http://dev.taptinder.org/wiki/TapTinder-tr2', 'TapTinder test repository 2' ), (
    3, 'TapTinder-tr3', 'http://dev.taptinder.org/wiki/TapTinder-tr3', 'TapTinder test repository 3'
);


INSERT INTO rep ( rep_id, project_id, active, name, path, `desc`, default_layout )
VALUES (
    1, 1, 1, 'default', 'http://dev.taptinder.org/svn/taptinder-tr1/', 'Parrot like repository',                            1 ), (
    2, 2, 1, 'default', 'http://dev.taptinder.org/svn/taptinder-tr2/', 'Pugs like repository (Rakudo external spectests)',  0 ), (
    3, 3, 1, 'default', 'http://dev.taptinder.org/svn/taptinder-tr3/', 'ParTcl like repository, external repository',       1
);


INSERT INTO job ( job_id, client_min_rev, priority, name, `desc` )
VALUES (
    1, 150, 1, 'tr1',       NULL    ), (
    2, 150, 2, 'tr1, tr2',  NULL    ), (
    3, 150, 3, 'tr1, tr3',  NULL
);


INSERT INTO jobp ( jobp_id, job_id, rep_path_id, `order`, name, `desc`, depends_on_id, extends )
VALUES (
    1, 1, 1, 1, 'sole',           NULL, NULL, 0  ), (
    2, 2, 1, 1, 'base',           NULL, NULL, 0  ), (
    3, 2, 2, 2, 'external tests', NULL, 2,    1  ), (
    4, 3, 1, 1, 'base',           NULL, NULL, 0  ), (
    5, 3, 3, 2, 'related part',   NULL, 4,    0
);

INSERT INTO jobp_cmd ( jobp_cmd_id, jobp_id, `order`, cmd_id )
VALUES (
    1, 1, 1, 1 ), (
    2, 1, 2, 2 ), (
    3, 1, 3, 4 ), (
    4, 1, 4, 5 ), (
    5, 1, 5, 6 ), (


    6,  2, 1, 1 ), (
    7,  2, 2, 2 ), (
    8,  2, 3, 4 ), (
    9,  2, 4, 5 ), (
    10, 2, 5, 6 ), (

    11, 3, 1, 1 ), (
    12, 3, 2, 2 ), (
    13, 3, 3, 6 ), (


    14, 4, 1, 1 ), (
    15, 4, 2, 2 ), (
    16, 4, 3, 4 ), (
    17, 4, 4, 5 ), (
    18, 4, 5, 6 ), (

    19, 5, 1, 1 ), (
    20, 5, 2, 2 ), (
    21, 5, 3, 4 ), (
    22, 5, 4, 5 ), (
    23, 5, 5, 6
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
    1, '/home/jurosz/taptinder-dev/server-data/cmdout', 'file/cmdout', 1, NOW(), null, 'dir-cmdout', 'dir for command outputs'  ), (
    2, '/home/jurosz/taptinder-dev/server-data/patch',  'file/patch',  1, NOW(), null, 'dir-patch',  'dir for patches'
);

INSERT INTO fspath_select ( fspath_select_id, fsfile_type_id, rep_path_id, fspath_id )
VALUES (
    1, 1, 1, 1  ), (
    2, 1, 2, 1  ), (
    3, 1, 3, 1  ), (
    4, 2, 1, 2  ), (
    5, 2, 2, 2  ), (
    6, 2, 3, 2
);

commit;
