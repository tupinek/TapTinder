package TapTinder::Client::RepManager;

use strict;
use warnings;
use Carp qw(carp croak verbose);

our $VERSION = '0.10';

use File::Spec::Functions;
use File::Copy::Recursive qw(dircopy);
use File::Path;
use File::Copy;

use Watchdog qw(sys sys_for_watchdog);
use SVNShell qw(svnversion svnup svndiff);


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

    croak "Directory '$dir' not found.\n" unless -d $dir;

    my $self  = {};
    $self->{dir} = $dir;

    $debug = 0 unless defined $debug;
    $self->{debug} = $debug;

    # TODO - separate by PID, many clients
    $self->{watchdog_dir} = $self->{dir};

    bless ($self, $class);
    return $self;
}


=head2 get_dir_path

Return dir_path for $rp_dir_base_name and $suffix.

=cut

sub get_dir_path {
    my ( $self, $rp_dir_base_name, $suffix ) = @_;

    my $rp_dir_name = $rp_dir_base_name . '-' . $suffix;
    my $dir_path = catdir( $self->{dir}, $rp_dir_name );
    return $dir_path;
}


=head2 prepare_rep_path_dirs

Will create all rep_path dirs if needed.

=cut

sub prepare_rep_path_dirs {
    my ( $self, $rp_dir_base_name ) = @_;

    my @suffixes = ( 'src', 'temp', 'results' );
    foreach my $suffix ( @suffixes ) {
        my $dir_path = $self->get_dir_path( $rp_dir_base_name, $suffix );
        unless ( -d $dir_path ) {
            mkdir( $dir_path ) or croak "Can't create directory '$dir_path':\n  " . $!;
        }
    }

    return 1;
}


=head2 get_rp_dir_base_name

Returns filesystem valid directory base name for $rep_name, $rep_path_path combination.

=cut

sub get_rp_dir_base_name {
    my ( $self, $rep_name, $rep_path_path ) = @_;

    my $fs_valid_rep_name = $rep_name;
    $fs_valid_rep_name =~ s{[^a-zA-Z0-9\-]}{}g;
    $fs_valid_rep_name =~ s{^\-+}{};

    my $fs_valid_rep_path_path = $rep_path_path;
    $fs_valid_rep_path_path =~ s{[^a-zA-Z0-9\-_]}{}g;

    return $fs_valid_rep_name . '-' . $fs_valid_rep_path_path;
}


=head2 dir_is_empty

Return 1 if directory is empty.

=cut

sub dir_is_empty {
    my ( $self, $src_dir_path ) = @_;

    my $dir_handle;
    opendir( $dir_handle, $src_dir_path ) or croak "Cannot open the directory '$src_dir_path': $!";
    my @files = grep {$_ ne '.' and $_ ne '..'} readdir( $dir_handle );
    closedir( $dir_handle ) or croak "Cannot close the directory '$src_dir_path': $!";

    # dir is not empty, svn co not needed
    return 0 if @files;
    return 1;
}


=head2 run_svn_co

Will run svn co command.

=cut

sub run_svn_co {
    my ( $self, $rep_full_path, $src_dir_path, $cmd_output_dir_path, $rev_num ) = @_;

    my $cmd = 'svn co';
    $cmd .= " -r $rev_num" if defined $rev_num;
    $cmd .= ' "' . $rep_full_path . '" "' . $src_dir_path . '"';

    my $cmd_output_file_path = catfile( $cmd_output_dir_path. 'svn_co.txt' );
    my ( $cmd_rc, $out ) = sys_for_watchdog(
        $cmd,
        $cmd_output_file_path,
        10*60,
        undef,
        $self->{watchdog_dir}
    );
    if ( $cmd_rc ) {
        # TODO
        carp "svn co failed, return code: $cmd_rc\n";
        carp "svn co output: '$out'\n";
        croak;
        return 0;
    }

    return 1;
}


=head2 prepare_temp_copy

Prepare temp direcotry with local copy of repository revision.

Required keys and example values:
'rep_name' => 'tr1',
'rep_path' => 'http://dev.taptinder.org/svn/taptinder-tr1/',
'rep_path_path' => 'trunk/',
'rev_num' => '6'

=cut

sub prepare_temp_copy {
    my ( $self, $rr_info ) = @_;

    # use Data::Dumper; print Dumper( $rr_info ); exit;
    my $rp_dir_base_name = $self->get_rp_dir_base_name(
        $rr_info->{rep_name}, $rr_info->{rep_path_path}
    );
    $self->prepare_rep_path_dirs( $rp_dir_base_name );

    my $src_dir_path = $self->get_dir_path( $rp_dir_base_name, 'src' );

    my $svn_co_needed = $self->dir_is_empty( $src_dir_path );
    if ( $svn_co_needed ) {
        my $cmd_output_dir_path = $self->get_dir_path( $rp_dir_base_name, 'results' );
        my $rep_full_path = $rr_info->{rep_path} . $rr_info->{rep_path_path};
        return $self->run_svn_co( $rep_full_path, $src_dir_path, $cmd_output_dir_path, $rr_info->{rev_num} );
    }

    return 1;
}


1;
