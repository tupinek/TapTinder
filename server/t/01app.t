use strict;
use warnings;
use Test::More tests => 2;

use lib 'lib';

BEGIN { use_ok 'Catalyst::Test', 'TapTinder::Web' }

ok( request('/')->is_success, 'Request should succeed' );
