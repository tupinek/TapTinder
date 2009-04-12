package TapTinder::Client::KeyPress;

use strict;
use warnings;
use Carp qw(carp croak verbose);

use base 'Exporter';
our $VERSION = 0.01;
our @EXPORT = qw(last_pressed_key process_keypress sleep_and_process_keypress cleanup_before_exit);

use Term::ReadKey;
our $ver = 0;

our $hooks = {};
$hooks->{before_exit} = sub {
    Term::ReadKey::ReadMode('normal');
};
$hooks->{pause_begin} = sub {};
$hooks->{pause_end} = sub {};

sub cleanup_before_exit {
    $hooks->{before_exit}->();
    return 1;
}


sub last_pressed_key() {
    my $char = undef;
    my $t_char = undef;
    while ( defined ($t_char = ReadKey(-1)) ) {
        $char = $t_char if $t_char;
        #print "|$t_char|\n";
    }
    return $char;
}


sub process_keypress() {
    my $paused = undef;
    while ( $paused || not defined $paused ) {
        my $char = last_pressed_key();
        if ( $char ) {
            $char = uc( $char );
            if ( $char eq 'P' ) {
                $hooks->{pause_begin}->() unless $paused;
                print "Paused. Press C to continue ...\n";
                print "User press pause key.\n" if $ver > 2;
                $paused = 1;

            } elsif ( $char eq 'C' ) {
                print "User press continue key.\n" if $ver > 2;
                $hooks->{pause_end}->() if $paused;
                $paused = 0;

            } elsif ( $char eq 'Q' || $char eq 'E' ) {
                print "User press exit key.\n" if $ver > 2;
                cleanup_before_exit();
                exit;

            } else {
                print "User press unknown key '$char'.\n" if $ver > 3;
            }
        }
        $paused = 0 unless defined $paused;
    }
    return 1;
}


sub sleep_and_process_keypress {
    my ( $sleep_time ) = @_;

    my $start_time = time();
    my $num = 0;
    while ( time() - $start_time < $sleep_time ) {
        process_keypress();
        sleep 1;
        if ( $ver > 9 ) {
            print ".";
            if ( $num < (time() - $start_time) / 10 - 1 ) {
                print "\n";
                $num++;
            }
        }
    }
    print "\n" if $ver > 2;
    return 1;
}


1;
