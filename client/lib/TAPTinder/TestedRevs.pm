package TAPTinder::TestedRevs;

use strict;
use warnings;

use base 'Exporter';
our $VERSION = 0.01;
our @EXPORT = qw(get_tested_revisions get_revision_to_test revision_test_done unlink_state_file);

use YAML qw(LoadFile DumpFile);
use File::Spec::Functions;

sub _get_revisions_state_fname {
    my ( $project_name ) = @_;
    my $fn = 'client-revs-'.$project_name.'.yaml';
    return catfile( '..', 'client-conf', $fn );
}

sub get_tested_revisions {
    my ( $project_name, $fname ) = @_;

    $fname = _get_revisions_state_fname($project_name) unless defined $fname;
    return {} unless -e $fname;

    my ( $hashref, $arrayref, $string ) = LoadFile( $fname );
    return $hashref;
}


=item C<get_revision_to_test($project_name, $actual_rev)>

Searches tested revision numberes and return new revision number to test.

Parameter $actual_rev is your project revison number and is used when no bigger
revision number found.

=cut


sub get_revision_to_test {
    my ( $project_name, $actual_rev ) = @_;
    
    my $tested_revs = get_tested_revisions( $project_name );
    my $num = 0;
    my $max = 0;
    foreach ( keys %$tested_revs ) {
        $num++;
        $max = $_ if $max < $_;
    }
    # $max should be less than $actual_rev if defined
    $max = $actual_rev if defined $actual_rev && $max < $actual_rev;

    if ( $num == 0 ) {
        return undef unless defined $actual_rev;
        return undef if $actual_rev < 1;
        return $actual_rev; 
    }

    my $to_test = $max;
    while ( exists $tested_revs->{$to_test} && $to_test > 0 ) {
        $to_test--;
    }
    return undef if $max - $to_test >= 500;
    return undef if $to_test == 0;
    return $to_test;
}


sub revision_test_done {
    my ( $project_name, $revision ) = @_;
    my $fname = _get_revisions_state_fname( $project_name );
    my $tested_revs = get_tested_revisions( $project_name, $fname );
    $tested_revs->{ $revision } = 1;
    return DumpFile( $fname, $tested_revs );
}


sub unlink_state_file {
    my ( $project_name ) = @_;
    my $fname = _get_revisions_state_fname( $project_name );
    return unlink( $fname );
}

1;
