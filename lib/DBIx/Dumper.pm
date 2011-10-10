package DBIx::Dumper;

# ABSTRACT: Dump DBIx::Class::ResultSet.

use strict;
use warnings;

our @EXPORT_OK = qw/dump_row/;

use Data::Dumper;


=head1 SYNOPSIS

  use DBIx::Dumper qw/dump_row/;

  my $rs = ...;
  while ( $row = $rs->next ) {
    print dump_row( $row );
  }

=head1 DESCRIPTION

Dump DBIx::Class::ResultSet data.

=method dump_row

Dump DBIx::Class row.

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

=cut

1;
