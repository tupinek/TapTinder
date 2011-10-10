package TapTinder::DB::DBIxClassBase;

# ABSTRACT: TapTinder::DB base class.

use base qw/DBIx::Class/;
__PACKAGE__->load_components(qw/CWebMagic Core/);

1;
