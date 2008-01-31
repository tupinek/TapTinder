#! perl

# Copyright (C) 2005-2007, The Perl Foundation.
# $Id: smokeserv-client.pl 21252 2007-09-13 06:36:05Z paultcochrane $

use strict;
use warnings;

use Getopt::Long;
use LWP::UserAgent;
use YAML;

use constant VERSION => 0.01;
sub debug($);

our $compress = sub { return };

my $project_name = $ARGV[0] || die "No project name\n";
my $file = $ARGV[1] || die "No file to upload.\n";
my $conf_fname = $ARGV[2] || die "No config file path.\n";

my ( $all_conf ) = YAML::LoadFile( $conf_fname );
my $conf = $all_conf->{$project_name};

debug "taptinder client upload v" . VERSION . " started.\n";

setup_compression() if $conf->{compressupload};

my %request = ( upload => 1, version => VERSION, smokes => [] );

{
    debug "Reading smoke \"$file\" to upload... ";

    open my $fh, "<", $file or die "Couldn't open \"$file\" for reading: $!\n";
    local $/;
    my $smoke = <$fh>;

    unless ( $smoke =~ /^-{3}/ ) {
        debug "doesn't look like a smoke; aborting.\n";
        exit 1;
    }

    $request{smoke} = $compress->($smoke) || $smoke;
    debug "ok.\n";
}

{
    my $taptinderserv = $conf->{taptinderserv};
    debug "Sending data to taptinderserv \"$taptinderserv\"... ";
    my $ua = LWP::UserAgent->new;
    $ua->agent( "taptinder-client-upload/" . VERSION );
    $ua->env_proxy;

    my $resp = $ua->post( $taptinderserv => \%request );
    if ( $resp->is_success ) {
        if ( $resp->content =~ /^ok/ ) {
            debug "success!\n";
            exit 0;
        }
        else {
            #debug "error:\n" . $resp->as_string . "\n";
            debug "error: " . $resp->content . "\n";
            exit 1;
        }
    }
    else {
        debug "error: " . $resp->status_line . "\n";
        exit 1;
    }
}

# Nice debugging output.
{
    my $fresh;

    sub debug($) {
        my $msg = shift;

        print STDERR "* " and $fresh++ unless $fresh;
        print STDERR $msg;
        $fresh = 0 if substr( $msg, -1 ) eq "\n";
        1;
    }
}

sub setup_compression {
    eval { require Compress::Bzip2; debug "Bzip2 compression on\n" }
        and return $compress = sub { Compress::Bzip2::memBzip(shift) };
    eval { require Compress::Zlib; debug "Gzip compression on\n" }
        and $compress = sub { Compress::Zlib::memGzip(shift) };
}

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:
