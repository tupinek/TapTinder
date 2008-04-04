use strict;
use warnings;
use lib qw( lib . ../lib ../../lib );

use TAPTinder::KeyPress qw(process_keypress sleep_and_process_keypress);
$TAPTinder::KeyPress::ver = 10;

#ReadMode('cbreak');

sub run_sleep {
    my ( $time, $msg ) = @_;

    print $msg if defined $msg;
    my $cmd = qq{ perl -e"select(STDOUT); \$| = 1; foreach (1..$time) { print '.'; sleep 1; }"};
    #print "cmd: '$cmd'\n";
    system($cmd);
    print "\n";
}


select(STDOUT); $| = 1;

print "Begin.\n";


run_sleep( 2, 'a1' );
process_keypress();

run_sleep( 2, 'a2' );
process_keypress();


print "b1";
sleep_and_process_keypress( 3 );

print "b2";
sleep_and_process_keypress( 3 );


print "Normal end.\n";
