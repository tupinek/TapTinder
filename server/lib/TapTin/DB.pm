package TapTin::DB;

use strict;
use warnings;

use Carp qw(carp croak verbose);
use FindBin qw($RealBin);

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
    print "function $sub_name, input (" . join(', ',@$ra_args) . "), result " . $self->dmp($results);
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


# $repository, $project_name
sub get_rep_id {
    my $cname = (caller(0))[3];
    my $self = shift;

    unless ( defined $self->{_cache}->{$cname} ) {
        $self->{_cache}->{$cname} = $self->{dbh}->prepare(qq{
            select rep_id
              from rep, project 
             where rep.path = ? 
               and rep.active = 1
               and project.project_id = rep.project_id
               and project.name = ?
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




# $rev_num
sub get_rev_id {
    my $cname = (caller(0))[3];
    my $self = shift;

    unless ( defined $self->{_cache}->{$cname} ) {
        $self->{_cache}->{$cname} = $self->{dbh}->prepare(qq{
            select rev_id
              from rev
             where rev_num = ?
        }) or croak $self->{dbh}->errstr;
    }
    my $result = $self->{dbh}->selectrow_hashref( 
        $self->{_cache}->{$cname},
        {},
        $_[0]
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
            select max(rev.rev_num) as max
              from rep_path, rev_rep_path, rev
             where rep_path.rep_id = ?
               and rev_rep_path.rep_path_id = rep_path.rep_path_id
               and rev.rep_id = rev_rep_path.rev_id
        }) or croak $self->{dbh}->errstr;
    }
    my $result = $self->{dbh}->selectrow_hashref( $self->{_cache}->{$cname}, @_ );
    $self->db_error() if $self->{_cache}->{$cname}->err;
    print $self->dump_get( $cname, \@_, $result ) if $self->{debug};
    return $result->{max};
}

# $rev_num, $date, $rep_user_id (author_id), $msg
sub insert_rev {
    my $cname = (caller(0))[3];
    my $self = shift;

    unless ( defined $self->{_cache}->{$cname} ) {
        $self->{_cache}->{$cname} = $self->{dbh}->prepare(qq{
            insert into rev ( rev_num, author_id, date, msg ) values ( ?, ?, ?, ? )
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



sub set_rep_file_modified {
    my $cname = (caller(0))[3];
    my $self = shift;
    my ( $sub_path, $rep_path_id, $revision ) = @_;

    return 1;
}




1;