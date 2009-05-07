#! perl

# SVN::Log v0.03, line 212
# -  my $headrule = qr/r(\d+) \| (\w+) \| (\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})/;
# +  my $headrule = qr/r(\d+) \| (.+?) \| (\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})/;

use strict;
use warnings;
use Carp qw(carp croak verbose);
use FindBin qw($RealBin);
use Data::Dumper;

use lib "$FindBin::Bin/../lib";
use SVN::Log;

my $log = SVN::Log::retrieve({
    'repository' => "https://svn.parrot.org/parrot/",
    'start' => 1907,
    'end' => 1907,
});

print Dumper($log);
exit();
