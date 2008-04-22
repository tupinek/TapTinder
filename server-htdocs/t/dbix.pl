#!/usr/bin/perl

use strict;
use warnings;
#use warnings FATAL => 'all';

use CGI qw/:standard :cgi-lib/;
use CGI::Carp qw(fatalsToBrowser);

our $BaseDir;
our $ServerDir;
BEGIN {
    use FindBin qw/$RealBin/;
    $BaseDir = $RealBin . '/../';
    $ServerDir = $RealBin . '/../../server/';
};

use lib "${ServerDir}lib";

use DBIx::Class;
use TapTinder::DB::Schema;

our $db;
our $par;
our $view_def;


sub get_db {
    my $conf_fpath = $ServerDir . 'conf/dbconf.pl';
    my $conf = require $conf_fpath;

    croak "Config loaded from '$conf_fpath' is empty.\n" unless $conf;

    my $db = TapTinder::DB::Schema->connect(
        $conf->{db}->{dsn},
        $conf->{db}->{user},
        $conf->{db}->{password},
        {}
    );
    return $db;
}


sub start {
    return do_show() if !$par->{ac} || $par->{ac} eq 'show';

    print "Content-type: text/plain\n\n";
    print "Unknown param 'ac'.";
    return 1;
}


sub do_show {
    require $BaseDir . 'templ/head.pl';

    # Execute a joined query to get the cds.
    #my @all_john_cds = $johns_rs->search_related('cds')->all;

    my $machine_rs = $db->resultset('machine')->get_column('name');
    print "<pre>\n";
    foreach my $machine ( $machine_rs->all ) {
        print "${machine}\n";
    }
    print "</pre>\n";
    print "done\n";

    require $BaseDir . 'templ/foot.pl';
    return 1;
}

$db = get_db();
$par = Vars();
start();
