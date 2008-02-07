use strict;
use warnings;

use Carp qw(carp croak verbose);
use File::stat;
use Data::Dumper;

our $debug = $ARGV[0];

sub load_data {
    my ( $fp ) = @_;

    my $data;
    eval {
        #use YAML::Tiny;
	#my $yaml = YAML::Tiny->read( $fp ); 
	#$data = $yaml->[0];
	use YAML::Syck;
	$data = LoadFile( $fp );
        delete $data->{results};
    };

    if ( $@ ) {
	carp $@;
	print "Using YAML ...\n";
	eval {
	    use YAML;
	    my ( $rh, $ra, $sc ) = YAML::LoadFile( $fp );
	    $data = $rh;
	};
        if ( $@ ) {
    	    carp $@;
	    return undef;
	}
    }
    return $data;
}


sub dump_header {
    my ( $data ) = @_;
    print "archname: " . $data->{pconfig}->{archname} . "\n";
    print "revision: " . $data->{pconfig}->{revision} . "\n";
    #print Dumper( $data );
}

		
my $mtimes = {};
foreach my $fp ( glob('parrot-smoke-*.yaml') ) {
    my $st = stat $fp;
    $mtimes->{ $st->mtime } = $fp;
} 

my $last_fn;
my $loaded_revs = {};
my $num = 0;
foreach my $mtime ( sort keys %$mtimes ) {
    $num++;
    my $fn = $mtimes->{$mtime};
    my @lt = localtime($mtime);
    my $time = sprintf("%04d-%02d-%02d %02d-%02d-%02d",($lt[5] + 1900),($lt[4] + 1),$lt[3],$lt[2], $lt[1], $lt[0]  );
    print "file: $fn\n";
    print "mtime: $time\n";
    $last_fn = $fn;

    my $data = load_data($fn);
    if ( defined $data ) {
        dump_header( $data );
	my $rev = $data->{pconfig}->{revision};
	my $arch = $data->{pconfig}->{archname};
	if ( defined $rev && defined $arch ) {
    	    $loaded_revs->{$rev} = {} unless exists $loaded_revs->{$rev};
	    if ( exists $loaded_revs->{$rev}->{$arch} ) {
		$loaded_revs->{$rev}->{$arch}++;
	    } 
	    else {
		$loaded_revs->{$rev}->{$arch} = 1;
	    }
	    #print Dumper($loaded_revs);
	} else {
	    print "Results file error. No archname or revisions in pconfig.\n";
	}
    }
    print "\n\n";
    last if $num >= 3 && $debug;
}
print "\n";


my $arch_stat = {};
foreach my $rev ( sort keys %$loaded_revs ) {
    print "$rev: ";
    my $archs = $loaded_revs->{$rev};
    my $arch_num = 0;
    foreach my $arch ( sort keys %$archs ) {
	$arch_num++;
	print ", " if $arch_num > 1;
	print $arch;
	print "(".$archs->{$arch}.")" if $archs->{$arch} > 1;
	$arch_stat->{$arch} = 0 unless exists $arch_stat->{$arch};
	$arch_stat->{$arch}++;
    }
    print "\n";
}
print "\n";

foreach my $arch ( sort keys %$arch_stat ) {
  print "$arch : " . $arch_stat->{$arch} . "\n";
}

