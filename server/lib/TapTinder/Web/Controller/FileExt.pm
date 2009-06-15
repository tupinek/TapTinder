package TapTinder::Web::Controller::FileExt;

use strict;
use warnings;
use base 'TapTinder::Web::ControllerBase';

use Archive::Tar;
use File::Spec::Functions;

=head1 NAME

TapTinder::Web::Controller::ClientMonitor - Catalyst Controller

=head1 DESCRIPTION

Catalyst controller for TapTinder file extracting.

=head1 METHODS

=head2 index

=cut

sub index : Path  {
    my ( $self, $c, @arg ) = @_;

    my $params = $c->request->params;
    #$self->dumper( $c, $params );
    #$self->dumper( $c, \@arg );


    my $archive_fsfile_id = $params->{id};
    my $ext_file_name = $params->{efn};

    unless ( $archive_fsfile_id =~ /^\d+$/ ) {
        $c->stash->{error} = "Id '$archive_fsfile_id' is not numeric.";
        return;
    }

    my $search_conf = {
        'fsfile_id.deleted' => undef,
    };
    $search_conf->{'me.archive_id'} = $archive_fsfile_id;
    $search_conf->{'me.org_name'} = $ext_file_name;

    my $search_attrs = {
        join => {
            'fsfile_id' => 'fspath_id',
        },
        '+select' => [ 'fspath_id.path', 'fsfile_id.name' ],
        '+as' => [ 'path', 'name' ],
    };

    my $ext_file = $c->model('WebDB::fsfile_ext')->find( $search_conf, $search_attrs );

    my $ext_full_path = undef;
    if ( $ext_file ) {
        my $path = $ext_file->get_column('path');
        my $file_name = $ext_file->get_column('name');
        $ext_full_path = catfile( $path, $file_name );
        #$self->dumper( $c, $ext_full_path );
        #return;

    # Not found. Will try to extract it.
    } else {
        my $arch_search_conf = {
            'me.fsfile_id' => $archive_fsfile_id,
            'me.deleted' => undef,
        };
        my $arch_search_attrs = {
            join => [ 'fspath_id', ],
            '+select' => [ 'fspath_id.path' ],
            '+as' => [ 'path' ],
        };
        my $arch_file_row = $c->model('WebDB::fsfile')->find( $arch_search_conf, $arch_search_attrs );
        my %arch_file = $arch_file_row->get_columns;

        my $arch_fpath = catfile( $arch_file{path}, $arch_file{name} );
        #$self->dumper( $c, $arch_fpath );

        unless ( -f $arch_fpath ) {
            $c->stash->{error} = "Can't find '$arch_fpath'.";
            return;
        }

        my $tar = Archive::Tar->new;
        $tar->read($arch_fpath);

        my $selected_fspath = $self->get_fspath_select_row(
            $c,
            4, # $fsfile_type_id - extracted files
            undef # $rep_path_id
        );
        if ( !$selected_fspath ) {
            $c->stash->{error} = "Error: Can't select path for 'extracted file' type.";
            return;
        }

        # ToDo transaction
        my $created = DateTime->now;
        my $fsfile_rs = $c->model('WebDB::fsfile')->create({
            fspath_id   => $selected_fspath->{fspath_id},
            name        => '',
            size        => 0,
            created     => $created,
            deleted     => undef,
        });
        unless ( $fsfile_rs ) {
            $c->stash->{error} = "Error: Create fsfile entry failed.";
            return 0;
        }
        my $fsfile_id = $fsfile_rs->get_column('fsfile_id');

        my ( $ext_extension ) = $ext_file_name =~ /(\..*?)$/;
        my $new_ext_file_name = $fsfile_id . $ext_extension;
        $ext_full_path = catfile( $selected_fspath->{path}, $new_ext_file_name );

        $tar->extract_file( $ext_file_name, $ext_full_path );
        #$self->dumper( $c, $tar->error() );
        #$self->dumper( $c, $ext_full_path );

        my $size = -s $ext_full_path;
        $fsfile_rs->update({
            name => $new_ext_file_name,
            size => $size,
        });

        my $fsfile_ext_rs = $c->model('WebDB::fsfile_ext')->create({
            archive_id  => $archive_fsfile_id,
            org_name    => $ext_file_name,
            fsfile_id   => $fsfile_id,
        });
        unless ( $fsfile_ext_rs ) {
            $c->stash->{error} = "Error: Create fsfile_ext_rs entry failed.";
            return 0;
        }
    }

    $c->serve_static_file( $ext_full_path );
    return undef;
}


=head1 SEE ALSO

L<TapTinder::Web>, L<Catalyst::Controller>

=head1 AUTHOR

Michal Jurosz <mj@mj41.cz>

=head1 LICENSE

This file is part of TapTinder. See L<TapTinder> license.

=cut


1;
