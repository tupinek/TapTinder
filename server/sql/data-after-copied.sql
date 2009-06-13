start transaction;

SET FOREIGN_KEY_CHECKS=0;

delete from fspath;
delete from fspath_select;


INSERT INTO fspath ( fspath_id, path, web_path, public, created, deleted, name, `desc` )
VALUES (
    1, '/home/jurosz/tt/server-data/cmdout',        'file/stabledb-cmdout',     1, NOW(), null, 'stable-db dir-cmdout', 'stable-db dir for command outputs'                 ), (
    2, '/home/jurosz/tt/server-data/patch',         'file/stabledb-patch',      1, NOW(), null, 'stable-db dir-patch',  'stable-db dir for patches'                         ), (
    3, '/home/jurosz/tt/server-data/archive',       'file/stabledb-archive',    1, NOW(), null, 'stable dir-archive',   'stable-db dir for files extracted from archives'   ), (
    4, '/home/jurosz/copy-tt/server-data/cmdout',   'file/cmdout',              1, NOW(), null, 'dir-cmdout',           'dir for command outputs'                           ), (
    5, '/home/jurosz/copy-tt/server-data/patch',    'file/patch',               1, NOW(), null, 'dir-patch',            'dir for patches'                                   ), (
    6, '/home/jurosz/copy-tt/server-data/archive',  'file/archive',             1, NOW(), null, 'dir-archive',          'dir for files extracted from archives'
);

INSERT INTO fspath_select ( fspath_select_id, fsfile_type_id, rep_path_id, fspath_id )
VALUES (
    1, 1,    1, 4  ), (
    2, 2,    1, 4  ), (
    3, 3, NULL, 5  ), (
    4, 4, NULL, 6
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

INSERT INTO ichannel_conf ( ichannel_conf_id, ibot_id, ichannel_id, errors_only, ireport_type_id, jobp_cmd_id, max_age )
VALUES (
    1, 1, 1, 1, 1, 4,   7*24    ), (
    2, 1, 2, 1, 1, 4,   7*24
);


commit;
