package DBIx::Class::CWebMagic;

# ABSTRACT: DBIx::Class extension for CwebMagfic (See Web Magic module).

use strict;
use warnings;

BEGIN {
    use base qw/DBIx::Class::Row Class::Accessor::Grouped/;
    use Carp qw/croak/;

    __PACKAGE__->mk_group_accessors('inherited' => qw/
        cwm_conf
    /);
};

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
    ...

  __PACKAGE__->cwm_conf( {
      auth => {
          my_password => 'R',
      },
      col_types => {
          person_id => 'G', # general ... show everywhere
          first_name => 'S', # secondary ... show inside primary table
      },
      deep => 4,
      skip_tables => [ qw/ user_history user_log / ],
  } );


=head1 DESCRIPTION

Store database schema metadata for CWebMagic application interface.

=head1 SEE ALSO

L<DBIx::Class>, L<CatalystX::Controller::CWebMagic>

=cut

1;
