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
delete from cmd;
delete from cmd_status;
delete from job;
delete from jobp;
delete from jobp_cmd;

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
delete from msjobp;
delete from msjobp_cmd;
delete from mslog;

delete from trun;
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
    1, 1, '0.11' -- ToDo
);

INSERT INTO trun_status ( trun_status_id, name, `desc` )
VALUES (
    1, 'loading started',  NULL ), (
    2, 'ok',  NULL ), (
    3, 'unknown error',  NULL ), (
    4, 'extract error', 'archive extracting error' ), (
    5, 'no files found error', NULL ), (
    6, 'no meta.yml file error', NULL ), (
    7, 'meta match error', 'some files from meta.yml not found in archive, or archive contains more files than meta.yml'
);


INSERT INTO trest ( trest_id, name, `desc` )
VALUES (
    1, 'not seen',  NULL ), (
    2, 'failed',    NULL ), (
    3, 'todo',      NULL ), (
    4, 'skip',      NULL ), (
    5, 'bonus',     NULL ), (
    6, 'ok',        NULL
);


INSERT INTO rep_change_type ( rep_change_type_id, abbr, `desc` )
VALUES (
    1, 'A', 'added'     ), (
    2, 'M', 'modified'  ), (
    3, 'D', 'deleted'   ), (
    4, 'R', 'replacing'
);


INSERT INTO msstatus ( msstatus_id, name, `desc` )
VALUES (
    1, 'unknown status',            NULL ), (
    2, 'msession just created',     NULL ), (
    3, 'waiting for new job',       NULL ), (
    4, 'command preparation',       NULL ), (
    5, 'running command',           NULL ), (
    6, 'paused by user',            NULL ), (
    7, 'stop by user',              NULL ), (
    8, 'stop by web server',        NULL ), (
    9, 'stop by anything else',     NULL ), (
   10, 'paused by user - refresh',  NULL
);


INSERT INTO msabort_reason ( msabort_reason_id, name, `desc` )
VALUES (
    1, 'unknown reason',                NULL ), (
    2, 'deprecated client revision',    NULL ), (
    3, 'machine was disabled',          NULL ), (
    4, 'bad client behavior',           NULL ), (
    5, 'iterrupted by user',            NULL
);


INSERT INTO fsfile_type ( fsfile_type_id, name, `desc` )
VALUES (
    1, 'command output', NULL ), (
    2, 'command data', NULL ), (
    3, 'patch', NULL
);


INSERT INTO cmd ( cmd_id, name, `desc`, params )
VALUES (
    1, 'get_src',
    'clean source code checkout/update, copy clean -> temp, check temp, create dir for results',
    'rep_path_id, rev_id'
), (
    2, 'prepare',
    'preparing project for TapTinder, add new files or apply patches',
    null
), (
    3, 'patch',
    'applying patch',
    'patch_id'
), (
    4, 'perl_configure',
    'running command - perl Configure.pl',
    null
), (
    5, 'make',
    'running command - make',
    null
), (
    6, 'trun',
    'running command - make test, create and upload Test::Harness::Archive',
    null
), (
    7, 'test',
    'running command - make test',
    null
), (
    8, 'bench',
    'running command - perl utils/benchmark.pl',
    null
), (
    9, 'install',
    'running command - make install',
    null
), (
    10, 'clean',
    'cleaning machine, e.g. after install',
    null
);


INSERT INTO cmd_status ( cmd_status_id, name, `desc` )
VALUES (
    1, 'created',   'created in DB, not started yet'    ), (
    2, 'running',   NULL                                ), (
    3, 'paused',    'paused by user'                    ), (
    4, 'ok',        'finished ok'                       ), (
    5, 'stopped',   NULL                                ), (
    6, 'error',     'finished with error'
);


INSERT INTO ireport_type ( ireport_type_id, name, `desc` )
VALUES (
    1, 'build report', '' ), (
    2, 'ttest report', ''
);


commit;
