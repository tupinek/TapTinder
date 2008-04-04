use strict;
use warnings;
use lib qw( lib . ../lib ../../lib );

use TAPTinder::KeyPress qw(process_keypress sleep_and_process_keypress);
$TAPTinder::KeyPress::ver = 10;

Term::ReadKey::ReadMode('cbreak');

sub run_sleep {
    my ( $time, $msg ) = @_;

    print $msg if defined $msg;
    my $cmd = qq{ perl -e"select(STDOUT); \$| = 1; foreach (1..$time) { print '.'; sleep 1; }"};
    #print "cmd: '$cmd'\n";
    system($cmd);
    print "\n";
}

sub sig_handler() {
    my ( $signal ) = @_;
    print("Recieved signal: $signal\n");
    Term::ReadKey::ReadMode('restore');
    exit;
}
#foreach ( keys %SIG ) { $SIG{$_} = \&sig_handler; }
$SIG{'KILL'}  = \&sig_handler;
$SIG{'INT'}  = \&sig_handler;
$SIG{'QUIT'} = \&sig_handler;  


select(STDOUT); $| = 1;

print "Begin.\n";

run_sleep( 2, 'a1-2 ' );
process_keypress();

run_sleep( 2, 'a2-2 ' );
process_keypress();

print 'b1-3 ';
sleep_and_process_keypress( 3 );

print 'b2-3 ';
sleep_and_process_keypress( 3 );

print 'c2-35 ';
sleep_and_process_keypress( 35 );

print "Normal end.\n";
