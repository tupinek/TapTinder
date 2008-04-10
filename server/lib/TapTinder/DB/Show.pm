package TapTinder::DB::Show;

use strict;
use warnings;

use base qw(TapTinder::DB);

use Carp qw(carp croak verbose);
use FindBin qw($RealBin);
use Digest::MD5 qw(md5);

use DBI;

use Data::Dumper;
use Devel::StackTrace;


sub db_error {
    my ( $self, $msg ) = @_;
    
    my $html = '';
    $html .= $msg if $msg;
    $html .= $self->{dbh}->errstr;
    $html .= "\n\n" . $self->trc();
    croak $html;
}



# $trun_id
sub get_trun_rev_num {
    my $self = shift;

    my $sth = $self->{dbh}->prepare_cached(qq{
        select rev.rev_num
          from trun, rev
         where trun.trun_id = ?
           and rev.rev_id = trun.rev_id
    });
    $self->db_error() if $self->{dbh}->err;

    my $result = $self->{dbh}->selectrow_hashref( $sth, {}, @_ );
    $self->db_error() if $self->{dbh}->err;

    print $self->dump_get( (caller(0))[3], \@_, $result ) if $self->{debug};
    return $result->{rev_num};
}


1;
