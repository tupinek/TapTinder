use strict;
use warnings;
use Test::More tests => 2;

use lib 'lib';

BEGIN {
    use_ok 'TapTinder::Web';
    use_ok 'TapTinder::Web::Model::WebDB';
}

