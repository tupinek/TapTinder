start transaction;

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


commit;