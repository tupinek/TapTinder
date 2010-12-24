use strict;
use warnings;
use utf8;

return sub {
    my ( $schema, $delete_all, $data ) = @_;
    
    # table: param_type
    $schema->resultset('param_type')->delete_all() if $delete_all;
    $schema->resultset('param_type')->populate([
        [ qw/ param_type_id name descr / ],
        [ 1,  'db_version', 'Version number of TapTinder database.'  ],
    ]);


    # table: param
    $schema->resultset('param')->delete_all() if $delete_all;
    $schema->resultset('param')->populate([
        [ qw/ param_id param_type_id value / ],
        [ 1, 1, $data->{db_version} ],
    ]);


    # table: trun_status
    $schema->resultset('trun_status')->delete_all() if $delete_all;
    $schema->resultset('trun_status')->populate([
        [ qw/ trun_status_id name descr / ],
        [ 1, 'loading started',  undef ],
        [ 2, 'ok',  undef ],
        [ 3, 'unknown error',  undef ],
        [ 4, 'extract error', 'archive extracting error' ],
        [ 5, 'no files found error', undef ],
        [ 6, 'no meta.yml file error', undef ],
        [ 7, 'meta match error', 'some files from meta.yml not found in archive, or archive contains more files than meta.yml' ],
    ]);


    # table: trest
    $schema->resultset('trest')->delete_all() if $delete_all;
    $schema->resultset('trest')->populate([
        [ qw/ trest_id name descr / ],
        [ 1, 'not seen',  undef ],
        [ 2, 'failed',    undef ],
        [ 3, 'todo',      undef ],
        [ 4, 'skip',      undef ],
        [ 5, 'bonus',     undef ],
        [ 6, 'ok',        undef ],
    ]);


    # table: msstatus
    $schema->resultset('msstatus')->delete_all() if $delete_all;
    $schema->resultset('msstatus')->populate([
        [ qw/ msstatus_id name descr / ],
        [  1, 'unknown status',            undef ],
        [  2, 'msession just created',     undef ],
        [  3, 'msession running',          undef ],
        [  4, 'paused by user',            undef ],
        [  5, 'paused by user - refresh',  undef ],
        [  6, 'stop by user',              undef ],
        [  7, 'stop by web server',        undef ],
        [  8, 'stop by anything else',     undef ],
    ]);


    # table: msabort_reason
    $schema->resultset('msabort_reason')->delete_all() if $delete_all;
    $schema->resultset('msabort_reason')->populate([
        [ qw/ msabort_reason_id name descr / ],
        [ 1, 'unknown reason',                undef ],
        [ 2, 'deprecated client revision',    undef ],
        [ 3, 'machine was disabled',          undef ],
        [ 4, 'bad client behavior',           undef ],
        [ 5, 'iterrupted by user',            undef ],
    ]);


    # table: msproc_status
    $schema->resultset('msproc_status')->delete_all() if $delete_all;
    $schema->resultset('msproc_status')->populate([
        [ qw/ msproc_status_id name descr / ],
        [  1, 'unknown status',         undef ],
        [  2, 'waiting for new job',    undef ],
        [  3, 'command preparation',    undef ],
        [  4, 'running command',        undef ],
    ]);


    # table: msproc_abort_reason
    $schema->resultset('msproc_abort_reason')->delete_all() if $delete_all;
    $schema->resultset('msproc_abort_reason')->populate([
        [ qw/ msproc_abort_reason_id name descr / ],
        [ 1, 'unknown reason',          undef ],
        [ 2, 'msproc just created',     undef ],
        [ 3, 'waiting for new job',     undef ],
        [ 4, 'command preparation',     undef ],
        [ 5, 'running command',         undef ],
        [ 6, 'killed by watchdog',      undef ],
        [ 7, 'see msession status',     undef ],
    ]);

    # table: fsfile_type
    $schema->resultset('fsfile_type')->delete_all() if $delete_all;
    $schema->resultset('fsfile_type')->populate([
        [ qw/ fsfile_type_id name descr / ],
        [ 1, 'command output',    undef    ],
        [ 2, 'command data',      undef    ],
        [ 3, 'patch',             undef    ],
        [ 4, 'extracted files',   undef    ],
    ]);


    # table: cmd
    $schema->resultset('cmd')->delete_all() if $delete_all;
    $schema->resultset('cmd')->populate([
        [ qw/ cmd_id name descr params / ],
        [
            1, 'get_src',
            'clean source code checkout/update, copy clean -> temp, check temp, create dir for results',
            'rep_path_id, rev_id'
        ], [
            2, 'prepare',
            'preparing project for TapTinder, add new files or apply patches',
            undef
        ], [
            3, 'patch',
            'applying patch',
            'patch_id'
        ], [
            4, 'perl_configure',
            'running command - perl Configure.pl',
            undef
        ], [
            5, 'make',
            'running command - make',
            undef
        ], [
            6, 'trun',
            'running command - make test, create and upload Test::Harness::Archive',
            undef
        ], [
            7, 'test',
            'running command - make test',
            undef
        ], [
            8, 'bench',
            'running command - perl utils/benchmark.pl',
            undef
        ], [
            9, 'install',
            'running command - make install',
            undef
        ], [
            10, 'clean',
            'cleaning machine, e.g. after install',
            undef
        ],
    ]);


    # table: cmd_status
    $schema->resultset('cmd_status')->delete_all() if $delete_all;
    $schema->resultset('cmd_status')->populate([
        [ qw/ cmd_status_id name descr / ],
        [ 1, 'created',   'created in DB, not started yet'    ],
        [ 2, 'running',   undef                               ],
        [ 3, 'paused',    'paused by user'                    ],
        [ 4, 'ok',        'finished ok'                       ],
        [ 5, 'stopped',   undef                               ],
        [ 6, 'killed',    'killed by watchdog',               ],
        [ 7, 'error',     'finished with error'               ],
    ]);


    # table: ireport_type
    $schema->resultset('ireport_type')->delete_all() if $delete_all;
    $schema->resultset('ireport_type')->populate([
        [ qw/ ireport_type_id name descr / ],
        [ 1, 'build report', '' ],
        [ 2, 'ttest report', '' ],
    ]);

    return 1;
};
