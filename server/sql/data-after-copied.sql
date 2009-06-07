start transaction;

SET FOREIGN_KEY_CHECKS=0;

delete from fspath;
delete from fspath_select;


INSERT INTO fspath ( fspath_id, path, web_path, public, created, deleted, name, `desc` )
VALUES (
    1, '/home/jurosz/tt/server-data/cmdout', 'file/stabledb-cmdout', 1, NOW(), null, 'stable-db dir-cmdout', 'stable-db dir for command outputs'  ), (
    2, '/home/jurosz/tt/server-data/patch',  'file/stabledb-patch',  1, NOW(), null, 'stable-db dir-patch',  'stable-db dir for patches' ), (
    3, '/home/jurosz/copy-tt/server-data/cmdout', 'file/cmdout', 1, NOW(), null, 'dir-cmdout', 'dir for command outputs'  ), (
    4, '/home/jurosz/copy-tt/server-data/patch',  'file/patch',  1, NOW(), null, 'dir-patch',  'dir for patches'
);

INSERT INTO fspath_select ( fspath_select_id, fsfile_type_id, rep_path_id, fspath_id )
VALUES (
    1, 1, 1, 3  ), (
    2, 2, 1, 3  ), (
    3, 3, 1, 4
);


delete from ibot_log;
delete from ichannel_conf;
delete from ichannel;
delete from ibot;

INSERT INTO ibot ( ibot_id, nick, full_name, server, port, operator_id )
VALUES (
    1, 'ttbot-copy', 'TapTinder bot (copy).', 'irc.freenode.org', 6667, 1
);

INSERT INTO ichannel ( ichannel_id, name )
VALUES (
    1, '#taptinder-bottest1'    ), (
    2, '#taptinder-bottest2'
);

INSERT INTO ichannel_conf ( ichannel_conf_id, ibot_id, ichannel_id, errors_only, ireport_type_id, jobp_cmd_id )
VALUES (
    1, 1, 1, 1, 1, 4    ), (
    2, 1, 2, 1, 1, 4
);


commit;
