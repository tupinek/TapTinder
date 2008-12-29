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
delete from job_part;
delete from job_part_command;


-- insert new data

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
1, 'Parrot', 'http://www.parrot.org/', 'Parrot is a virtual machine designed to efficiently compile and execute bytecode for dynamic languages. Parrot currently hosts a variety of language implementations in various stages of completion, including Tcl, Javascript, Ruby, Lua, Scheme, PHP, Python, Perl 6, APL, and a .NET bytecode translator.'
);

INSERT INTO project ( project_id, name, url, `desc`  )
VALUES (
2, 'Pugs', 'http://www.pugscode.org/', 'Pugs is an implementation of Perl 6, written in Haskell. Pugs repository contains many others Perl 6 related projects (Synopsis, official Perl 6 test suite).'
);


INSERT INTO rep ( rep_id, project_id, active, name, path, `desc`, default_layout  )
VALUES (
1, 1, 1, 'base', 'http://svn.perl.org/parrot/', '', 1
);

INSERT INTO rep ( rep_id, project_id, active, name, path, `desc`, default_layout  )
VALUES (
1, 1, 1, 'base', 'http://svn.pugscode.org/pugs/', '', 0
);


INSERT INTO job ( job_id, rep_id, rep_path_id, client_min_rev, priority, name, `desc` )
VALUES (
1, 1, NULL, 150, 1, 'Parrot only', NULL
), (
2, 1, NULL, 150, 1, 'Parrot and Rakudo', NULL
);


INSERT INTO job_part ( job_part_id, job_id, `order`, name, `desc`, depends_on_id )
VALUES (
1, 1, 1, 'sole', NULL, NULL
), (
2, 2, 1, 'Parrot', NULL, NULL
), (
3, 2, 2, 'Rakudo spectests', NULL, 2
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

11, 3, 1, 1
), (
12, 3, 2, 2
), (
13, 3, 3, 6

);

commit;
