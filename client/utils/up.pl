#!/usr/bin/perl

$ENV{PERL5LIB} = '/home2/scripts/mj41/taptinder/libcpan';

opendir( $dh, './' ) || die $!;

while ( my $dir = readdir($dh) ) {
    print "dir: $dir\n";
    next if $dir eq '.' || $dir eq '..';
    my $res_fp = $dir . '/taptinder-results.yaml';
    system('/usr/bin/perl /home2/scripts/mj41/taptinder/client/upload.pl parrot ' . $res_fp . ' /home2/scripts/mj41/taptinder/client-conf/client-conf-ent.yaml');
}

close( $dh );