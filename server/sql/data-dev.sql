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

INSERT INTO user ( user_id, login, passwd, first_name, last_name, irc_nick, active, created, last_login )
VALUES (
    1, 'mj41', substring(MD5(RAND()), -8), 'Michal', 'Jurosz', 'mj41', 1, NOW(), NULL
);


INSERT INTO farm ( farm_id, name, has_same_hw, has_same_sw, `desc`  )
VALUES (
    1, 'vutbr.cz tapir cluster', 1, 0, 'Dedicated to TapTinder.'
);


INSERT INTO machine ( machine_id, name, user_id, passwd, `desc` , created, ip, cpuarch, osname, archname, disabled, prev_machine_id, farm_id )
VALUES (
    5, 'pc-jurosz2',    1, substring(MD5(RAND()), -8), NULL, NOW(), '147.229.5.124',  'i386',   'MSWin32', 'MSWin32-x86-multi-thread', 0, NULL, NULL   ), (
    6, 'tapir1',        1, substring(MD5(RAND()), -8), NULL, NOW(), '147.229.191.11', 'x86_64', 'linux',   'i386-linux-thread-multi',  0, NULL, 1      ), (
    7, 'tapir2',        1, substring(MD5(RAND()), -8), NULL, NOW(), '147.229.191.12', 'x86_64', 'linux',   'i386-linux-thread-multi',  0, NULL, 1
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
    1, 257, 1, 'tr1 A',     NULL    ), (
    2, 257, 2, 'tr1, tr2',  NULL    ), (
    3, 257, 3, 'tr1, tr3',  NULL    ), (
    4, 257, 4, 'tr1 B',     NULL
);


INSERT INTO jobp ( jobp_id, job_id, rep_path_id, `order`, name, `desc`, max_age, depends_on_id, extends )
VALUES (
    1, 1, 1, 1, 'sole',           NULL,     3*30*24, NULL, 0  ), (
    2, 2, 1, 1, 'base',           NULL,     3*30*24, NULL, 0  ), (
    3, 2, 2, 2, 'external tests', NULL,     5*30*24, 2,    1  ), (
    4, 3, 1, 1, 'base',           NULL,       10*24, NULL, 0  ), (
    5, 3, 3, 2, 'related part',   NULL,    12*30*24, 4,    0  ), (
    6, 4, 1, 1, 'sole',           NULL,        NULL, NULL, 0
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
    23, 5, 5, 6 ), (

    24, 6, 1, 1 ), (
    25, 6, 2, 2 ), (
    26, 6, 3, 4 ), (
    27, 6, 4, 5
);

INSERT INTO machine_job_conf ( machine_job_conf_id, machine_id, rep_id, rep_path_id, job_id, priority )
VALUES (
    1, 5, NULL, NULL, 1,    1  ), (

    2, 6, 1,    NULL, NULL, 1  ), (
    3, 6, NULL, NULL, 2,    2  ), (

    4, 7, 1,    NULL, NULL, 1  ), (
    5, 7, 1,    NULL, NULL, 2  ), (
    6, 7, NULL, NULL, NULL, 3
);

INSERT INTO fspath ( fspath_id, path, web_path, public, created, deleted, name, `desc` )
VALUES (
    1, '/home/jurosz/dev-tt/server-data/cmdout', 'file/cmdout', 1, NOW(), null, 'dir-cmdout', 'dir for command outputs'  ), (
    2, '/home/jurosz/dev-tt/server-data/patch',  'file/patch',  1, NOW(), null, 'dir-patch',  'dir for patches'
);

INSERT INTO fspath_select ( fspath_select_id, fsfile_type_id, rep_path_id, fspath_id )
VALUES (
    1, 1, 1, 1  ), (
    2, 1, 2, 1  ), (
    3, 1, 3, 1  ), (

    4, 2, 1, 1  ), (
    5, 2, 2, 1  ), (
    6, 2, 3, 1  ), (

    7, 3, 1, 2  ), (
    8, 3, 2, 2  ), (
    9, 3, 3, 2
);

INSERT INTO ibot ( ibot_id, nick, full_name, server, port, operator_id )
VALUES (
    1, 'ttbot', 'TapTinder bot.', 'irc.freenode.org', 6667, 1
);

INSERT INTO ichannel ( ichannel_id, name, ibot_id )
VALUES (
    1, '#taptinder-bottest1',   1   ), (
    2, '#taptinder-bottest2',   1
);


INSERT INTO ireport_type ( ireport_type_id, name, `desc` )
VALUES (
    1, 'build report', '' ), (
    2, 'ttest report', ''
);

INSERT INTO ichannel_conf ( ichannel_conf_id, ibot_id, ichannel_id, ireport_type_id, jobp_cmd_id )
VALUES (
    1, 1, 1, 1,  4      ), (
    2, 1, 1, 1,  9      ), (
    3, 1, 1, 2, 10
);

commit;
