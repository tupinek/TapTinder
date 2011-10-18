package TapTinder::Web::Check::DB;

# ABSTRACT: TapTinder::Web checks for database status and schema state.

use strict;
use warnings;


=method connected

Check connect to database and run try to simple select statement.

=cut

sub connected {
    my ( $db_conf, $some_table_model ) = @_;

    my $status = {
        info => {
            text => 'database',
        },
        admin_info => {
            conf => {
                name => $db_conf->{name},
                user => $db_conf->{user},
                dbi_dsn => $db_conf->{dbi_dsn},
            },
        },
        checks => [],
    };

    my $info = {
        name => 'connected',
        info => 'can read some data from table',
    };
    eval {
        my $rs = $some_table_model->search();
        my $connected = ( defined $rs && $rs->next ) ? 1 : 0;
    };
    if ( my $err = $@ ) {
        $info->{ok} = 0;
        $info->{admin_info} = {
            err_msg => $err,
        };
    } else {
        $info->{ok} = 1;
    }
    push @{ $status->{checks} }, $info;

    return $status;
}


=head1 SEE ALSO

L<TapTinder::Web::Controller::API1::Check>, L<TapTinder::Web>.

=cut


1;