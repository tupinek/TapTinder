use strict;
use warnings;
use Test::More tests => 3;

use lib 'lib';

BEGIN { use_ok 'Catalyst::Test', 'TapTinder::Web' }
BEGIN { use_ok 'TapTinder::Web::Controller::Table' }

ok( request('/table')->is_success, 'table request should succeed' );
