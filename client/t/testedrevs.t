use strict;
use warnings;
use lib qw( lib . ../lib ../../lib );
use Test::More;

use TAPTinder::TestedRevs;

# project_name
my $pname = 'test-' . $$;

my $trevs = get_tested_revisions( $pname );

plan tests => 19;

is_deeply( $trevs, {}, 'empty' );

my $to_test;
$to_test = get_revision_to_test( $pname, 1 );
is( $to_test, undef, 'to test if actual is 1' );

$to_test = get_revision_to_test( $pname, 5 );
is( $to_test, 4, 'to test if actual is 5' );


revision_test_done( $pname, 5 );
$trevs = get_tested_revisions( $pname );
is_deeply( $trevs, { 5 => 1, }, 'contains 5' );

$to_test = get_revision_to_test( $pname, 20 );
is( $to_test, 20, 'to test is ok - 20' );

$to_test = get_revision_to_test( $pname, 5 );
is( $to_test, 4, 'to test is ok - 4' );

$to_test = get_revision_to_test( $pname, 4 );
is( $to_test, 4, 'to test is ok - 4' );


revision_test_done( $pname, 4 );
$trevs = get_tested_revisions( $pname );
is_deeply( $trevs, { 4 => 1, 5 => 1, }, 'contains 4 and 5' );

$to_test = get_revision_to_test( $pname, 20 );
is( $to_test, 20, 'to test is ok - 20' );

$to_test = get_revision_to_test( $pname, 5 );
is( $to_test, 3, 'to test is ok - 3' );


revision_test_done( $pname, 3 );
revision_test_done( $pname, 2 );
$trevs = get_tested_revisions( $pname );
is_deeply( $trevs, { 2 => 1, 3 => 1, 4 => 1, 5 => 1, }, 'contains 2..5' );

$to_test = get_revision_to_test( $pname, 20 );
is( $to_test, 20, 'to test is ok - 20' );

$to_test = get_revision_to_test( $pname, 6 );
is( $to_test, 6, 'to test is ok - 6' );

$to_test = get_revision_to_test( $pname, 5 );
is( $to_test, 1, 'to test is ok - 1' );


revision_test_done( $pname, 1 );
$to_test = get_revision_to_test( $pname, 5 );
is( $to_test, undef, 'to test is ok - undef' );


revision_test_done( $pname, 20 );
$trevs = get_tested_revisions( $pname );
is_deeply( $trevs, { 1 => 1, 2=>1, 3=>1, 4=>1, 5=>1, 20=>1, }, 'contains 1..5 and 20' );

$to_test = get_revision_to_test( $pname, 30 );
is( $to_test, 30, 'to test is ok - 30' );

$to_test = get_revision_to_test( $pname, 20 );
is( $to_test, 19, 'to test is ok' );

ok( unlink_state_file( $pname ), 'unlink ok' );
