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
use TapTinder::Client::KeyPress qw(process_keypress sleep_and_process_keypress);
use SVN::PropBug qw(diff_contains_real_change);
$SVN::PropBug::ver = 0;

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
    my ( $class, $dir, $ver, $debug ) = @_;

    croak "Directory '$dir' not found.\n" unless -d $dir;

    my $self  = {};
    $self->{dir} = $dir;

    $ver = 2 unless defined $ver;
    $debug = 0 unless defined $debug;
    $self->{ver} = $ver;
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

    my $rp_dir_base_name = $fs_valid_rep_name;
    $rp_dir_base_name .= '-' . $fs_valid_rep_path_path unless $fs_valid_rep_path_path;
    return $rp_dir_base_name;
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

Will run svn checkout command.

=cut

sub run_svn_co {
    my ( $self, $rep_full_path, $src_dir_path, $cmd_output_dir_path, $rev_num ) = @_;

    my $cmd = 'svn co';
    $cmd .= " -r $rev_num" if defined $rev_num;
    $cmd .= ' "' . $rep_full_path . '" "' . $src_dir_path . '"';

    my $cmd_output_file_path = catfile( $cmd_output_dir_path, 'svn_co.txt' );
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
        return 0; # not needed
    }

    return 1;
}


=head2 run_svn_up

Will run svn update command.

=cut

sub run_svn_up {
    my ( $self, $src_dir_path, $cmd_output_dir_path, $rev_num ) = @_;

    my $to_rev_str = $rev_num;
    my ( $up_ok, $o_log, $tmp_new_rev ) = svnup(
        $src_dir_path,
        $to_rev_str
    );

    # TODO
    unless ( $up_ok ) {
        croak $o_log;
    }

    return $up_ok;
}


=head2 remove_dir_loop

Will try to recursive remove directory. Will sleep for 5 seconds if directory can't be removed and then try
to remove it again.

=cut


sub remove_dir_loop {
    my ( $self, $dir_path ) = @_;

    print "Removing dir '$dir_path' ...\n" if $self->{ver} >= 2;
    if ( -d $dir_path ) {
        rmtree( $dir_path ) or croak $!;
        while ( -d $dir_path ) {
            print "Remove temp dir '$dir_path' failed.\n" if $self->{ver} >= 2;
            my $wait_time = 5;
            print "Waiting for ${wait_time}s.\n" if $self->{ver} >= 2;
            sleep_and_process_keypress( $wait_time );
            rmtree( $dir_path ) or croak $!;
        }
        print "Dir '$dir_path' removed.\n" if $self->{ver} >= 2;
    } else {
        print "Dir '$dir_path' not found.\n" if $self->{ver} >= 2;
    }
    return 1;
}


=head2 prepare_temp_from_src

Create temp_dir as copy of src_dir.

=cut

sub prepare_temp_from_src {
    my ( $self, $temp_dir_path, $src_dir_path ) = @_;

    $self->remove_dir_loop( $temp_dir_path );
    mkdir( $temp_dir_path ) or croak "Can't mkdir '$temp_dir_path':\n  $!";
    process_keypress();

    print "Copying src '$src_dir_path' to temp '$temp_dir_path' ...\n" if $self->{ver} >= 2;
    dircopy( $src_dir_path, $temp_dir_path ) or croak "Can't copy dir '$src_dir_path' to '$temp_dir_path' $!";
    print "Copy src dir to temp dir done.\n" if $self->{ver} >= 3;

    return 1;
}


=head2 check_not_modified

Check if directory is in clean (not modified) state.

=cut

sub check_not_modified {
    my ( $self, $dir_path, $bypase_svnbug ) = @_;

    my ( $o_rev, $o_log ) = svnversion( $dir_path );
    croak "svn svnversion failed: $o_log" unless defined $o_rev;
    print "Revision number of dir '$dir_path': $o_rev\n" if $self->{ver} >= 4;
    if ( $o_rev =~ /^(\d+)$/ ) {
        return 1;

    } elsif ( !$bypase_svnbug || $o_rev !~ /^(\d+)M$/ ) {
        carp "Bad revision number '$o_rev' on '$dir_path'. Run cleanup dir.\n";
        return 0;
    }

    # bypass Subversion bug, see [perl #49788]
    my ( $diff, $err ) = svndiff( $dir_path );
    croak "SVN diff error on dir '$dir_path': $err\n" unless defined $diff;

    my $is_real_modification = diff_contains_real_change( $diff );
    unless ( defined $is_real_modification ) {
        croak "SVN::PropBug error on dir '$dir_path': $@.";
    }
    if ( $is_real_modification ) {
        croak "Found modifications in temp directory.\n" . "Diff: $diff\n";
    }
    print "Subversion bug bypassed on '$dir_path'.\n" if $self->{ver} >= 3;
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

    # update or checkout src dir
    my $svn_co_needed = $self->dir_is_empty( $src_dir_path );
    my $results_dir_path = $self->get_dir_path( $rp_dir_base_name, 'results' );
    my $ret_code;
    # checkout
    if ( $svn_co_needed ) {
        my $rep_full_path = $rr_info->{rep_path} . $rr_info->{rep_path_path};
        $ret_code = $self->run_svn_co( $rep_full_path, $src_dir_path, $results_dir_path, $rr_info->{rev_num} );

    # update
    } else {
        $ret_code = $self->run_svn_up( $src_dir_path, $results_dir_path, $rr_info->{rev_num} );
    }
    return undef unless $self->check_not_modified( $src_dir_path, 0 );

    return undef unless $ret_code;
    process_keypress();

    # create temp dir from src dir
    my $temp_dir_path = $self->get_dir_path( $rp_dir_base_name, 'temp' );
    my $prep_rc = $self->prepare_temp_from_src( $temp_dir_path, $src_dir_path );
    return undef unless $prep_rc;
    return undef unless $self->check_not_modified( $temp_dir_path, 1 );

    return {
        results_dir => $results_dir_path,
        temp_dir => $temp_dir_path,
    };
}


=head1 TODO

Full client-data directory managment.
* quotas, cleanup
* ...

=cut

1;
