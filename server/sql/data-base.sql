start transaction;

SET FOREIGN_KEY_CHECKS=0;

delete from user;
delete from client;
delete from project;
delete from rep;


SET FOREIGN_KEY_CHECKS=1;

INSERT INTO `user` ( `user_id` , `login` , `passwd` , `active` , `created` , `last_login` )
VALUES (
'1', 'mj41', substring(MD5(RAND()), -8), '1', NOW(), NULL
);


INSERT INTO `client` ( `client_id` , `passwd` , `user_id` , `created` , `last_login` , `ip` , `cpuarch` , `osname` , `archname` , `active` , `prev_client_id` )
VALUES (
'1', substring(MD5(RAND()), -8), '1', NOW(), NULL , '147.229.2.84', 'i386', 'linux', 'i386-linux-thread-multi', '1', NULL
);


INSERT INTO `client` ( `client_id` , `passwd` , `user_id` , `created` , `last_login` , `ip` , `cpuarch` , `osname` , `archname` , `active` , `prev_client_id` )
VALUES (
'2', substring(MD5(RAND()), -8), '1', NOW(), NULL , '147.229.5.124', 'i386', 'MSWin32', 'MSWin32-x86-multi-thread', '1', NULL
); 


INSERT INTO `project` ( `project_id` , `name` , `url` , `info` )
VALUES (
'1', 'parrot', 'http://www.parrotcode.org/', 'Parrot is a virtual machine designed to efficiently compile and execute bytecode for dynamic languages. Parrot currently hosts a variety of language implementations in various stages of completion, including Tcl, Javascript, Ruby, Lua, Scheme, PHP, Python, Perl 6, APL, and a .NET bytecode translator.'
);


INSERT INTO `rep` ( `rep_id` , `project_id` , `active` , `name` , `path` , `info` )
VALUES (
'1', '1', '1', 'parrot repository', 'http://svn.perl.org/parrot/', ''
);


commit;