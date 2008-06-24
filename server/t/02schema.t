use strict;
use warnings;
use Test::More tests => 2;

use YAML::Syck qw/LoadFile/;

use lib 'lib';
use TapTinder::DB::SchemaAdd;

my $fpath = './conf/web_db.yml';
my $conf = LoadFile($fpath);

my %dbi_params = ();
my $schema = TapTinder::DB::Schema->connect(
    $conf->{db}->{dbi_dsn},
    $conf->{db}->{user},
    $conf->{db}->{pass},
    \%dbi_params
);

ok ( $schema, 'Connect should succeed' );

#export DBIC_TRACE=1
#use Data::Dumper; print Dumper( $schema );
# dbix-class bug test
my $rs = $schema->resultset('build')->search( {}, { join => 'rep_path_id' } );

ok( $rs->count, 'rs->count on build should succeed' );
