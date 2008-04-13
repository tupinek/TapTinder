#!/usr/bin/perl

use strict;
use warnings;
#use warnings FATAL => 'all';

use CGI qw/:standard :cgi-lib/;
use CGI::Carp qw(fatalsToBrowser);

use lib qw(../../server/lib);

use DBIx::Class;
use TapTinder::DB::Schema;

our $RealBin = '/home2/web/perl6/taptinder-dev/server-htdocs/';

our $db;
our $par;
our $view_def;


sub get_db {
    my $conf_fpath = $RealBin . '../server/conf/dbconf.pl';
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
    require $RealBin . 'templ/head.pl';
    
    # Execute a joined query to get the cds.
    #my @all_john_cds = $johns_rs->search_related('cds')->all;
  
    my $client_rs = $db->resultset('client')->get_column('name');
    print "<pre>\n";
    foreach my $client ( $client_rs->all ) {
        print "${client}\n";
    }
    print "</pre>\n";
    print "done\n";
  
    require $RealBin . 'templ/foot.pl';
    return 1;
}

$db = get_db();
$par = Vars();
start();
