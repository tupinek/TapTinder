package DBIx::Class::CWebMagic;

use strict;
use warnings;
our $VERSION = '0.02';

BEGIN {
    use base qw/DBIx::Class::Row Class::Accessor::Grouped/;
    use Carp qw/croak/;

    __PACKAGE__->mk_group_accessors('inherited' => qw/
        cwm_col_title
        cwm_col_descr
        cwm_col_type
        cwm_col_auth
    /);
};


=head1 NAME

DBIx::Class::CWebMagic

=head1 SYNOPSIS

  package MyPoject::DB::Schema::person;
  use base 'DBIx::Class';
  use strict;
  use warnings;

  __PACKAGE__->load_components(qw/Core CWebMagic/);
  __PACKAGE__->table('person');

  __PACKAGE__->add_columns(
    'person_id' => {
        ...
    'first_name' => {
        ...
    'last_name' => {
        ...
    'passwd' => {
        ...
    ...

  __PACKAGE__->cwm_col_type( { 'person_id' => 'S', 'first_name' => 'G',  }  );


=head1 DESCRIPTION

Store database schema metadata for CWebMagic application interface.

=head1 SEE ALSO

L<DBIx::Class>, L<CatalystX::Controller::CWebMagic>

=head1 AUTHOR

Michal Jurosz <mj@mj41.cz>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
