

package TapTinder::DB::Schema::rep_path;
use base 'DBIx::Class';
use strict;
use warnings;

__PACKAGE__->load_components(qw/Core ViewMD/);
__PACKAGE__->table('rep_path');


__PACKAGE__->add_columns(
    'rep_path_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 1,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'rep_path_id',
      'is_nullable' => 0,
      'size' => '11'
    },
    'rep_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 1,
      'name' => 'rep_id',
      'is_nullable' => 0,
      'size' => '11'
    },
    'path' => {
      'data_type' => 'VARCHAR',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'path',
      'is_nullable' => 0,
      'size' => '255'
    },
    'rev_num_from' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'rev_num_from',
      'is_nullable' => 0,
      'size' => '11'
    },
    'rev_num_to' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => 'NULL',
      'is_foreign_key' => 0,
      'name' => 'rev_num_to',
      'is_nullable' => 1,
      'size' => '11'
    },
);
__PACKAGE__->set_primary_key('rep_path_id');


package TapTinder::DB::Schema::trun_conf;
use base 'DBIx::Class';
use strict;
use warnings;

__PACKAGE__->load_components(qw/Core ViewMD/);
__PACKAGE__->table('trun_conf');


__PACKAGE__->add_columns(
    'trun_conf_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 1,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'trun_conf_id',
      'is_nullable' => 0,
      'size' => '11'
    },
    'hash' => {
      'data_type' => 'VARCHAR',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'hash',
      'is_nullable' => 0,
      'size' => '50'
    },
    'harness_args' => {
      'data_type' => 'VARCHAR',
      'is_auto_increment' => 0,
      'default_value' => 'NULL',
      'is_foreign_key' => 0,
      'name' => 'harness_args',
      'is_nullable' => 1,
      'size' => '255'
    },
    'alias_conf_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => 'NULL',
      'is_foreign_key' => 1,
      'name' => 'alias_conf_id',
      'is_nullable' => 1,
      'size' => '11'
    },
);
__PACKAGE__->set_primary_key('trun_conf_id');


package TapTinder::DB::Schema::rev_rep_path;
use base 'DBIx::Class';
use strict;
use warnings;

__PACKAGE__->load_components(qw/Core ViewMD/);
__PACKAGE__->table('rev_rep_path');


__PACKAGE__->add_columns(
    'rev_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 1,
      'name' => 'rev_id',
      'is_nullable' => 0,
      'size' => '11'
    },
    'rep_path_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 1,
      'name' => 'rep_path_id',
      'is_nullable' => 0,
      'size' => '11'
    },
);


package TapTinder::DB::Schema::jobp_cmd;
use base 'DBIx::Class';
use strict;
use warnings;

__PACKAGE__->load_components(qw/Core ViewMD/);
__PACKAGE__->table('jobp_cmd');


__PACKAGE__->add_columns(
    'jobp_cmd_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 1,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'jobp_cmd_id',
      'is_nullable' => 0,
      'size' => '11'
    },
    'jobp_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 1,
      'name' => 'jobp_id',
      'is_nullable' => 0,
      'size' => '11'
    },
    'order' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'order',
      'is_nullable' => 0,
      'size' => '11'
    },
    'cmd_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 1,
      'name' => 'cmd_id',
      'is_nullable' => 0,
      'size' => '11'
    },
    'params' => {
      'data_type' => 'TEXT',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'params',
      'is_nullable' => 1,
      'size' => '65535'
    },
);
__PACKAGE__->set_primary_key('jobp_cmd_id');


package TapTinder::DB::Schema::rep_change_type;
use base 'DBIx::Class';
use strict;
use warnings;

__PACKAGE__->load_components(qw/Core ViewMD/);
__PACKAGE__->table('rep_change_type');


__PACKAGE__->add_columns(
    'rep_change_type_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'rep_change_type_id',
      'is_nullable' => 0,
      'size' => '11'
    },
    'abbr' => {
      'data_type' => 'VARCHAR',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'abbr',
      'is_nullable' => 0,
      'size' => '1'
    },
    'desc' => {
      'data_type' => 'VARCHAR',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'desc',
      'is_nullable' => 0,
      'size' => '10'
    },
);
__PACKAGE__->set_primary_key('rep_change_type_id');


package TapTinder::DB::Schema::user;
use base 'DBIx::Class';
use strict;
use warnings;

__PACKAGE__->load_components(qw/Core ViewMD/);
__PACKAGE__->table('user');


__PACKAGE__->add_columns(
    'user_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 1,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'user_id',
      'is_nullable' => 0,
      'size' => '11'
    },
    'login' => {
      'data_type' => 'VARCHAR',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'login',
      'is_nullable' => 0,
      'size' => '20'
    },
    'passwd' => {
      'data_type' => 'VARCHAR',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'passwd',
      'is_nullable' => 0,
      'size' => '20'
    },
    'first_name' => {
      'data_type' => 'VARCHAR',
      'is_auto_increment' => 0,
      'default_value' => '',
      'is_foreign_key' => 0,
      'name' => 'first_name',
      'is_nullable' => 0,
      'size' => '255'
    },
    'last_name' => {
      'data_type' => 'VARCHAR',
      'is_auto_increment' => 0,
      'default_value' => '',
      'is_foreign_key' => 0,
      'name' => 'last_name',
      'is_nullable' => 0,
      'size' => '255'
    },
    'active' => {
      'data_type' => 'BOOLEAN',
      'is_auto_increment' => 0,
      'default_value' => '1',
      'is_foreign_key' => 0,
      'name' => 'active',
      'is_nullable' => 0,
      'size' => 0
    },
    'created' => {
      'data_type' => 'DATETIME',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'created',
      'is_nullable' => 0,
      'size' => 0
    },
    'last_login' => {
      'data_type' => 'DATETIME',
      'is_auto_increment' => 0,
      'default_value' => 'NULL',
      'is_foreign_key' => 0,
      'name' => 'last_login',
      'is_nullable' => 1,
      'size' => 0
    },
);
__PACKAGE__->set_primary_key('user_id');


package TapTinder::DB::Schema::param;
use base 'DBIx::Class';
use strict;
use warnings;

__PACKAGE__->load_components(qw/Core ViewMD/);
__PACKAGE__->table('param');


__PACKAGE__->add_columns(
    'param_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 1,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'param_id',
      'is_nullable' => 0,
      'size' => '11'
    },
    'param_type_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 1,
      'name' => 'param_type_id',
      'is_nullable' => 0,
      'size' => '11'
    },
    'value' => {
      'data_type' => 'VARCHAR',
      'is_auto_increment' => 0,
      'default_value' => 'NULL',
      'is_foreign_key' => 0,
      'name' => 'value',
      'is_nullable' => 1,
      'size' => '255'
    },
);
__PACKAGE__->set_primary_key('param_id');


package TapTinder::DB::Schema::msession;
use base 'DBIx::Class';
use strict;
use warnings;

__PACKAGE__->load_components(qw/Core ViewMD/);
__PACKAGE__->table('msession');


__PACKAGE__->add_columns(
    'msession_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 1,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'msession_id',
      'is_nullable' => 0,
      'size' => '11'
    },
    'machine_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 1,
      'name' => 'machine_id',
      'is_nullable' => 0,
      'size' => '11'
    },
    'client_rev' => {
      'data_type' => 'VARCHAR',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'client_rev',
      'is_nullable' => 0,
      'size' => '21'
    },
    'pid' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'pid',
      'is_nullable' => 0,
      'size' => '11'
    },
    'start_time' => {
      'data_type' => 'DATETIME',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'start_time',
      'is_nullable' => 0,
      'size' => 0
    },
    'end_time' => {
      'data_type' => 'DATETIME',
      'is_auto_increment' => 0,
      'default_value' => 'NULL',
      'is_foreign_key' => 0,
      'name' => 'end_time',
      'is_nullable' => 1,
      'size' => 0
    },
    'abort_reason_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => 'NULL',
      'is_foreign_key' => 1,
      'name' => 'abort_reason_id',
      'is_nullable' => 1,
      'size' => '11'
    },
);
__PACKAGE__->set_primary_key('msession_id');


package TapTinder::DB::Schema::build_conf;
use base 'DBIx::Class';
use strict;
use warnings;

__PACKAGE__->load_components(qw/Core ViewMD/);
__PACKAGE__->table('build_conf');


__PACKAGE__->add_columns(
    'build_conf_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 1,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'build_conf_id',
      'is_nullable' => 0,
      'size' => '11'
    },
    'hash' => {
      'data_type' => 'VARCHAR',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'hash',
      'is_nullable' => 0,
      'size' => '50'
    },
    'cc' => {
      'data_type' => 'VARCHAR',
      'is_auto_increment' => 0,
      'default_value' => 'NULL',
      'is_foreign_key' => 0,
      'name' => 'cc',
      'is_nullable' => 1,
      'size' => '255'
    },
    'devel' => {
      'data_type' => 'VARCHAR',
      'is_auto_increment' => 0,
      'default_value' => 'NULL',
      'is_foreign_key' => 0,
      'name' => 'devel',
      'is_nullable' => 1,
      'size' => '255'
    },
    'optimize' => {
      'data_type' => 'VARCHAR',
      'is_auto_increment' => 0,
      'default_value' => 'NULL',
      'is_foreign_key' => 0,
      'name' => 'optimize',
      'is_nullable' => 1,
      'size' => '255'
    },
    'alias_conf_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => 'NULL',
      'is_foreign_key' => 1,
      'name' => 'alias_conf_id',
      'is_nullable' => 1,
      'size' => '11'
    },
);
__PACKAGE__->set_primary_key('build_conf_id');


package TapTinder::DB::Schema::msabort_reason;
use base 'DBIx::Class';
use strict;
use warnings;

__PACKAGE__->load_components(qw/Core ViewMD/);
__PACKAGE__->table('msabort_reason');


__PACKAGE__->add_columns(
    'msabort_reason_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 1,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'msabort_reason_id',
      'is_nullable' => 0,
      'size' => '11'
    },
    'name' => {
      'data_type' => 'VARCHAR',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'name',
      'is_nullable' => 1,
      'size' => '25'
    },
    'desc' => {
      'data_type' => 'TEXT',
      'is_auto_increment' => 0,
      'default_value' => 'NULL',
      'is_foreign_key' => 0,
      'name' => 'desc',
      'is_nullable' => 1,
      'size' => '65535'
    },
);
__PACKAGE__->set_primary_key('msabort_reason_id');


package TapTinder::DB::Schema::msjob;
use base 'DBIx::Class';
use strict;
use warnings;

__PACKAGE__->load_components(qw/Core ViewMD/);
__PACKAGE__->table('msjob');


__PACKAGE__->add_columns(
    'msjob_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 1,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'msjob_id',
      'is_nullable' => 0,
      'size' => '11'
    },
    'msession_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 1,
      'name' => 'msession_id',
      'is_nullable' => 0,
      'size' => '11'
    },
    'job_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 1,
      'name' => 'job_id',
      'is_nullable' => 0,
      'size' => '11'
    },
    'number' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'number',
      'is_nullable' => 0,
      'size' => '11'
    },
    'pid' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => 'NULL',
      'is_foreign_key' => 0,
      'name' => 'pid',
      'is_nullable' => 1,
      'size' => '11'
    },
);
__PACKAGE__->set_primary_key('msjob_id');


package TapTinder::DB::Schema::fsfile_type;
use base 'DBIx::Class';
use strict;
use warnings;

__PACKAGE__->load_components(qw/Core ViewMD/);
__PACKAGE__->table('fsfile_type');


__PACKAGE__->add_columns(
    'fsfile_type_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 1,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'fsfile_type_id',
      'is_nullable' => 0,
      'size' => '11'
    },
    'name' => {
      'data_type' => 'VARCHAR',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'name',
      'is_nullable' => 1,
      'size' => '25'
    },
    'desc' => {
      'data_type' => 'TEXT',
      'is_auto_increment' => 0,
      'default_value' => 'NULL',
      'is_foreign_key' => 0,
      'name' => 'desc',
      'is_nullable' => 1,
      'size' => '65535'
    },
);
__PACKAGE__->set_primary_key('fsfile_type_id');


package TapTinder::DB::Schema::cmd;
use base 'DBIx::Class';
use strict;
use warnings;

__PACKAGE__->load_components(qw/Core ViewMD/);
__PACKAGE__->table('cmd');


__PACKAGE__->add_columns(
    'cmd_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 1,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'cmd_id',
      'is_nullable' => 0,
      'size' => '11'
    },
    'name' => {
      'data_type' => 'VARCHAR',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'name',
      'is_nullable' => 1,
      'size' => '25'
    },
    'desc' => {
      'data_type' => 'TEXT',
      'is_auto_increment' => 0,
      'default_value' => 'NULL',
      'is_foreign_key' => 0,
      'name' => 'desc',
      'is_nullable' => 1,
      'size' => '65535'
    },
    'params' => {
      'data_type' => 'TEXT',
      'is_auto_increment' => 0,
      'default_value' => 'NULL',
      'is_foreign_key' => 0,
      'name' => 'params',
      'is_nullable' => 1,
      'size' => '65535'
    },
);
__PACKAGE__->set_primary_key('cmd_id');


package TapTinder::DB::Schema::bfile;
use base 'DBIx::Class';
use strict;
use warnings;

__PACKAGE__->load_components(qw/Core ViewMD/);
__PACKAGE__->table('bfile');


__PACKAGE__->add_columns(
    'bfile_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 1,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'bfile_id',
      'is_nullable' => 0,
      'size' => '11'
    },
    'brun_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 1,
      'name' => 'brun_id',
      'is_nullable' => 0,
      'size' => '11'
    },
    'rep_file_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 1,
      'name' => 'rep_file_id',
      'is_nullable' => 0,
      'size' => '11'
    },
    'run_time' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => 'NULL',
      'is_foreign_key' => 0,
      'name' => 'run_time',
      'is_nullable' => 1,
      'size' => '11'
    },
    'hang' => {
      'data_type' => 'BOOLEAN',
      'is_auto_increment' => 0,
      'default_value' => '0',
      'is_foreign_key' => 0,
      'name' => 'hang',
      'is_nullable' => 1,
      'size' => 0
    },
);
__PACKAGE__->set_primary_key('bfile_id');


package TapTinder::DB::Schema::cmd_status;
use base 'DBIx::Class';
use strict;
use warnings;

__PACKAGE__->load_components(qw/Core ViewMD/);
__PACKAGE__->table('cmd_status');


__PACKAGE__->add_columns(
    'cmd_status_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 1,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'cmd_status_id',
      'is_nullable' => 0,
      'size' => '11'
    },
    'name' => {
      'data_type' => 'VARCHAR',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'name',
      'is_nullable' => 1,
      'size' => '25'
    },
    'desc' => {
      'data_type' => 'TEXT',
      'is_auto_increment' => 0,
      'default_value' => 'NULL',
      'is_foreign_key' => 0,
      'name' => 'desc',
      'is_nullable' => 1,
      'size' => '65535'
    },
);
__PACKAGE__->set_primary_key('cmd_status_id');


package TapTinder::DB::Schema::farm;
use base 'DBIx::Class';
use strict;
use warnings;

__PACKAGE__->load_components(qw/Core ViewMD/);
__PACKAGE__->table('farm');


__PACKAGE__->add_columns(
    'farm_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 1,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'farm_id',
      'is_nullable' => 0,
      'size' => '11'
    },
    'name' => {
      'data_type' => 'VARCHAR',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'name',
      'is_nullable' => 0,
      'size' => '20'
    },
    'has_same_hw' => {
      'data_type' => 'BOOLEAN',
      'is_auto_increment' => 0,
      'default_value' => '0',
      'is_foreign_key' => 0,
      'name' => 'has_same_hw',
      'is_nullable' => 0,
      'size' => 0
    },
    'has_same_sw' => {
      'data_type' => 'BOOLEAN',
      'is_auto_increment' => 0,
      'default_value' => '0',
      'is_foreign_key' => 0,
      'name' => 'has_same_sw',
      'is_nullable' => 0,
      'size' => 0
    },
    'desc' => {
      'data_type' => 'TEXT',
      'is_auto_increment' => 0,
      'default_value' => 'NULL',
      'is_foreign_key' => 0,
      'name' => 'desc',
      'is_nullable' => 1,
      'size' => '65535'
    },
);
__PACKAGE__->set_primary_key('farm_id');


package TapTinder::DB::Schema::trest;
use base 'DBIx::Class';
use strict;
use warnings;

__PACKAGE__->load_components(qw/Core ViewMD/);
__PACKAGE__->table('trest');


__PACKAGE__->add_columns(
    'trest_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'trest_id',
      'is_nullable' => 0,
      'size' => '11'
    },
    'name' => {
      'data_type' => 'VARCHAR',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'name',
      'is_nullable' => 1,
      'size' => '25'
    },
    'desc' => {
      'data_type' => 'TEXT',
      'is_auto_increment' => 0,
      'default_value' => 'NULL',
      'is_foreign_key' => 0,
      'name' => 'desc',
      'is_nullable' => 1,
      'size' => '65535'
    },
);
__PACKAGE__->set_primary_key('trest_id');


package TapTinder::DB::Schema::jobp;
use base 'DBIx::Class';
use strict;
use warnings;

__PACKAGE__->load_components(qw/Core ViewMD/);
__PACKAGE__->table('jobp');


__PACKAGE__->add_columns(
    'jobp_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 1,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'jobp_id',
      'is_nullable' => 0,
      'size' => '11'
    },
    'job_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 1,
      'name' => 'job_id',
      'is_nullable' => 0,
      'size' => '11'
    },
    'rep_path_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => 'NULL',
      'is_foreign_key' => 1,
      'name' => 'rep_path_id',
      'is_nullable' => 1,
      'size' => '11'
    },
    'patch_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => 'NULL',
      'is_foreign_key' => 1,
      'name' => 'patch_id',
      'is_nullable' => 1,
      'size' => '11'
    },
    'order' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'order',
      'is_nullable' => 0,
      'size' => '11'
    },
    'name' => {
      'data_type' => 'VARCHAR',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'name',
      'is_nullable' => 1,
      'size' => '25'
    },
    'desc' => {
      'data_type' => 'TEXT',
      'is_auto_increment' => 0,
      'default_value' => 'NULL',
      'is_foreign_key' => 0,
      'name' => 'desc',
      'is_nullable' => 1,
      'size' => '65535'
    },
    'depends_on_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => 'NULL',
      'is_foreign_key' => 1,
      'name' => 'depends_on_id',
      'is_nullable' => 1,
      'size' => '11'
    },
    'extends' => {
      'data_type' => 'BOOLEAN',
      'is_auto_increment' => 0,
      'default_value' => '0',
      'is_foreign_key' => 0,
      'name' => 'extends',
      'is_nullable' => 0,
      'size' => 0
    },
);
__PACKAGE__->set_primary_key('jobp_id');


package TapTinder::DB::Schema::rev;
use base 'DBIx::Class';
use strict;
use warnings;

__PACKAGE__->load_components(qw/Core ViewMD/);
__PACKAGE__->table('rev');


__PACKAGE__->add_columns(
    'rev_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 1,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'rev_id',
      'is_nullable' => 0,
      'size' => '11'
    },
    'rep_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 1,
      'name' => 'rep_id',
      'is_nullable' => 0,
      'size' => '11'
    },
    'rev_num' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'rev_num',
      'is_nullable' => 0,
      'size' => '11'
    },
    'author_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 1,
      'name' => 'author_id',
      'is_nullable' => 0,
      'size' => '11'
    },
    'date' => {
      'data_type' => 'DATETIME',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'date',
      'is_nullable' => 0,
      'size' => 0
    },
    'msg' => {
      'data_type' => 'TEXT',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'msg',
      'is_nullable' => 1,
      'size' => '65535'
    },
);
__PACKAGE__->set_primary_key('rev_id');


package TapTinder::DB::Schema::fspath;
use base 'DBIx::Class';
use strict;
use warnings;

__PACKAGE__->load_components(qw/Core ViewMD/);
__PACKAGE__->table('fspath');


__PACKAGE__->add_columns(
    'fspath_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 1,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'fspath_id',
      'is_nullable' => 0,
      'size' => '11'
    },
    'path' => {
      'data_type' => 'VARCHAR',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'path',
      'is_nullable' => 1,
      'size' => '1023'
    },
    'web_path' => {
      'data_type' => 'VARCHAR',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'web_path',
      'is_nullable' => 1,
      'size' => '255'
    },
    'public' => {
      'data_type' => 'BOOLEAN',
      'is_auto_increment' => 0,
      'default_value' => '0',
      'is_foreign_key' => 0,
      'name' => 'public',
      'is_nullable' => 1,
      'size' => 0
    },
    'created' => {
      'data_type' => 'DATETIME',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'created',
      'is_nullable' => 0,
      'size' => 0
    },
    'deleted' => {
      'data_type' => 'DATETIME',
      'is_auto_increment' => 0,
      'default_value' => 'NULL',
      'is_foreign_key' => 0,
      'name' => 'deleted',
      'is_nullable' => 1,
      'size' => 0
    },
    'name' => {
      'data_type' => 'VARCHAR',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'name',
      'is_nullable' => 1,
      'size' => '25'
    },
    'desc' => {
      'data_type' => 'TEXT',
      'is_auto_increment' => 0,
      'default_value' => 'NULL',
      'is_foreign_key' => 0,
      'name' => 'desc',
      'is_nullable' => 1,
      'size' => '65535'
    },
);
__PACKAGE__->set_primary_key('fspath_id');


package TapTinder::DB::Schema::mslog;
use base 'DBIx::Class';
use strict;
use warnings;

__PACKAGE__->load_components(qw/Core ViewMD/);
__PACKAGE__->table('mslog');


__PACKAGE__->add_columns(
    'mslog_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 1,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'mslog_id',
      'is_nullable' => 0,
      'size' => '11'
    },
    'msession_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 1,
      'name' => 'msession_id',
      'is_nullable' => 0,
      'size' => '11'
    },
    'msstatus_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 1,
      'name' => 'msstatus_id',
      'is_nullable' => 0,
      'size' => '11'
    },
    'attempt_number' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => '1',
      'is_foreign_key' => 0,
      'name' => 'attempt_number',
      'is_nullable' => 1,
      'size' => '11'
    },
    'change_time' => {
      'data_type' => 'DATETIME',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'change_time',
      'is_nullable' => 0,
      'size' => 0
    },
    'estimated_finish_time' => {
      'data_type' => 'DATETIME',
      'is_auto_increment' => 0,
      'default_value' => 'NULL',
      'is_foreign_key' => 0,
      'name' => 'estimated_finish_time',
      'is_nullable' => 1,
      'size' => 0
    },
);
__PACKAGE__->set_primary_key('mslog_id');


package TapTinder::DB::Schema::patch;
use base 'DBIx::Class';
use strict;
use warnings;

__PACKAGE__->load_components(qw/Core ViewMD/);
__PACKAGE__->table('patch');


__PACKAGE__->add_columns(
    'patch_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 1,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'patch_id',
      'is_nullable' => 0,
      'size' => '11'
    },
    'rep_path_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 1,
      'name' => 'rep_path_id',
      'is_nullable' => 0,
      'size' => '11'
    },
    'rev_num' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'rev_num',
      'is_nullable' => 0,
      'size' => '11'
    },
    'rev_num_to' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'rev_num_to',
      'is_nullable' => 0,
      'size' => '11'
    },
    'author_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 1,
      'name' => 'author_id',
      'is_nullable' => 0,
      'size' => '11'
    },
    'date' => {
      'data_type' => 'DATETIME',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'date',
      'is_nullable' => 0,
      'size' => 0
    },
    'msg' => {
      'data_type' => 'TEXT',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'msg',
      'is_nullable' => 1,
      'size' => '65535'
    },
    'fsfile_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 1,
      'name' => 'fsfile_id',
      'is_nullable' => 0,
      'size' => '11'
    },
    'new_patch_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => 'NULL',
      'is_foreign_key' => 1,
      'name' => 'new_patch_id',
      'is_nullable' => 1,
      'size' => '11'
    },
);
__PACKAGE__->set_primary_key('patch_id');


package TapTinder::DB::Schema::rep_file;
use base 'DBIx::Class';
use strict;
use warnings;

__PACKAGE__->load_components(qw/Core ViewMD/);
__PACKAGE__->table('rep_file');


__PACKAGE__->add_columns(
    'rep_file_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 1,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'rep_file_id',
      'is_nullable' => 0,
      'size' => '11'
    },
    'rep_path_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 1,
      'name' => 'rep_path_id',
      'is_nullable' => 0,
      'size' => '11'
    },
    'sub_path' => {
      'data_type' => 'VARCHAR',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'sub_path',
      'is_nullable' => 0,
      'size' => '255'
    },
    'rev_num_from' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'rev_num_from',
      'is_nullable' => 0,
      'size' => '11'
    },
    'rev_num_to' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => 'NULL',
      'is_foreign_key' => 0,
      'name' => 'rev_num_to',
      'is_nullable' => 1,
      'size' => '11'
    },
);
__PACKAGE__->set_primary_key('rep_file_id');


package TapTinder::DB::Schema::fsfile;
use base 'DBIx::Class';
use strict;
use warnings;

__PACKAGE__->load_components(qw/Core ViewMD/);
__PACKAGE__->table('fsfile');


__PACKAGE__->add_columns(
    'fsfile_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 1,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'fsfile_id',
      'is_nullable' => 0,
      'size' => '11'
    },
    'fspath_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 1,
      'name' => 'fspath_id',
      'is_nullable' => 0,
      'size' => '11'
    },
    'name' => {
      'data_type' => 'VARCHAR',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'name',
      'is_nullable' => 1,
      'size' => '255'
    },
    'size' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'size',
      'is_nullable' => 0,
      'size' => '11'
    },
    'created' => {
      'data_type' => 'DATETIME',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'created',
      'is_nullable' => 0,
      'size' => 0
    },
    'deleted' => {
      'data_type' => 'DATETIME',
      'is_auto_increment' => 0,
      'default_value' => 'NULL',
      'is_foreign_key' => 0,
      'name' => 'deleted',
      'is_nullable' => 1,
      'size' => 0
    },
);
__PACKAGE__->set_primary_key('fsfile_id');


package TapTinder::DB::Schema::param_type;
use base 'DBIx::Class';
use strict;
use warnings;

__PACKAGE__->load_components(qw/Core ViewMD/);
__PACKAGE__->table('param_type');


__PACKAGE__->add_columns(
    'param_type_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 1,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'param_type_id',
      'is_nullable' => 0,
      'size' => '11'
    },
    'name' => {
      'data_type' => 'VARCHAR',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'name',
      'is_nullable' => 0,
      'size' => '20'
    },
    'desc' => {
      'data_type' => 'TEXT',
      'is_auto_increment' => 0,
      'default_value' => 'NULL',
      'is_foreign_key' => 0,
      'name' => 'desc',
      'is_nullable' => 1,
      'size' => '65535'
    },
);
__PACKAGE__->set_primary_key('param_type_id');


package TapTinder::DB::Schema::project;
use base 'DBIx::Class';
use strict;
use warnings;

__PACKAGE__->load_components(qw/Core ViewMD/);
__PACKAGE__->table('project');


__PACKAGE__->add_columns(
    'project_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 1,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'project_id',
      'is_nullable' => 0,
      'size' => '11'
    },
    'name' => {
      'data_type' => 'VARCHAR',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'name',
      'is_nullable' => 0,
      'size' => '255'
    },
    'url' => {
      'data_type' => 'VARCHAR',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'url',
      'is_nullable' => 0,
      'size' => '255'
    },
    'desc' => {
      'data_type' => 'TEXT',
      'is_auto_increment' => 0,
      'default_value' => 'NULL',
      'is_foreign_key' => 0,
      'name' => 'desc',
      'is_nullable' => 1,
      'size' => '65535'
    },
);
__PACKAGE__->set_primary_key('project_id');


package TapTinder::DB::Schema::msjobp;
use base 'DBIx::Class';
use strict;
use warnings;

__PACKAGE__->load_components(qw/Core ViewMD/);
__PACKAGE__->table('msjobp');


__PACKAGE__->add_columns(
    'msjobp_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 1,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'msjobp_id',
      'is_nullable' => 0,
      'size' => '11'
    },
    'msjob_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 1,
      'name' => 'msjob_id',
      'is_nullable' => 0,
      'size' => '11'
    },
    'jobp_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 1,
      'name' => 'jobp_id',
      'is_nullable' => 0,
      'size' => '11'
    },
    'rev_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 1,
      'name' => 'rev_id',
      'is_nullable' => 0,
      'size' => '11'
    },
);
__PACKAGE__->set_primary_key('msjobp_id');


package TapTinder::DB::Schema::rep_file_change;
use base 'DBIx::Class';
use strict;
use warnings;

__PACKAGE__->load_components(qw/Core ViewMD/);
__PACKAGE__->table('rep_file_change');


__PACKAGE__->add_columns(
    'rev_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 1,
      'name' => 'rev_id',
      'is_nullable' => 0,
      'size' => '11'
    },
    'rev_num' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'rev_num',
      'is_nullable' => 0,
      'size' => '11'
    },
    'rep_file_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 1,
      'name' => 'rep_file_id',
      'is_nullable' => 0,
      'size' => '11'
    },
    'change_type_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 1,
      'name' => 'change_type_id',
      'is_nullable' => 0,
      'size' => '11'
    },
);


package TapTinder::DB::Schema::rep_test;
use base 'DBIx::Class';
use strict;
use warnings;

__PACKAGE__->load_components(qw/Core ViewMD/);
__PACKAGE__->table('rep_test');


__PACKAGE__->add_columns(
    'rep_test_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 1,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'rep_test_id',
      'is_nullable' => 0,
      'size' => '11'
    },
    'rep_file_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 1,
      'name' => 'rep_file_id',
      'is_nullable' => 0,
      'size' => '11'
    },
    'number' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'number',
      'is_nullable' => 0,
      'size' => '11'
    },
    'name' => {
      'data_type' => 'VARCHAR',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'name',
      'is_nullable' => 0,
      'size' => '255'
    },
    'has_another_name' => {
      'data_type' => 'BOOLEAN',
      'is_auto_increment' => 0,
      'default_value' => '0',
      'is_foreign_key' => 0,
      'name' => 'has_another_name',
      'is_nullable' => 0,
      'size' => 0
    },
);
__PACKAGE__->set_primary_key('rep_test_id');


package TapTinder::DB::Schema::msstatus;
use base 'DBIx::Class';
use strict;
use warnings;

__PACKAGE__->load_components(qw/Core ViewMD/);
__PACKAGE__->table('msstatus');


__PACKAGE__->add_columns(
    'msstatus_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 1,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'msstatus_id',
      'is_nullable' => 0,
      'size' => '11'
    },
    'name' => {
      'data_type' => 'VARCHAR',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'name',
      'is_nullable' => 1,
      'size' => '25'
    },
    'desc' => {
      'data_type' => 'TEXT',
      'is_auto_increment' => 0,
      'default_value' => 'NULL',
      'is_foreign_key' => 0,
      'name' => 'desc',
      'is_nullable' => 1,
      'size' => '65535'
    },
);
__PACKAGE__->set_primary_key('msstatus_id');


package TapTinder::DB::Schema::tskipall_msg;
use base 'DBIx::Class';
use strict;
use warnings;

__PACKAGE__->load_components(qw/Core ViewMD/);
__PACKAGE__->table('tskipall_msg');


__PACKAGE__->add_columns(
    'tskipall_msg_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 1,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'tskipall_msg_id',
      'is_nullable' => 0,
      'size' => '11'
    },
    'msg' => {
      'data_type' => 'TEXT',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'msg',
      'is_nullable' => 1,
      'size' => '65535'
    },
    'hash' => {
      'data_type' => 'VARCHAR',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'hash',
      'is_nullable' => 0,
      'size' => '50'
    },
);
__PACKAGE__->set_primary_key('tskipall_msg_id');


package TapTinder::DB::Schema::brun;
use base 'DBIx::Class';
use strict;
use warnings;

__PACKAGE__->load_components(qw/Core ViewMD/);
__PACKAGE__->table('brun');


__PACKAGE__->add_columns(
    'brun_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 1,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'brun_id',
      'is_nullable' => 0,
      'size' => '11'
    },
    'msjobp_cmd_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 1,
      'name' => 'msjobp_cmd_id',
      'is_nullable' => 0,
      'size' => '11'
    },
    'conf_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 1,
      'name' => 'conf_id',
      'is_nullable' => 0,
      'size' => '11'
    },
);
__PACKAGE__->set_primary_key('brun_id');


package TapTinder::DB::Schema::msjobp_cmd;
use base 'DBIx::Class';
use strict;
use warnings;

__PACKAGE__->load_components(qw/Core ViewMD/);
__PACKAGE__->table('msjobp_cmd');


__PACKAGE__->add_columns(
    'msjobp_cmd_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 1,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'msjobp_cmd_id',
      'is_nullable' => 0,
      'size' => '11'
    },
    'jobp_cmd_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 1,
      'name' => 'jobp_cmd_id',
      'is_nullable' => 0,
      'size' => '11'
    },
    'msjobp_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 1,
      'name' => 'msjobp_id',
      'is_nullable' => 0,
      'size' => '11'
    },
    'status_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 1,
      'name' => 'status_id',
      'is_nullable' => 0,
      'size' => '11'
    },
    'pid' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'pid',
      'is_nullable' => 0,
      'size' => '11'
    },
    'start_time' => {
      'data_type' => 'DATETIME',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'start_time',
      'is_nullable' => 0,
      'size' => 0
    },
    'end_time' => {
      'data_type' => 'DATETIME',
      'is_auto_increment' => 0,
      'default_value' => 'NULL',
      'is_foreign_key' => 0,
      'name' => 'end_time',
      'is_nullable' => 1,
      'size' => 0
    },
    'output_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 1,
      'name' => 'output_id',
      'is_nullable' => 0,
      'size' => '11'
    },
);
__PACKAGE__->set_primary_key('msjobp_cmd_id');


package TapTinder::DB::Schema::machine;
use base 'DBIx::Class';
use strict;
use warnings;

__PACKAGE__->load_components(qw/Core ViewMD/);
__PACKAGE__->table('machine');


__PACKAGE__->add_columns(
    'machine_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 1,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'machine_id',
      'is_nullable' => 0,
      'size' => '11'
    },
    'user_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 1,
      'name' => 'user_id',
      'is_nullable' => 0,
      'size' => '11'
    },
    'name' => {
      'data_type' => 'VARCHAR',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'name',
      'is_nullable' => 0,
      'size' => '20'
    },
    'passwd' => {
      'data_type' => 'VARCHAR',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'passwd',
      'is_nullable' => 0,
      'size' => '20'
    },
    'desc' => {
      'data_type' => 'TEXT',
      'is_auto_increment' => 0,
      'default_value' => 'NULL',
      'is_foreign_key' => 0,
      'name' => 'desc',
      'is_nullable' => 1,
      'size' => '65535'
    },
    'ip' => {
      'data_type' => 'VARCHAR',
      'is_auto_increment' => 0,
      'default_value' => 'NULL',
      'is_foreign_key' => 0,
      'name' => 'ip',
      'is_nullable' => 1,
      'size' => '15'
    },
    'cpuarch' => {
      'data_type' => 'VARCHAR',
      'is_auto_increment' => 0,
      'default_value' => 'NULL',
      'is_foreign_key' => 0,
      'name' => 'cpuarch',
      'is_nullable' => 1,
      'size' => '50'
    },
    'osname' => {
      'data_type' => 'VARCHAR',
      'is_auto_increment' => 0,
      'default_value' => 'NULL',
      'is_foreign_key' => 0,
      'name' => 'osname',
      'is_nullable' => 1,
      'size' => '50'
    },
    'archname' => {
      'data_type' => 'VARCHAR',
      'is_auto_increment' => 0,
      'default_value' => 'NULL',
      'is_foreign_key' => 0,
      'name' => 'archname',
      'is_nullable' => 1,
      'size' => '255'
    },
    'disabled' => {
      'data_type' => 'BOOLEAN',
      'is_auto_increment' => 0,
      'default_value' => '0',
      'is_foreign_key' => 0,
      'name' => 'disabled',
      'is_nullable' => 0,
      'size' => 0
    },
    'created' => {
      'data_type' => 'DATETIME',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'created',
      'is_nullable' => 0,
      'size' => 0
    },
    'prev_machine_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => 'NULL',
      'is_foreign_key' => 1,
      'name' => 'prev_machine_id',
      'is_nullable' => 1,
      'size' => '11'
    },
    'farm_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => 'NULL',
      'is_foreign_key' => 1,
      'name' => 'farm_id',
      'is_nullable' => 1,
      'size' => '11'
    },
);
__PACKAGE__->set_primary_key('machine_id');


package TapTinder::DB::Schema::rep_file_change_from;
use base 'DBIx::Class';
use strict;
use warnings;

__PACKAGE__->load_components(qw/Core ViewMD/);
__PACKAGE__->table('rep_file_change_from');


__PACKAGE__->add_columns(
    'rev_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 1,
      'name' => 'rev_id',
      'is_nullable' => 0,
      'size' => '11'
    },
    'rep_file_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 1,
      'name' => 'rep_file_id',
      'is_nullable' => 0,
      'size' => '11'
    },
    'from_rev_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => 'NULL',
      'is_foreign_key' => 1,
      'name' => 'from_rev_id',
      'is_nullable' => 1,
      'size' => '11'
    },
    'from_rep_file_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => 'NULL',
      'is_foreign_key' => 1,
      'name' => 'from_rep_file_id',
      'is_nullable' => 1,
      'size' => '11'
    },
);


package TapTinder::DB::Schema::ttest;
use base 'DBIx::Class';
use strict;
use warnings;

__PACKAGE__->load_components(qw/Core ViewMD/);
__PACKAGE__->table('ttest');


__PACKAGE__->add_columns(
    'ttest_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 1,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'ttest_id',
      'is_nullable' => 0,
      'size' => '11'
    },
    'trun_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 1,
      'name' => 'trun_id',
      'is_nullable' => 0,
      'size' => '11'
    },
    'rep_test_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 1,
      'name' => 'rep_test_id',
      'is_nullable' => 0,
      'size' => '11'
    },
    'trest_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 1,
      'name' => 'trest_id',
      'is_nullable' => 0,
      'size' => '11'
    },
);
__PACKAGE__->set_primary_key('ttest_id');


package TapTinder::DB::Schema::tdiag_msg;
use base 'DBIx::Class';
use strict;
use warnings;

__PACKAGE__->load_components(qw/Core ViewMD/);
__PACKAGE__->table('tdiag_msg');


__PACKAGE__->add_columns(
    'tdiag_msg_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 1,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'tdiag_msg_id',
      'is_nullable' => 0,
      'size' => '11'
    },
    'ttest_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 1,
      'name' => 'ttest_id',
      'is_nullable' => 0,
      'size' => '11'
    },
    'msg' => {
      'data_type' => 'TEXT',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'msg',
      'is_nullable' => 1,
      'size' => '65535'
    },
    'hash' => {
      'data_type' => 'VARCHAR',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'hash',
      'is_nullable' => 0,
      'size' => '50'
    },
);
__PACKAGE__->set_primary_key('tdiag_msg_id');


package TapTinder::DB::Schema::brun_conf;
use base 'DBIx::Class';
use strict;
use warnings;

__PACKAGE__->load_components(qw/Core ViewMD/);
__PACKAGE__->table('brun_conf');


__PACKAGE__->add_columns(
    'brun_conf_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 1,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'brun_conf_id',
      'is_nullable' => 0,
      'size' => '11'
    },
    'hash' => {
      'data_type' => 'VARCHAR',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'hash',
      'is_nullable' => 0,
      'size' => '50'
    },
    'args' => {
      'data_type' => 'VARCHAR',
      'is_auto_increment' => 0,
      'default_value' => 'NULL',
      'is_foreign_key' => 0,
      'name' => 'args',
      'is_nullable' => 1,
      'size' => '255'
    },
    'alias_conf_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => 'NULL',
      'is_foreign_key' => 1,
      'name' => 'alias_conf_id',
      'is_nullable' => 1,
      'size' => '11'
    },
);
__PACKAGE__->set_primary_key('brun_conf_id');


package TapTinder::DB::Schema::build;
use base 'DBIx::Class';
use strict;
use warnings;

__PACKAGE__->load_components(qw/Core ViewMD/);
__PACKAGE__->table('build');


__PACKAGE__->add_columns(
    'build_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 1,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'build_id',
      'is_nullable' => 0,
      'size' => '11'
    },
    'msjobp_cmd_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 1,
      'name' => 'msjobp_cmd_id',
      'is_nullable' => 0,
      'size' => '11'
    },
    'conf_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 1,
      'name' => 'conf_id',
      'is_nullable' => 0,
      'size' => '11'
    },
);
__PACKAGE__->set_primary_key('build_id');


package TapTinder::DB::Schema::job;
use base 'DBIx::Class';
use strict;
use warnings;

__PACKAGE__->load_components(qw/Core ViewMD/);
__PACKAGE__->table('job');


__PACKAGE__->add_columns(
    'job_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 1,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'job_id',
      'is_nullable' => 0,
      'size' => '11'
    },
    'client_min_rev' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => '1',
      'is_foreign_key' => 0,
      'name' => 'client_min_rev',
      'is_nullable' => 1,
      'size' => '11'
    },
    'priority' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'priority',
      'is_nullable' => 0,
      'size' => '11'
    },
    'name' => {
      'data_type' => 'VARCHAR',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'name',
      'is_nullable' => 1,
      'size' => '25'
    },
    'desc' => {
      'data_type' => 'TEXT',
      'is_auto_increment' => 0,
      'default_value' => 'NULL',
      'is_foreign_key' => 0,
      'name' => 'desc',
      'is_nullable' => 1,
      'size' => '65535'
    },
);
__PACKAGE__->set_primary_key('job_id');


package TapTinder::DB::Schema::machine_job_conf;
use base 'DBIx::Class';
use strict;
use warnings;

__PACKAGE__->load_components(qw/Core ViewMD/);
__PACKAGE__->table('machine_job_conf');


__PACKAGE__->add_columns(
    'machine_job_conf_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 1,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'machine_job_conf_id',
      'is_nullable' => 0,
      'size' => '11'
    },
    'machine_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 1,
      'name' => 'machine_id',
      'is_nullable' => 0,
      'size' => '11'
    },
    'rep_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 1,
      'name' => 'rep_id',
      'is_nullable' => 0,
      'size' => '11'
    },
    'rep_path_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 1,
      'name' => 'rep_path_id',
      'is_nullable' => 0,
      'size' => '11'
    },
    'job_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 1,
      'name' => 'job_id',
      'is_nullable' => 0,
      'size' => '11'
    },
);
__PACKAGE__->set_primary_key('machine_job_conf_id');


package TapTinder::DB::Schema::rep_author;
use base 'DBIx::Class';
use strict;
use warnings;

__PACKAGE__->load_components(qw/Core ViewMD/);
__PACKAGE__->table('rep_author');


__PACKAGE__->add_columns(
    'rep_author_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 1,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'rep_author_id',
      'is_nullable' => 0,
      'size' => '11'
    },
    'rep_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 1,
      'name' => 'rep_id',
      'is_nullable' => 0,
      'size' => '11'
    },
    'rep_login' => {
      'data_type' => 'VARCHAR',
      'is_auto_increment' => 0,
      'default_value' => 'NULL',
      'is_foreign_key' => 0,
      'name' => 'rep_login',
      'is_nullable' => 1,
      'size' => '255'
    },
    'user_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => 'NULL',
      'is_foreign_key' => 1,
      'name' => 'user_id',
      'is_nullable' => 1,
      'size' => '11'
    },
);
__PACKAGE__->set_primary_key('rep_author_id');


package TapTinder::DB::Schema::trun;
use base 'DBIx::Class';
use strict;
use warnings;

__PACKAGE__->load_components(qw/Core ViewMD/);
__PACKAGE__->table('trun');


__PACKAGE__->add_columns(
    'trun_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 1,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'trun_id',
      'is_nullable' => 0,
      'size' => '11'
    },
    'msjobp_cmd_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 1,
      'name' => 'msjobp_cmd_id',
      'is_nullable' => 0,
      'size' => '11'
    },
    'conf_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 1,
      'name' => 'conf_id',
      'is_nullable' => 0,
      'size' => '11'
    },
    'num_notseen' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'num_notseen',
      'is_nullable' => 0,
      'size' => '11'
    },
    'num_failed' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'num_failed',
      'is_nullable' => 0,
      'size' => '11'
    },
    'num_unknown' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'num_unknown',
      'is_nullable' => 0,
      'size' => '11'
    },
    'num_todo' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'num_todo',
      'is_nullable' => 0,
      'size' => '11'
    },
    'num_bonus' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'num_bonus',
      'is_nullable' => 0,
      'size' => '11'
    },
    'num_skip' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'num_skip',
      'is_nullable' => 0,
      'size' => '11'
    },
    'num_ok' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'num_ok',
      'is_nullable' => 0,
      'size' => '11'
    },
);
__PACKAGE__->set_primary_key('trun_id');


package TapTinder::DB::Schema::fspath_select;
use base 'DBIx::Class';
use strict;
use warnings;

__PACKAGE__->load_components(qw/Core ViewMD/);
__PACKAGE__->table('fspath_select');


__PACKAGE__->add_columns(
    'fspath_select_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 1,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'fspath_select_id',
      'is_nullable' => 0,
      'size' => '11'
    },
    'fsfile_type_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 1,
      'name' => 'fsfile_type_id',
      'is_nullable' => 0,
      'size' => '11'
    },
    'rep_path_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 1,
      'name' => 'rep_path_id',
      'is_nullable' => 0,
      'size' => '11'
    },
    'fspath_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 1,
      'name' => 'fspath_id',
      'is_nullable' => 0,
      'size' => '11'
    },
);
__PACKAGE__->set_primary_key('fspath_select_id');


package TapTinder::DB::Schema::tfile;
use base 'DBIx::Class';
use strict;
use warnings;

__PACKAGE__->load_components(qw/Core ViewMD/);
__PACKAGE__->table('tfile');


__PACKAGE__->add_columns(
    'tfile_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 1,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'tfile_id',
      'is_nullable' => 0,
      'size' => '11'
    },
    'trun_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 1,
      'name' => 'trun_id',
      'is_nullable' => 0,
      'size' => '11'
    },
    'rep_file_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 1,
      'name' => 'rep_file_id',
      'is_nullable' => 0,
      'size' => '11'
    },
    'all_passed' => {
      'data_type' => 'BOOLEAN',
      'is_auto_increment' => 0,
      'default_value' => '0',
      'is_foreign_key' => 0,
      'name' => 'all_passed',
      'is_nullable' => 0,
      'size' => 0
    },
    'tskipall_msg_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => 'NULL',
      'is_foreign_key' => 1,
      'name' => 'tskipall_msg_id',
      'is_nullable' => 1,
      'size' => '11'
    },
    'hang' => {
      'data_type' => 'BOOLEAN',
      'is_auto_increment' => 0,
      'default_value' => '0',
      'is_foreign_key' => 0,
      'name' => 'hang',
      'is_nullable' => 1,
      'size' => 0
    },
);
__PACKAGE__->set_primary_key('tfile_id');


package TapTinder::DB::Schema::rep;
use base 'DBIx::Class';
use strict;
use warnings;

__PACKAGE__->load_components(qw/Core ViewMD/);
__PACKAGE__->table('rep');


__PACKAGE__->add_columns(
    'rep_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 1,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'rep_id',
      'is_nullable' => 0,
      'size' => '11'
    },
    'project_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 1,
      'name' => 'project_id',
      'is_nullable' => 0,
      'size' => '11'
    },
    'name' => {
      'data_type' => 'VARCHAR',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'name',
      'is_nullable' => 0,
      'size' => '255'
    },
    'path' => {
      'data_type' => 'VARCHAR',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'path',
      'is_nullable' => 0,
      'size' => '255'
    },
    'subpath' => {
      'data_type' => 'VARCHAR',
      'is_auto_increment' => 0,
      'default_value' => '',
      'is_foreign_key' => 0,
      'name' => 'subpath',
      'is_nullable' => 0,
      'size' => '255'
    },
    'desc' => {
      'data_type' => 'TEXT',
      'is_auto_increment' => 0,
      'default_value' => 'NULL',
      'is_foreign_key' => 0,
      'name' => 'desc',
      'is_nullable' => 1,
      'size' => '65535'
    },
    'active' => {
      'data_type' => 'BOOLEAN',
      'is_auto_increment' => 0,
      'default_value' => '1',
      'is_foreign_key' => 0,
      'name' => 'active',
      'is_nullable' => 0,
      'size' => 0
    },
    'default_layout' => {
      'data_type' => 'BOOLEAN',
      'is_auto_increment' => 0,
      'default_value' => '1',
      'is_foreign_key' => 0,
      'name' => 'default_layout',
      'is_nullable' => 0,
      'size' => 0
    },
);
__PACKAGE__->set_primary_key('rep_id');

package TapTinder::DB::Schema::rep_path;

__PACKAGE__->belongs_to('rep_id','TapTinder::DB::Schema::rep','rep_id');

__PACKAGE__->has_many('get_rev_rep_path', 'TapTinder::DB::Schema::rev_rep_path', 'rep_path_id');
__PACKAGE__->has_many('get_rep_file', 'TapTinder::DB::Schema::rep_file', 'rep_path_id');
__PACKAGE__->has_many('get_patch', 'TapTinder::DB::Schema::patch', 'rep_path_id');
__PACKAGE__->has_many('get_jobp', 'TapTinder::DB::Schema::jobp', 'rep_path_id');
__PACKAGE__->has_many('get_machine_job_conf', 'TapTinder::DB::Schema::machine_job_conf', 'rep_path_id');
__PACKAGE__->has_many('get_fspath_select', 'TapTinder::DB::Schema::fspath_select', 'rep_path_id');

package TapTinder::DB::Schema::trun_conf;

__PACKAGE__->belongs_to('alias_conf_id','TapTinder::DB::Schema::trun_conf','alias_conf_id',{join_type => 'left'});

__PACKAGE__->has_many('get_trun_conf', 'TapTinder::DB::Schema::trun_conf', 'alias_conf_id');
__PACKAGE__->has_many('get_trun', 'TapTinder::DB::Schema::trun', 'conf_id');

package TapTinder::DB::Schema::rev_rep_path;

__PACKAGE__->belongs_to('rev_id','TapTinder::DB::Schema::rev','rev_id');

__PACKAGE__->belongs_to('rep_path_id','TapTinder::DB::Schema::rep_path','rep_path_id');


package TapTinder::DB::Schema::jobp_cmd;

__PACKAGE__->belongs_to('jobp_id','TapTinder::DB::Schema::jobp','jobp_id');

__PACKAGE__->belongs_to('cmd_id','TapTinder::DB::Schema::cmd','cmd_id');

__PACKAGE__->has_many('get_msjobp_cmd', 'TapTinder::DB::Schema::msjobp_cmd', 'jobp_cmd_id');

package TapTinder::DB::Schema::rep_change_type;

__PACKAGE__->has_many('get_rep_file_change', 'TapTinder::DB::Schema::rep_file_change', 'change_type_id');

package TapTinder::DB::Schema::user;

__PACKAGE__->has_many('get_machine', 'TapTinder::DB::Schema::machine', 'user_id');
__PACKAGE__->has_many('get_rep_author', 'TapTinder::DB::Schema::rep_author', 'user_id');

package TapTinder::DB::Schema::param;

__PACKAGE__->belongs_to('param_type_id','TapTinder::DB::Schema::param_type','param_type_id');


package TapTinder::DB::Schema::msession;

__PACKAGE__->belongs_to('machine_id','TapTinder::DB::Schema::machine','machine_id');

__PACKAGE__->belongs_to('abort_reason_id','TapTinder::DB::Schema::msabort_reason','abort_reason_id',{join_type => 'left'});

__PACKAGE__->has_many('get_msjob', 'TapTinder::DB::Schema::msjob', 'msession_id');
__PACKAGE__->has_many('get_mslog', 'TapTinder::DB::Schema::mslog', 'msession_id');

package TapTinder::DB::Schema::build_conf;

__PACKAGE__->belongs_to('alias_conf_id','TapTinder::DB::Schema::build_conf','alias_conf_id',{join_type => 'left'});

__PACKAGE__->has_many('get_build_conf', 'TapTinder::DB::Schema::build_conf', 'alias_conf_id');
__PACKAGE__->has_many('get_build', 'TapTinder::DB::Schema::build', 'conf_id');

package TapTinder::DB::Schema::msjob;

__PACKAGE__->belongs_to('msession_id','TapTinder::DB::Schema::msession','msession_id');

__PACKAGE__->belongs_to('job_id','TapTinder::DB::Schema::job','job_id');

__PACKAGE__->has_many('get_msjobp', 'TapTinder::DB::Schema::msjobp', 'msjob_id');

package TapTinder::DB::Schema::msabort_reason;

__PACKAGE__->has_many('get_msession', 'TapTinder::DB::Schema::msession', 'abort_reason_id');

package TapTinder::DB::Schema::fsfile_type;

__PACKAGE__->has_many('get_fspath_select', 'TapTinder::DB::Schema::fspath_select', 'fsfile_type_id');

package TapTinder::DB::Schema::cmd;

__PACKAGE__->has_many('get_jobp_cmd', 'TapTinder::DB::Schema::jobp_cmd', 'cmd_id');

package TapTinder::DB::Schema::bfile;

__PACKAGE__->belongs_to('brun_id','TapTinder::DB::Schema::brun','brun_id');

__PACKAGE__->belongs_to('rep_file_id','TapTinder::DB::Schema::rep_file','rep_file_id');


package TapTinder::DB::Schema::cmd_status;

__PACKAGE__->has_many('get_msjobp_cmd', 'TapTinder::DB::Schema::msjobp_cmd', 'status_id');

package TapTinder::DB::Schema::farm;

__PACKAGE__->has_many('get_machine', 'TapTinder::DB::Schema::machine', 'farm_id');

package TapTinder::DB::Schema::trest;

__PACKAGE__->has_many('get_ttest', 'TapTinder::DB::Schema::ttest', 'trest_id');

package TapTinder::DB::Schema::jobp;

__PACKAGE__->belongs_to('job_id','TapTinder::DB::Schema::job','job_id');

__PACKAGE__->belongs_to('depends_on_id','TapTinder::DB::Schema::jobp','depends_on_id',{join_type => 'left'});

__PACKAGE__->has_many('get_jobp', 'TapTinder::DB::Schema::jobp', 'depends_on_id');
__PACKAGE__->belongs_to('rep_path_id','TapTinder::DB::Schema::rep_path','rep_path_id',{join_type => 'left'});

__PACKAGE__->belongs_to('patch_id','TapTinder::DB::Schema::patch','patch_id',{join_type => 'left'});

__PACKAGE__->has_many('get_jobp_cmd', 'TapTinder::DB::Schema::jobp_cmd', 'jobp_id');
__PACKAGE__->has_many('get_msjobp', 'TapTinder::DB::Schema::msjobp', 'jobp_id');

package TapTinder::DB::Schema::rev;

__PACKAGE__->belongs_to('rep_id','TapTinder::DB::Schema::rep','rep_id');

__PACKAGE__->belongs_to('author_id','TapTinder::DB::Schema::rep_author','author_id');

__PACKAGE__->has_many('get_rev_rep_path', 'TapTinder::DB::Schema::rev_rep_path', 'rev_id');
__PACKAGE__->has_many('get_rep_file_change', 'TapTinder::DB::Schema::rep_file_change', 'rev_id');
__PACKAGE__->has_many('get_rep_file_change_from', 'TapTinder::DB::Schema::rep_file_change_from', 'rev_id');
__PACKAGE__->has_many('get_rep_file_change_from', 'TapTinder::DB::Schema::rep_file_change_from', 'from_rev_id');
__PACKAGE__->has_many('get_msjobp', 'TapTinder::DB::Schema::msjobp', 'rev_id');

package TapTinder::DB::Schema::fspath;

__PACKAGE__->has_many('get_fsfile', 'TapTinder::DB::Schema::fsfile', 'fspath_id');
__PACKAGE__->has_many('get_fspath_select', 'TapTinder::DB::Schema::fspath_select', 'fspath_id');

package TapTinder::DB::Schema::mslog;

__PACKAGE__->belongs_to('msession_id','TapTinder::DB::Schema::msession','msession_id');

__PACKAGE__->belongs_to('msstatus_id','TapTinder::DB::Schema::msstatus','msstatus_id');


package TapTinder::DB::Schema::patch;

__PACKAGE__->belongs_to('rep_path_id','TapTinder::DB::Schema::rep_path','rep_path_id');

__PACKAGE__->belongs_to('author_id','TapTinder::DB::Schema::rep_author','author_id');

__PACKAGE__->belongs_to('fsfile_id','TapTinder::DB::Schema::fsfile','fsfile_id');

__PACKAGE__->belongs_to('new_patch_id','TapTinder::DB::Schema::patch','new_patch_id',{join_type => 'left'});

__PACKAGE__->has_many('get_patch', 'TapTinder::DB::Schema::patch', 'new_patch_id');
__PACKAGE__->has_many('get_jobp', 'TapTinder::DB::Schema::jobp', 'patch_id');

package TapTinder::DB::Schema::rep_file;

__PACKAGE__->belongs_to('rep_path_id','TapTinder::DB::Schema::rep_path','rep_path_id');

__PACKAGE__->has_many('get_rep_file_change', 'TapTinder::DB::Schema::rep_file_change', 'rep_file_id');
__PACKAGE__->has_many('get_rep_file_change_from', 'TapTinder::DB::Schema::rep_file_change_from', 'rep_file_id');
__PACKAGE__->has_many('get_rep_file_change_from', 'TapTinder::DB::Schema::rep_file_change_from', 'from_rep_file_id');
__PACKAGE__->has_many('get_rep_test', 'TapTinder::DB::Schema::rep_test', 'rep_file_id');
__PACKAGE__->has_many('get_tfile', 'TapTinder::DB::Schema::tfile', 'rep_file_id');
__PACKAGE__->has_many('get_bfile', 'TapTinder::DB::Schema::bfile', 'rep_file_id');

package TapTinder::DB::Schema::fsfile;

__PACKAGE__->has_many('get_patch', 'TapTinder::DB::Schema::patch', 'fsfile_id');
__PACKAGE__->has_many('get_msjobp_cmd', 'TapTinder::DB::Schema::msjobp_cmd', 'output_id');
__PACKAGE__->belongs_to('fspath_id','TapTinder::DB::Schema::fspath','fspath_id');


package TapTinder::DB::Schema::param_type;

__PACKAGE__->has_many('get_param', 'TapTinder::DB::Schema::param', 'param_type_id');

package TapTinder::DB::Schema::project;

__PACKAGE__->has_many('get_rep', 'TapTinder::DB::Schema::rep', 'project_id');

package TapTinder::DB::Schema::msjobp;

__PACKAGE__->belongs_to('msjob_id','TapTinder::DB::Schema::msjob','msjob_id');

__PACKAGE__->belongs_to('jobp_id','TapTinder::DB::Schema::jobp','jobp_id');

__PACKAGE__->belongs_to('rev_id','TapTinder::DB::Schema::rev','rev_id');

__PACKAGE__->has_many('get_msjobp_cmd', 'TapTinder::DB::Schema::msjobp_cmd', 'msjobp_id');

package TapTinder::DB::Schema::rep_file_change;

__PACKAGE__->belongs_to('rev_id','TapTinder::DB::Schema::rev','rev_id');

__PACKAGE__->belongs_to('rep_file_id','TapTinder::DB::Schema::rep_file','rep_file_id');

__PACKAGE__->belongs_to('change_type_id','TapTinder::DB::Schema::rep_change_type','change_type_id');


package TapTinder::DB::Schema::rep_test;

__PACKAGE__->belongs_to('rep_file_id','TapTinder::DB::Schema::rep_file','rep_file_id');

__PACKAGE__->has_many('get_ttest', 'TapTinder::DB::Schema::ttest', 'rep_test_id');

package TapTinder::DB::Schema::msstatus;

__PACKAGE__->has_many('get_mslog', 'TapTinder::DB::Schema::mslog', 'msstatus_id');

package TapTinder::DB::Schema::tskipall_msg;

__PACKAGE__->has_many('get_tfile', 'TapTinder::DB::Schema::tfile', 'tskipall_msg_id');

package TapTinder::DB::Schema::brun;

__PACKAGE__->belongs_to('msjobp_cmd_id','TapTinder::DB::Schema::msjobp_cmd','msjobp_cmd_id');

__PACKAGE__->belongs_to('conf_id','TapTinder::DB::Schema::brun_conf','conf_id');

__PACKAGE__->has_many('get_bfile', 'TapTinder::DB::Schema::bfile', 'brun_id');

package TapTinder::DB::Schema::msjobp_cmd;

__PACKAGE__->belongs_to('jobp_cmd_id','TapTinder::DB::Schema::jobp_cmd','jobp_cmd_id');

__PACKAGE__->belongs_to('msjobp_id','TapTinder::DB::Schema::msjobp','msjobp_id');

__PACKAGE__->belongs_to('status_id','TapTinder::DB::Schema::cmd_status','status_id');

__PACKAGE__->belongs_to('output_id','TapTinder::DB::Schema::fsfile','output_id');

__PACKAGE__->has_many('get_build', 'TapTinder::DB::Schema::build', 'msjobp_cmd_id');
__PACKAGE__->has_many('get_trun', 'TapTinder::DB::Schema::trun', 'msjobp_cmd_id');
__PACKAGE__->has_many('get_brun', 'TapTinder::DB::Schema::brun', 'msjobp_cmd_id');

package TapTinder::DB::Schema::machine;

__PACKAGE__->belongs_to('user_id','TapTinder::DB::Schema::user','user_id');

__PACKAGE__->belongs_to('prev_machine_id','TapTinder::DB::Schema::machine','prev_machine_id',{join_type => 'left'});

__PACKAGE__->has_many('get_machine', 'TapTinder::DB::Schema::machine', 'prev_machine_id');
__PACKAGE__->belongs_to('farm_id','TapTinder::DB::Schema::farm','farm_id',{join_type => 'left'});

__PACKAGE__->has_many('get_machine_job_conf', 'TapTinder::DB::Schema::machine_job_conf', 'machine_id');
__PACKAGE__->has_many('get_msession', 'TapTinder::DB::Schema::msession', 'machine_id');

package TapTinder::DB::Schema::rep_file_change_from;

__PACKAGE__->belongs_to('rev_id','TapTinder::DB::Schema::rev','rev_id');

__PACKAGE__->belongs_to('rep_file_id','TapTinder::DB::Schema::rep_file','rep_file_id');

__PACKAGE__->belongs_to('from_rev_id','TapTinder::DB::Schema::rev','from_rev_id',{join_type => 'left'});

__PACKAGE__->belongs_to('from_rep_file_id','TapTinder::DB::Schema::rep_file','from_rep_file_id',{join_type => 'left'});


package TapTinder::DB::Schema::ttest;

__PACKAGE__->belongs_to('trun_id','TapTinder::DB::Schema::trun','trun_id');

__PACKAGE__->belongs_to('rep_test_id','TapTinder::DB::Schema::rep_test','rep_test_id');

__PACKAGE__->belongs_to('trest_id','TapTinder::DB::Schema::trest','trest_id');

__PACKAGE__->has_many('get_tdiag_msg', 'TapTinder::DB::Schema::tdiag_msg', 'ttest_id');

package TapTinder::DB::Schema::tdiag_msg;

__PACKAGE__->belongs_to('ttest_id','TapTinder::DB::Schema::ttest','ttest_id');


package TapTinder::DB::Schema::brun_conf;

__PACKAGE__->belongs_to('alias_conf_id','TapTinder::DB::Schema::brun_conf','alias_conf_id',{join_type => 'left'});

__PACKAGE__->has_many('get_brun_conf', 'TapTinder::DB::Schema::brun_conf', 'alias_conf_id');
__PACKAGE__->has_many('get_brun', 'TapTinder::DB::Schema::brun', 'conf_id');

package TapTinder::DB::Schema::build;

__PACKAGE__->belongs_to('msjobp_cmd_id','TapTinder::DB::Schema::msjobp_cmd','msjobp_cmd_id');

__PACKAGE__->belongs_to('conf_id','TapTinder::DB::Schema::build_conf','conf_id');


package TapTinder::DB::Schema::job;

__PACKAGE__->has_many('get_jobp', 'TapTinder::DB::Schema::jobp', 'job_id');
__PACKAGE__->has_many('get_machine_job_conf', 'TapTinder::DB::Schema::machine_job_conf', 'job_id');
__PACKAGE__->has_many('get_msjob', 'TapTinder::DB::Schema::msjob', 'job_id');

package TapTinder::DB::Schema::machine_job_conf;

__PACKAGE__->belongs_to('machine_id','TapTinder::DB::Schema::machine','machine_id');

__PACKAGE__->belongs_to('rep_id','TapTinder::DB::Schema::rep','rep_id');

__PACKAGE__->belongs_to('rep_path_id','TapTinder::DB::Schema::rep_path','rep_path_id');

__PACKAGE__->belongs_to('job_id','TapTinder::DB::Schema::job','job_id');


package TapTinder::DB::Schema::rep_author;

__PACKAGE__->belongs_to('rep_id','TapTinder::DB::Schema::rep','rep_id');

__PACKAGE__->belongs_to('user_id','TapTinder::DB::Schema::user','user_id',{join_type => 'left'});

__PACKAGE__->has_many('get_rev', 'TapTinder::DB::Schema::rev', 'author_id');
__PACKAGE__->has_many('get_patch', 'TapTinder::DB::Schema::patch', 'author_id');

package TapTinder::DB::Schema::trun;

__PACKAGE__->belongs_to('msjobp_cmd_id','TapTinder::DB::Schema::msjobp_cmd','msjobp_cmd_id');

__PACKAGE__->belongs_to('conf_id','TapTinder::DB::Schema::trun_conf','conf_id');

__PACKAGE__->has_many('get_tfile', 'TapTinder::DB::Schema::tfile', 'trun_id');
__PACKAGE__->has_many('get_ttest', 'TapTinder::DB::Schema::ttest', 'trun_id');

package TapTinder::DB::Schema::fspath_select;

__PACKAGE__->belongs_to('fsfile_type_id','TapTinder::DB::Schema::fsfile_type','fsfile_type_id');

__PACKAGE__->belongs_to('rep_path_id','TapTinder::DB::Schema::rep_path','rep_path_id');

__PACKAGE__->belongs_to('fspath_id','TapTinder::DB::Schema::fspath','fspath_id');


package TapTinder::DB::Schema::tfile;

__PACKAGE__->belongs_to('trun_id','TapTinder::DB::Schema::trun','trun_id');

__PACKAGE__->belongs_to('rep_file_id','TapTinder::DB::Schema::rep_file','rep_file_id');

__PACKAGE__->belongs_to('tskipall_msg_id','TapTinder::DB::Schema::tskipall_msg','tskipall_msg_id',{join_type => 'left'});


package TapTinder::DB::Schema::rep;

__PACKAGE__->belongs_to('project_id','TapTinder::DB::Schema::project','project_id');

__PACKAGE__->has_many('get_rep_author', 'TapTinder::DB::Schema::rep_author', 'rep_id');
__PACKAGE__->has_many('get_rev', 'TapTinder::DB::Schema::rev', 'rep_id');
__PACKAGE__->has_many('get_rep_path', 'TapTinder::DB::Schema::rep_path', 'rep_id');
__PACKAGE__->has_many('get_machine_job_conf', 'TapTinder::DB::Schema::machine_job_conf', 'rep_id');



package TapTinder::DB::Schema;
use base 'DBIx::Class::Schema';
use strict;
use warnings;

__PACKAGE__->register_class('rep_path', 'TapTinder::DB::Schema::rep_path');

__PACKAGE__->register_class('trun_conf', 'TapTinder::DB::Schema::trun_conf');

__PACKAGE__->register_class('rev_rep_path', 'TapTinder::DB::Schema::rev_rep_path');

__PACKAGE__->register_class('jobp_cmd', 'TapTinder::DB::Schema::jobp_cmd');

__PACKAGE__->register_class('rep_change_type', 'TapTinder::DB::Schema::rep_change_type');

__PACKAGE__->register_class('user', 'TapTinder::DB::Schema::user');

__PACKAGE__->register_class('param', 'TapTinder::DB::Schema::param');

__PACKAGE__->register_class('msession', 'TapTinder::DB::Schema::msession');

__PACKAGE__->register_class('build_conf', 'TapTinder::DB::Schema::build_conf');

__PACKAGE__->register_class('msabort_reason', 'TapTinder::DB::Schema::msabort_reason');

__PACKAGE__->register_class('msjob', 'TapTinder::DB::Schema::msjob');

__PACKAGE__->register_class('fsfile_type', 'TapTinder::DB::Schema::fsfile_type');

__PACKAGE__->register_class('cmd', 'TapTinder::DB::Schema::cmd');

__PACKAGE__->register_class('bfile', 'TapTinder::DB::Schema::bfile');

__PACKAGE__->register_class('cmd_status', 'TapTinder::DB::Schema::cmd_status');

__PACKAGE__->register_class('farm', 'TapTinder::DB::Schema::farm');

__PACKAGE__->register_class('trest', 'TapTinder::DB::Schema::trest');

__PACKAGE__->register_class('jobp', 'TapTinder::DB::Schema::jobp');

__PACKAGE__->register_class('rev', 'TapTinder::DB::Schema::rev');

__PACKAGE__->register_class('fspath', 'TapTinder::DB::Schema::fspath');

__PACKAGE__->register_class('mslog', 'TapTinder::DB::Schema::mslog');

__PACKAGE__->register_class('patch', 'TapTinder::DB::Schema::patch');

__PACKAGE__->register_class('rep_file', 'TapTinder::DB::Schema::rep_file');

__PACKAGE__->register_class('fsfile', 'TapTinder::DB::Schema::fsfile');

__PACKAGE__->register_class('param_type', 'TapTinder::DB::Schema::param_type');

__PACKAGE__->register_class('project', 'TapTinder::DB::Schema::project');

__PACKAGE__->register_class('msjobp', 'TapTinder::DB::Schema::msjobp');

__PACKAGE__->register_class('rep_file_change', 'TapTinder::DB::Schema::rep_file_change');

__PACKAGE__->register_class('rep_test', 'TapTinder::DB::Schema::rep_test');

__PACKAGE__->register_class('msstatus', 'TapTinder::DB::Schema::msstatus');

__PACKAGE__->register_class('tskipall_msg', 'TapTinder::DB::Schema::tskipall_msg');

__PACKAGE__->register_class('brun', 'TapTinder::DB::Schema::brun');

__PACKAGE__->register_class('msjobp_cmd', 'TapTinder::DB::Schema::msjobp_cmd');

__PACKAGE__->register_class('machine', 'TapTinder::DB::Schema::machine');

__PACKAGE__->register_class('rep_file_change_from', 'TapTinder::DB::Schema::rep_file_change_from');

__PACKAGE__->register_class('ttest', 'TapTinder::DB::Schema::ttest');

__PACKAGE__->register_class('tdiag_msg', 'TapTinder::DB::Schema::tdiag_msg');

__PACKAGE__->register_class('brun_conf', 'TapTinder::DB::Schema::brun_conf');

__PACKAGE__->register_class('build', 'TapTinder::DB::Schema::build');

__PACKAGE__->register_class('job', 'TapTinder::DB::Schema::job');

__PACKAGE__->register_class('machine_job_conf', 'TapTinder::DB::Schema::machine_job_conf');

__PACKAGE__->register_class('rep_author', 'TapTinder::DB::Schema::rep_author');

__PACKAGE__->register_class('trun', 'TapTinder::DB::Schema::trun');

__PACKAGE__->register_class('fspath_select', 'TapTinder::DB::Schema::fspath_select');

__PACKAGE__->register_class('tfile', 'TapTinder::DB::Schema::tfile');

__PACKAGE__->register_class('rep', 'TapTinder::DB::Schema::rep');

1;
