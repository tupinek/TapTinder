package TapTinder::Utils::Cmd;

use strict;
use warnings;

our @EXPORT_OK = qw(run_cmd_ipc);


sub run_cmd_ipc {
    my ( $cmd, $noipc, $msg ) = @_;

    $! = undef;
    $@ = undef;
    if ( ! $noipc ) {
        print $msg;
    }
    my $ret_code = system( $cmd );
    print "Cmd return code: $ret_code - ";
    if ( $ret_code ) {
        print "error";
    } else {
        print "ok";
    }
    print "\n";

    print $! if $!;
    print $@ if $@;
    my $neg_ret_code = ! $ret_code;
    return $neg_ret_code;
}


1;
