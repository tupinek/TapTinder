package TapTinder::Client::RepManager;

use strict;
use warnings;
use Carp qw(carp croak verbose);

our $VERSION = '0.10';

use File::Copy::Recursive qw(dircopy);
use File::Path;
use File::Copy;


=head1 NAME

TapTinder::Client::RepManager - TapTinder client manager of repositories local copies

=head1 SYNOPSIS

See L<TapTinder::Client>

=head1 DESCRIPTION

TapTinder client ...

=head2 new

Create RepManager object.

=cut

sub new {
    my ( $class, $dir, $debug ) = @_;

    my $self  = {};
    $self->{dir} = $dir;

    $debug = 0 unless defined $debug;
    $self->{debug} = $debug;

    bless ($self, $class);
    return $self;
}


=head2 prepare_temp_copy

Prepare temp direcotry with local copy of repository revision.

=cut

sub prepare_temp_copy {
    my ( $self, $rep_rev_info ) = @_;

    return 1;
}


1;
