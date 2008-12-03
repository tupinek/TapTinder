package DBIx::Class::ViewMD;

use strict;
use warnings;
our $VERSION = '0.004';

BEGIN {
    use base qw/DBIx::Class::Row Class::Accessor::Grouped/;
    use Carp qw/croak/;

    __PACKAGE__->mk_group_accessors('inherited' => qw/
        titles
        restricted_cols
        cols_in_table_view
        cols_in_foreign_tables
        cols_in_foreign_tables_sub
    /);
};


=head1 NAME

DBIx::Class::ViewMD

=head1 SYNOPSIS

  package TapTinder::DB::Schema::person;
  use base 'DBIx::Class';
  use strict;
  use warnings;

  __PACKAGE__->load_components(qw/Core ViewMD/);
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

  __PACKAGE__->titles( [ 'ID', 'Person first name', 'Person password', ... ] );
  __PACKAGE__->restricted_cols( { 'passwd' => 1, } );
  __PACKAGE__->cols_in_foreign_tables( [ qw/first_name last_name/  );


=head1 DESCRIPTION

Store database schema metadata for web application interface.

=head1 SEE ALSO

L<DBIx::Class>, L<CatalystX::Controller::TableBrowser>

=head1 AUTHOR

Michal Jurosz <mj@mj41.cz>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
