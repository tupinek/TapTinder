package TapTinder::DB::Schema::rep_path;
use base 'DBIx::Class';
use strict;
use warnings;

__PACKAGE__->load_components(qw/ Core/);
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
);
__PACKAGE__->set_primary_key('rep_path_id');


package TapTinder::DB::Schema::project;
use base 'DBIx::Class';
use strict;
use warnings;

__PACKAGE__->load_components(qw/ Core/);
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
    'info' => {
      'data_type' => 'TEXT',
      'is_auto_increment' => 0,
      'default_value' => 'NULL',
      'is_foreign_key' => 0,
      'name' => 'info',
      'is_nullable' => 1,
      'size' => '65535'
    },
);
__PACKAGE__->set_primary_key('project_id');


package TapTinder::DB::Schema::rep_test;
use base 'DBIx::Class';
use strict;
use warnings;

__PACKAGE__->load_components(qw/ Core/);
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


package TapTinder::DB::Schema::rep_file_change;
use base 'DBIx::Class';
use strict;
use warnings;

__PACKAGE__->load_components(qw/ Core/);
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
    'rep_file_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 1,
      'name' => 'rep_file_id',
      'is_nullable' => 0,
      'size' => '11'
    },
    'change_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 1,
      'name' => 'change_id',
      'is_nullable' => 0,
      'size' => '11'
    },
);


package TapTinder::DB::Schema::tskipall_msg;
use base 'DBIx::Class';
use strict;
use warnings;

__PACKAGE__->load_components(qw/ Core/);
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


package TapTinder::DB::Schema::rev_rep_path;
use base 'DBIx::Class';
use strict;
use warnings;

__PACKAGE__->load_components(qw/ Core/);
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


package TapTinder::DB::Schema::user;
use base 'DBIx::Class';
use strict;
use warnings;

__PACKAGE__->load_components(qw/ Core/);
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


package TapTinder::DB::Schema::rep_file_change_from;
use base 'DBIx::Class';
use strict;
use warnings;

__PACKAGE__->load_components(qw/ Core/);
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


package TapTinder::DB::Schema::user_rep;
use base 'DBIx::Class';
use strict;
use warnings;

__PACKAGE__->load_components(qw/ Core/);
__PACKAGE__->table('user_rep');


__PACKAGE__->add_columns(
    'user_rep_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 1,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'user_rep_id',
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
__PACKAGE__->set_primary_key('user_rep_id');


package TapTinder::DB::Schema::ttest;
use base 'DBIx::Class';
use strict;
use warnings;

__PACKAGE__->load_components(qw/ Core/);
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
    'tresult_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 1,
      'name' => 'tresult_id',
      'is_nullable' => 0,
      'size' => '11'
    },
);
__PACKAGE__->set_primary_key('ttest_id');


package TapTinder::DB::Schema::tdiag_msg;
use base 'DBIx::Class';
use strict;
use warnings;

__PACKAGE__->load_components(qw/ Core/);
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


package TapTinder::DB::Schema::change;
use base 'DBIx::Class';
use strict;
use warnings;

__PACKAGE__->load_components(qw/ Core/);
__PACKAGE__->table('change');


__PACKAGE__->add_columns(
    'change_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'change_id',
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
    'info' => {
      'data_type' => 'VARCHAR',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'info',
      'is_nullable' => 0,
      'size' => '10'
    },
);
__PACKAGE__->set_primary_key('change_id');


package TapTinder::DB::Schema::conf;
use base 'DBIx::Class';
use strict;
use warnings;

__PACKAGE__->load_components(qw/ Core/);
__PACKAGE__->table('conf');


__PACKAGE__->add_columns(
    'conf_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 1,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'conf_id',
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
    'harness_args' => {
      'data_type' => 'VARCHAR',
      'is_auto_increment' => 0,
      'default_value' => 'NULL',
      'is_foreign_key' => 0,
      'name' => 'harness_args',
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
      'is_foreign_key' => 0,
      'name' => 'alias_conf_id',
      'is_nullable' => 1,
      'size' => '11'
    },
);
__PACKAGE__->set_primary_key('conf_id');


package TapTinder::DB::Schema::tresult;
use base 'DBIx::Class';
use strict;
use warnings;

__PACKAGE__->load_components(qw/ Core/);
__PACKAGE__->table('tresult');


__PACKAGE__->add_columns(
    'tresult_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'tresult_id',
      'is_nullable' => 0,
      'size' => '11'
    },
    'title' => {
      'data_type' => 'VARCHAR',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'title',
      'is_nullable' => 1,
      'size' => '10'
    },
    'info' => {
      'data_type' => 'VARCHAR',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'info',
      'is_nullable' => 1,
      'size' => '255'
    },
);
__PACKAGE__->set_primary_key('tresult_id');


package TapTinder::DB::Schema::client;
use base 'DBIx::Class';
use strict;
use warnings;

__PACKAGE__->load_components(qw/ Core/);
__PACKAGE__->table('client');


__PACKAGE__->add_columns(
    'client_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 1,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'client_id',
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
      'default_value' => 'NULL',
      'is_foreign_key' => 0,
      'name' => 'name',
      'is_nullable' => 1,
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
    'info' => {
      'data_type' => 'TEXT',
      'is_auto_increment' => 0,
      'default_value' => 'NULL',
      'is_foreign_key' => 0,
      'name' => 'info',
      'is_nullable' => 1,
      'size' => '65535'
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
    'active' => {
      'data_type' => 'BOOLEAN',
      'is_auto_increment' => 0,
      'default_value' => '1',
      'is_foreign_key' => 0,
      'name' => 'active',
      'is_nullable' => 0,
      'size' => 0
    },
    'prev_client_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => 'NULL',
      'is_foreign_key' => 1,
      'name' => 'prev_client_id',
      'is_nullable' => 1,
      'size' => '11'
    },
);
__PACKAGE__->set_primary_key('client_id');


package TapTinder::DB::Schema::trun;
use base 'DBIx::Class';
use strict;
use warnings;

__PACKAGE__->load_components(qw/ Core/);
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
    'client_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 1,
      'name' => 'client_id',
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


package TapTinder::DB::Schema::rev;
use base 'DBIx::Class';
use strict;
use warnings;

__PACKAGE__->load_components(qw/ Core/);
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


package TapTinder::DB::Schema::tfile;
use base 'DBIx::Class';
use strict;
use warnings;

__PACKAGE__->load_components(qw/ Core/);
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
    'tskippall_msg_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => 'NULL',
      'is_foreign_key' => 0,
      'name' => 'tskippall_msg_id',
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


package TapTinder::DB::Schema::rep_file;
use base 'DBIx::Class';
use strict;
use warnings;

__PACKAGE__->load_components(qw/ Core/);
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


package TapTinder::DB::Schema::rep;
use base 'DBIx::Class';
use strict;
use warnings;

__PACKAGE__->load_components(qw/ Core/);
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
    'active' => {
      'data_type' => 'BOOLEAN',
      'is_auto_increment' => 0,
      'default_value' => '1',
      'is_foreign_key' => 0,
      'name' => 'active',
      'is_nullable' => 0,
      'size' => 0
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
    'url' => {
      'data_type' => 'VARCHAR',
      'is_auto_increment' => 0,
      'default_value' => 'NULL',
      'is_foreign_key' => 0,
      'name' => 'url',
      'is_nullable' => 1,
      'size' => '255'
    },
    'info' => {
      'data_type' => 'TEXT',
      'is_auto_increment' => 0,
      'default_value' => 'NULL',
      'is_foreign_key' => 0,
      'name' => 'info',
      'is_nullable' => 1,
      'size' => '65535'
    },
);
__PACKAGE__->set_primary_key('rep_id');

package TapTinder::DB::Schema::rep_path;

__PACKAGE__->belongs_to('rep_id', 'TapTinder::DB::Schema::rep');

__PACKAGE__->has_many('get_rev_rep_path', 'TapTinder::DB::Schema::rev_rep_path', 'rep_path_id');
__PACKAGE__->has_many('get_rep_file', 'TapTinder::DB::Schema::rep_file', 'rep_path_id');
__PACKAGE__->has_many('get_trun', 'TapTinder::DB::Schema::trun', 'rep_path_id');

package TapTinder::DB::Schema::project;

__PACKAGE__->has_many('get_rep', 'TapTinder::DB::Schema::rep', 'project_id');

package TapTinder::DB::Schema::rep_test;

__PACKAGE__->belongs_to('rep_file_id', 'TapTinder::DB::Schema::rep_file');

__PACKAGE__->has_many('get_ttest', 'TapTinder::DB::Schema::ttest', 'rep_test_id');

package TapTinder::DB::Schema::rep_file_change;

__PACKAGE__->belongs_to('rev_id', 'TapTinder::DB::Schema::rev');

__PACKAGE__->belongs_to('rep_file_id', 'TapTinder::DB::Schema::rep_file');

__PACKAGE__->belongs_to('change_id', 'TapTinder::DB::Schema::change');


package TapTinder::DB::Schema::rev_rep_path;

__PACKAGE__->belongs_to('rev_id', 'TapTinder::DB::Schema::rev');

__PACKAGE__->belongs_to('rep_path_id', 'TapTinder::DB::Schema::rep_path');


package TapTinder::DB::Schema::user;

__PACKAGE__->has_many('get_client', 'TapTinder::DB::Schema::client', 'user_id');
__PACKAGE__->has_many('get_user_rep', 'TapTinder::DB::Schema::user_rep', 'user_id');

package TapTinder::DB::Schema::rep_file_change_from;

__PACKAGE__->belongs_to('rev_id', 'TapTinder::DB::Schema::rev');

__PACKAGE__->belongs_to('rep_file_id', 'TapTinder::DB::Schema::rep_file');

__PACKAGE__->belongs_to('from_rev_id', 'TapTinder::DB::Schema::rev');

__PACKAGE__->belongs_to('from_rep_file_id', 'TapTinder::DB::Schema::rep_file');


package TapTinder::DB::Schema::user_rep;

__PACKAGE__->belongs_to('user_id', 'TapTinder::DB::Schema::user');

__PACKAGE__->belongs_to('rep_id', 'TapTinder::DB::Schema::rep');

__PACKAGE__->has_many('get_rev', 'TapTinder::DB::Schema::rev', 'author_id');

package TapTinder::DB::Schema::ttest;

__PACKAGE__->belongs_to('trun_id', 'TapTinder::DB::Schema::trun');

__PACKAGE__->belongs_to('rep_test_id', 'TapTinder::DB::Schema::rep_test');

__PACKAGE__->belongs_to('tresult_id', 'TapTinder::DB::Schema::tresult');

__PACKAGE__->has_many('get_tdiag_msg', 'TapTinder::DB::Schema::tdiag_msg', 'ttest_id');

package TapTinder::DB::Schema::tdiag_msg;

__PACKAGE__->belongs_to('ttest_id', 'TapTinder::DB::Schema::ttest');


package TapTinder::DB::Schema::change;

__PACKAGE__->has_many('get_rep_file_change', 'TapTinder::DB::Schema::rep_file_change', 'change_id');

package TapTinder::DB::Schema::conf;

__PACKAGE__->has_many('get_trun', 'TapTinder::DB::Schema::trun', 'conf_id');

package TapTinder::DB::Schema::tresult;

__PACKAGE__->has_many('get_ttest', 'TapTinder::DB::Schema::ttest', 'tresult_id');

package TapTinder::DB::Schema::client;

__PACKAGE__->belongs_to('user_id', 'TapTinder::DB::Schema::user');

__PACKAGE__->belongs_to('prev_client_id', 'TapTinder::DB::Schema::client');

__PACKAGE__->has_many('get_client', 'TapTinder::DB::Schema::client', 'prev_client_id');
__PACKAGE__->has_many('get_trun', 'TapTinder::DB::Schema::trun', 'client_id');

package TapTinder::DB::Schema::trun;

__PACKAGE__->belongs_to('rev_id', 'TapTinder::DB::Schema::rev');

__PACKAGE__->belongs_to('rep_path_id', 'TapTinder::DB::Schema::rep_path');

__PACKAGE__->belongs_to('client_id', 'TapTinder::DB::Schema::client');

__PACKAGE__->belongs_to('conf_id', 'TapTinder::DB::Schema::conf');

__PACKAGE__->has_many('get_tfile', 'TapTinder::DB::Schema::tfile', 'trun_id');
__PACKAGE__->has_many('get_ttest', 'TapTinder::DB::Schema::ttest', 'trun_id');

package TapTinder::DB::Schema::rev;

__PACKAGE__->belongs_to('rep_id', 'TapTinder::DB::Schema::rep');

__PACKAGE__->belongs_to('author_id', 'TapTinder::DB::Schema::user_rep');

__PACKAGE__->has_many('get_rev_rep_path', 'TapTinder::DB::Schema::rev_rep_path', 'rev_id');
__PACKAGE__->has_many('get_rep_file_change', 'TapTinder::DB::Schema::rep_file_change', 'rev_id');
__PACKAGE__->has_many('get_rep_file_change_from', 'TapTinder::DB::Schema::rep_file_change_from', 'rev_id');
__PACKAGE__->has_many('get_rep_file_change_from', 'TapTinder::DB::Schema::rep_file_change_from', 'from_rev_id');
__PACKAGE__->has_many('get_trun', 'TapTinder::DB::Schema::trun', 'rev_id');

package TapTinder::DB::Schema::tfile;

__PACKAGE__->belongs_to('trun_id', 'TapTinder::DB::Schema::trun');

__PACKAGE__->belongs_to('rep_file_id', 'TapTinder::DB::Schema::rep_file');


package TapTinder::DB::Schema::rep_file;

__PACKAGE__->belongs_to('rep_path_id', 'TapTinder::DB::Schema::rep_path');

__PACKAGE__->has_many('get_rep_file_change', 'TapTinder::DB::Schema::rep_file_change', 'rep_file_id');
__PACKAGE__->has_many('get_rep_file_change_from', 'TapTinder::DB::Schema::rep_file_change_from', 'rep_file_id');
__PACKAGE__->has_many('get_rep_file_change_from', 'TapTinder::DB::Schema::rep_file_change_from', 'from_rep_file_id');
__PACKAGE__->has_many('get_rep_test', 'TapTinder::DB::Schema::rep_test', 'rep_file_id');
__PACKAGE__->has_many('get_tfile', 'TapTinder::DB::Schema::tfile', 'rep_file_id');

package TapTinder::DB::Schema::rep;

__PACKAGE__->belongs_to('project_id', 'TapTinder::DB::Schema::project');

__PACKAGE__->has_many('get_user_rep', 'TapTinder::DB::Schema::user_rep', 'rep_id');
__PACKAGE__->has_many('get_rev', 'TapTinder::DB::Schema::rev', 'rep_id');
__PACKAGE__->has_many('get_rep_path', 'TapTinder::DB::Schema::rep_path', 'rep_id');



package TapTinder::DB::Schema;
use base 'DBIx::Class::Schema';
use strict;
use warnings;

__PACKAGE__->register_class('rep_path', 'TapTinder::DB::Schema::rep_path');

__PACKAGE__->register_class('project', 'TapTinder::DB::Schema::project');

__PACKAGE__->register_class('rep_test', 'TapTinder::DB::Schema::rep_test');

__PACKAGE__->register_class('rep_file_change', 'TapTinder::DB::Schema::rep_file_change');

__PACKAGE__->register_class('tskipall_msg', 'TapTinder::DB::Schema::tskipall_msg');

__PACKAGE__->register_class('rev_rep_path', 'TapTinder::DB::Schema::rev_rep_path');

__PACKAGE__->register_class('user', 'TapTinder::DB::Schema::user');

__PACKAGE__->register_class('rep_file_change_from', 'TapTinder::DB::Schema::rep_file_change_from');

__PACKAGE__->register_class('user_rep', 'TapTinder::DB::Schema::user_rep');

__PACKAGE__->register_class('ttest', 'TapTinder::DB::Schema::ttest');

__PACKAGE__->register_class('tdiag_msg', 'TapTinder::DB::Schema::tdiag_msg');

__PACKAGE__->register_class('change', 'TapTinder::DB::Schema::change');

__PACKAGE__->register_class('conf', 'TapTinder::DB::Schema::conf');

__PACKAGE__->register_class('tresult', 'TapTinder::DB::Schema::tresult');

__PACKAGE__->register_class('client', 'TapTinder::DB::Schema::client');

__PACKAGE__->register_class('trun', 'TapTinder::DB::Schema::trun');

__PACKAGE__->register_class('rev', 'TapTinder::DB::Schema::rev');

__PACKAGE__->register_class('tfile', 'TapTinder::DB::Schema::tfile');

__PACKAGE__->register_class('rep_file', 'TapTinder::DB::Schema::rep_file');

__PACKAGE__->register_class('rep', 'TapTinder::DB::Schema::rep');

1;
