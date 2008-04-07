package TapTin::DB;

use strict;
use warnings;

use Carp qw(carp croak verbose);
use FindBin qw($RealBin);
use Digest::MD5 qw(md5);

use DBI;

use Data::Dumper;
use Devel::StackTrace;


sub new {
    my $class = shift;
    my $self  = {};

    $self->{dbh} = undef;
    $self->{_cache} = {};   # sth_cache;
    $self->{debug} = 0;

    bless ($self, $class);
    return $self;
}


sub connect {
    my ( $self, $conf, $params ) = @_;
    
    $params = {
        RaiseError => 0, 
        AutoCommit => 0,
    } unless defined $params;
    
    return $self->{dbh} = DBI->connect(
        $conf->{dsn},
        $conf->{user},
        $conf->{password},
        $params
    ) or croak $DBI::errstr;
}


sub debug {
    my $self = shift;
    if (@_) { $self->{debug} = shift }
    return $self->{debug};
}
    
    
sub errstr {
    my $self = shift;
    return $self->{dbh}->errstr;
}


sub commit {
    my $self = shift;
    return $self->{dbh}->commit;
}


sub rollback {
    my $self = shift;
    return $self->{dbh}->rollback;
}

sub disconnect {
    my $self = shift;
    return $self->{dbh}->disconnect;
}


# TODO move to DB:Debug class
sub dmp {
    my $dd = Data::Dumper->new( [ @_ ] );
    $dd->Indent(1);
    $dd->Terse(1);
    $dd->Purity(1);
    $dd->Deepcopy(1);
    $dd->Deparse(1);
    return $dd->Dump;
}

sub dump_get {
    my ( $self, $sub_name, $ra_args, $results ) = @_;
    return "function $sub_name, input (" . join(', ',@$ra_args) . "), result " . $self->dmp($results);
}

sub trc {
    my $trace = Devel::StackTrace->new;
    return $trace->as_string;
}



sub log_rev_error {
    my ( $self, $rd, $msg ) = @_;
    
    $self->{dbh}->rollback;
    $self->{dbh}->disconnect;
    if ( defined $rd ) {
        croak 
            $msg
            . "\n"
            . "For revision " . $rd->{revision} . ".\n"
            . dmp( $rd ) ."\n"
        ;
    }
}

sub db_error {
    my ( $self, $msg ) = @_;
    
    $self->{dbh}->rollback;
    $self->{dbh}->disconnect;
    $msg = '' unless defined $msg;
    $msg .= $self->{dbh}->errstr;
    $msg .= "\n\n" . trc();
    croak $msg;
}


# repository $path
sub get_rep_id {
    my $cname = (caller(0))[3];
    my $self = shift;

    unless ( defined $self->{_cache}->{$cname} ) {
        $self->{_cache}->{$cname} = $self->{dbh}->prepare(qq{
            select rep_id
              from rep
             where rep.path = ? 
               and rep.active = 1
        }) or croak $self->{dbh}->errstr;
    }
    my $result = $self->{dbh}->selectrow_hashref( $self->{_cache}->{$cname}, {}, @_ );
    $self->db_error() if $self->{_cache}->{$cname}->err;
    print $self->dump_get( $cname, \@_, $result ) if $self->{debug};
    return $result->{rep_id};
}


# $rep_id
sub get_rep_users {
    my $cname = (caller(0))[3];
    my $self = shift;

    unless ( defined $self->{_cache}->{$cname} ) {
        $self->{_cache}->{$cname} = $self->{dbh}->prepare(qq{
            select user_rep_id,
                   rep_login
              from user_rep
             where rep_id = ?
        }) or croak $self->{dbh}->errstr;
    }
    $self->{_cache}->{$cname}->execute( @_ );
    my $result = $self->{_cache}->{$cname}->fetchall_hashref( 'rep_login' );
    $self->db_error() if $self->{_cache}->{$cname}->err;
    print $self->dump_get( $cname, \@_, $result ) if $self->{debug};
    return $result;
}

# $rep_id, $rep_login (null)
sub get_rep_user_id {
    my $cname = (caller(0))[3];
    my $self = shift;

    unless ( defined $self->{_cache}->{$cname} ) {
        $self->{_cache}->{$cname} = $self->{dbh}->prepare(qq{
            select user_rep_id
              from user_rep
             where rep_id = ?
               and rep_login = ? OR (rep_login IS NULL AND ? = 1)
        }) or croak $self->{dbh}->errstr;
    }
    my $result = $self->{dbh}->selectrow_hashref(
        $self->{_cache}->{$cname}, {},
        $_[0], $_[1], defined($_[1]) ? 0 : 1
    );
    $self->db_error() if $self->{_cache}->{$cname}->err;
    print $self->dump_get( $cname, \@_, $result ) if $self->{debug};
    return $result->{user_rep_id};
}

# $rep_id, $rep_login
sub insert_rep_user {
    my $cname = (caller(0))[3];
    my $self = shift;

    unless ( defined $self->{_cache}->{$cname} ) {
        $self->{_cache}->{$cname} = $self->{dbh}->prepare(qq{
            insert into user_rep ( rep_id, rep_login ) values ( ?, ? )
        }) or croak $self->{dbh}->errstr;
    }
    $self->{_cache}->{$cname}->execute( @_ );
    $self->db_error() if $self->{_cache}->{$cname}->err;
    #my $result = $self->{dbh}->last_insert_id( undef, undef, undef, undef);
    my $result = $self->get_rep_user_id( $_[0], $_[1] );
    print $self->dump_get( $cname, \@_, $result ) if $self->{debug};
    return $result;
}


# $rep_id, $rep_path
sub get_rep_path_id {
    my $cname = (caller(0))[3];
    my $self = shift;

    unless ( defined $self->{_cache}->{$cname} ) {
        $self->{_cache}->{$cname} = $self->{dbh}->prepare(qq{
            select rep_path_id
              from rep_path
             where rep_id = ?
               and path = ?
        }) or croak $self->{dbh}->errstr;
    }
    my $result = $self->{dbh}->selectrow_hashref( $self->{_cache}->{$cname}, {}, @_ );
    $self->db_error() if $self->{_cache}->{$cname}->err;
    print $self->dump_get( $cname, \@_, $result ) if $self->{debug};
    return $result->{rep_path_id};
}

# $rep_id, $rep_path, $base_rev_id
sub insert_rep_path {
    my $cname = (caller(0))[3];
    my $self = shift;

    unless ( defined $self->{_cache}->{$cname} ) {
        $self->{_cache}->{$cname} = $self->{dbh}->prepare(qq{
            insert into rep_path ( rep_id, path ) values ( ?, ? )
        }) or croak $self->{dbh}->errstr;
    }
    $self->{_cache}->{$cname}->execute( @_ );
    $self->db_error() if $self->{_cache}->{$cname}->err;
    my $result = $self->get_rep_path_id( $_[0], $_[1] );
    print $self->dump_get( $cname, \@_, $result ) if $self->{debug};
    return $result;
}


# $rev_id, $rep_path_id
sub exists_rev_rep_path {
    my $cname = (caller(0))[3];
    my $self = shift;

    unless ( defined $self->{_cache}->{$cname} ) {
        $self->{_cache}->{$cname} = $self->{dbh}->prepare(qq{
            select 1 as found
              from rev_rep_path
             where rev_id = ?
               and rep_path_id = ?
        }) or croak $self->{dbh}->errstr;
    }
    my $result = $self->{dbh}->selectrow_hashref( $self->{_cache}->{$cname}, {}, @_ );
    $self->db_error() if $self->{_cache}->{$cname}->err;
    print $self->dump_get( $cname, \@_, $result ) if $self->{debug};
    return $result->{found};
}


# $rev_id, $rep_path_id
sub insert_rev_rep_path {
    my $cname = (caller(0))[3];
    my $self = shift;

    unless ( defined $self->{_cache}->{$cname} ) {
        $self->{_cache}->{$cname} = $self->{dbh}->prepare(qq{
            insert into rev_rep_path ( rev_id, rep_path_id ) values ( ?, ? )
        }) or croak $self->{dbh}->errstr;
    }
    $self->{_cache}->{$cname}->execute( @_ );
    $self->db_error() if $self->{_cache}->{$cname}->err;
    my $result = $self->get_rep_path_id( $_[0], $_[1] );
    print $self->dump_get( $cname, \@_, $result ) if $self->{debug};
    return $result;
}




# $rep_id, $rev_num
sub get_rev_id {
    my $cname = (caller(0))[3];
    my $self = shift;

    unless ( defined $self->{_cache}->{$cname} ) {
        $self->{_cache}->{$cname} = $self->{dbh}->prepare(qq{
            select rev_id
              from rev
             where rep_id = ?
               and rev_num = ?
        }) or croak $self->{dbh}->errstr;
    }
    my $result = $self->{dbh}->selectrow_hashref( 
        $self->{_cache}->{$cname},
        {},
        @_
    );
    $self->db_error() if $self->{_cache}->{$cname}->err;
    print $self->dump_get( $cname, \@_, $result ) if $self->{debug};
    return $result->{rev_id};
}

# $rep_id
sub get_max_rev_num {
    my $cname = (caller(0))[3];
    my $self = shift;

    unless ( defined $self->{_cache}->{$cname} ) {
        $self->{_cache}->{$cname} = $self->{dbh}->prepare(qq{
            select MAX(rev_num) as max_rev_num
              from rev
             where rep_id = ?
        }) or croak $self->{dbh}->errstr;
    }
    my $result = $self->{dbh}->selectrow_hashref( $self->{_cache}->{$cname}, {}, @_ );
    $self->db_error() if $self->{_cache}->{$cname}->err;
    print $self->dump_get( $cname, \@_, $result ) if $self->{debug};
    return $result->{max_rev_num};
}

# $rep_id
sub get_number_of_revs {
    my $cname = (caller(0))[3];
    my $self = shift;

    unless ( defined $self->{_cache}->{$cname} ) {
        $self->{_cache}->{$cname} = $self->{dbh}->prepare(qq{
            select count(1) as number_of_revs
              from rev
             where rep_id = ?
        }) or croak $self->{dbh}->errstr;
    }
    my $result = $self->{dbh}->selectrow_hashref( $self->{_cache}->{$cname}, {}, @_ );
    $self->db_error() if $self->{_cache}->{$cname}->err;
    print $self->dump_get( $cname, \@_, $result ) if $self->{debug};
    return $result->{number_of_revs};
}

# $rep_id, $rev_num, $date, $rep_user_id (author_id), $msg
sub insert_rev {
    my $cname = (caller(0))[3];
    my $self = shift;

    unless ( defined $self->{_cache}->{$cname} ) {
        $self->{_cache}->{$cname} = $self->{dbh}->prepare(qq{
            insert into rev ( rep_id, rev_num, author_id, date, msg ) values ( ?, ?, ?, ?, ? )
        }) or croak $self->{dbh}->errstr;
    }
    $self->{_cache}->{$cname}->execute( @_ );
    $self->db_error() if $self->{_cache}->{$cname}->err;
    my $result = $self->get_rev_id( $_[0], $_[1] );
    print $self->dump_get( $cname, \@_, $result ) if $self->{debug};
    return $result;
}


# $sub_path, $rep_path_id, $revision
sub get_rep_file_id {
    my $cname = (caller(0))[3];
    my $self = shift;

    my ( $sub_path, $rep_path_id, $revision ) = @_;
    unless ( defined $self->{_cache}->{$cname} ) {
        $self->{_cache}->{$cname} = $self->{dbh}->prepare(qq{
            select rep_file_id
              from rep_file
             where rep_path_id = ?
               and sub_path = ?
               and rev_num_from <= ?
               and (rev_num_to IS NULL OR rev_num_to >= ?)
        }) or croak $self->{dbh}->errstr;
    }
    my $result = $self->{dbh}->selectrow_hashref( 
        $self->{_cache}->{$cname},
        {},
        $rep_path_id, $sub_path, $revision, $revision
    );
    $self->db_error() if $self->{_cache}->{$cname}->err;
    print $self->dump_get( $cname, \@_, $result ) if $self->{debug};
    return $result->{rev_file_id};
}

# $sub_path, $rep_path_id, $revision
sub insert_rep_file {
    my $cname = (caller(0))[3];
    my $self = shift;

    unless ( defined $self->{_cache}->{$cname} ) {
        $self->{_cache}->{$cname} = $self->{dbh}->prepare(qq{
            insert into rep_file ( sub_path, rep_path_id, rev_num_from ) values ( ?, ?, ? )
        }) or croak $self->{dbh}->errstr;
    }
    $self->{_cache}->{$cname}->execute( @_ );
    $self->db_error() if $self->{_cache}->{$cname}->err;
    my $result = $self->get_rep_file_id( $_[0], $_[1], $_[2] );
    print $self->dump_get( $cname, \@_, $result ) if $self->{debug};
    return $result;
}


# $sub_path, $rep_path_id, $revision
sub set_rep_file_deleted {
    my $cname = (caller(0))[3];
    my $self = shift;

    my ( $sub_path, $rep_path_id, $revision ) = @_;
    unless ( defined $self->{_cache}->{$cname} ) {
        $self->{_cache}->{$cname} = $self->{dbh}->prepare(qq{
            update rep_file
               set rev_num_to = ?
             where rep_path_id = ?
               and sub_path = ?
               and rev_num_from <= ?
               and rev_num_to is null
        }) or croak $self->{dbh}->errstr;
    }
    $self->{_cache}->{$cname}->execute( 
        $revision, $rep_path_id, $sub_path, $revision
    );
    $self->db_error() if $self->{_cache}->{$cname}->err;
    my $result = $self->get_rep_file_id( $_[0], $_[1], $_[2] );
    print $self->dump_get( $cname, \@_, $result ) if $self->{debug};
    return $result;
}


# TODO
sub set_rep_file_modified {
    my $cname = (caller(0))[3];
    my $self = shift;
    my ( $sub_path, $rep_path_id, $revision ) = @_;
    return 1;
}


sub str_args_md5 {
    my $self = shift;
    my $str = '';
    $str .= $_ foreach @_;
    return md5($str);
}


# $hash
sub get_conf_id {
    my $cname = (caller(0))[3];
    my $self = shift;

    my ( $hash ) = @_;
    unless ( defined $self->{_cache}->{$cname} ) {
        $self->{_cache}->{$cname} = $self->{dbh}->prepare(qq{
            select conf_id
              from conf
             where hash = ?
        }) or croak $self->{dbh}->errstr;
    }
    my $result = $self->{dbh}->selectrow_hashref( 
        $self->{_cache}->{$cname},
        {},
        $hash
    );
    $self->db_error() if $self->{_cache}->{$cname}->err;
    print $self->dump_get( $cname, \@_, $result ) if $self->{debug};
    return $result->{conf_id};
}


# $hash, $cc, $harness_args, $devel, $optimize
sub insert_conf {
    my $cname = (caller(0))[3];
    my $self = shift;

    unless ( defined $self->{_cache}->{$cname} ) {
        $self->{_cache}->{$cname} = $self->{dbh}->prepare(qq{
            insert into conf ( hash, cc, harness_args, devel, `optimize` ) values ( ?, ?, ?, ?, ? )
        }) or croak $self->{dbh}->errstr;
    }
    $self->{_cache}->{$cname}->execute( @_ );
    $self->db_error() if $self->{_cache}->{$cname}->err;
    my $result = $self->get_conf_id( $_[0] );
    print $self->dump_get( $cname, \@_, $result ) if $self->{debug};
    return $result;
}


sub get_or_insert_conf {
    my $self = shift;
    my $hash = $self->str_args_md5( @_ );
    my $conf_id = $self->get_conf_id($hash);
    return $conf_id if defined $conf_id;
    return $self->insert_conf( $hash, @_ );
}


# -
sub get_inserted_trun_id {
    my $cname = (caller(0))[3];
    my $self = shift;


    my $rows = $self->{dbh}->do("select max(trun_id) from trun");
    $self->dmp($rows); exit;
    #return $self->{dbh}->last_insert_id();
}


# $rev_id, $rep_path_id, $client_id, $conf_id
sub insert_trun_base {
    my $cname = (caller(0))[3];
    my $self = shift;

    unless ( defined $self->{_cache}->{$cname} ) {
        $self->{_cache}->{$cname} = $self->{dbh}->prepare(qq{
            insert into trun ( rev_id, rep_path_id, client_id, conf_id ) values ( ?, ?, ?, ? )
        }) or croak $self->{dbh}->errstr;
    }
    $self->{_cache}->{$cname}->execute( @_ );
    my $result = $self->get_inserted_trun_id();
    print $self->dump_get( $cname, \@_, $result ) if $self->{debug};
    $self->db_error() if $self->{_cache}->{$cname}->err;
    return $result;
    
}

1;