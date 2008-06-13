package DBIx::Dumper;

use strict;
use warnings;
our $VERSION = '0.001';

our @EXPORT_OK = qw/dump_row Dumper/;

use Data::Dumper;

=head1 NAME

DBIx::Dumper

=head1 SYNOPSIS

  use DBIx::Dumper qw/Dumper dump_row/;

  my $rs = ...;
  while ( $row = $rs->next ) {
    print dump_row( $row );
  }

=head1 DESCRIPTION

Dump DBIx::Class::ResultSet data.

=cut


sub dump_row {
    my ( $row, $prefix ) = @_;
    $prefix = '' unless defined $prefix;
    my $ot = '';

    #$ot .= Dumper($row) . ', ';
    my %cols = ( $row->get_columns );
    my $num = 0;
    foreach ( sort keys %cols ) {
        my $val = $cols{$_};
        ( $val ) ? ( $val =~ s{\n}{\\n}g ) : ( $val = '' );
        $ot .= $prefix . $_ . ": " . $val . "\n";
        $num++;
    }
    # TODO, has_column_loaded ?
    if ( 0 ) {
        my %icols = ( $row->get_inflated_columns );
        my $num = 0;
        while ( my ($k,$v) = each(%icols) ) {
            next unless ref $v;
            $ot .= $prefix . $k . " ->\n";
            $ot .= dump_row( $v, $prefix.'   ' );
            $num++;
        }
        $ot .= "\n";
    }

    return $ot;
}


=head1 SEE ALSO

L<DBIx::Class>

=head1 AUTHOR

Michal Jurosz <mj@mj41.cz>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
