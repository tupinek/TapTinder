package TapTinder::Web::Check::Path;

# ABSTRACT: TapTinder::Web checks for directories and files.

use strict;
use warnings;


=method uploadtmp_exists

Check if exists uploadtmp dir and that is writable.

=cut

sub uploadtmp_exists {
    my ( $upload_path ) = @_;

    my $status = {
        info => {
            text => 'upload temp directory',
        },
        admin_info => {
            path => $upload_path,
        },
        checks => [],
    };


    # created
    my $exists = ( -d $upload_path ) ? 1 : 0;
    push @{ $status->{checks} }, {
        name => 'exists',
        info => 'upload directory exists',
        ok => $exists,
    };

    # writable
    if ( $exists ) {
        my ( $fh, $filename );
        eval {
            ( $fh, $filename ) = File::Temp::tempfile( DIR => $upload_path, CLEANUP => 1 );
            print $fh "test content\n";
            close $fh;
        };

        my $info = {
            name => 'writable',
            info => 'directory is writable',
        };

        if ( my $err = $@ ) {
            $info->{ok} = 0;
            $info->{admin_info} = {
                err_msg => $err,
                filename => $filename,
            };
        } else {
            $info->{ok} = 1;
        }
        push @{ $status->{checks} }, $info;
    }

    return $status;
}

=head1 SEE ALSO

L<TapTinder::Web::Controller::API1::Check>, L<TapTinder::Web>.

=cut


1;