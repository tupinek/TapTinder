package TapTinder::DB::Show;

use strict;
use warnings;

use base qw(TapTinder::DB);

use Carp qw(carp croak verbose);
use FindBin qw($RealBin);
use Digest::MD5 qw(md5);

use DBI;

use Data::Dumper;
use Devel::StackTrace;


sub get_all_trun {
    my $self = shift;
    
}

1;