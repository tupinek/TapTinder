package TapTinder::DB;

use strict;
use warnings;

use Carp qw(carp croak verbose);
use FindBin qw($RealBin);
use Digest::MD5 qw(md5);

use DBI;

use Data::Dumper;
use Devel::StackTrace;


=head1 NAME

TapTinder::DB - TapTinder database functions

=head1 SYNOPSIS

See L<TapTinder::DB>

=head1 DESCRIPTION

TapTinder database functions. Doesn't use DBIx::Class schema.

=cut


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
    my $self = shift;
    my $dd = Data::Dumper->new( [ @_ ] );
    $dd->Indent(1);
    $dd->Terse(1);
    $dd->Purity(1);
    $dd->Deepcopy(1);
    $dd->Deparse(1);
    return $dd->Dump;
}

sub dump_get {
    my ( $self, $ra_args, $results ) = @_;
    my $sub_name = (caller(1))[3];
    my $args_str = ' ';
    if ( defined $ra_args && ref $ra_args eq 'ARRAY' ) {
        my $num = 0;
        foreach ( @$ra_args ) {
            $args_str .= ', ' if $num;
            $args_str .= ( defined $_ ) ? $_ : 'undef';
            $num++;
        }
    }
    return "function $sub_name, input (" . $args_str . "), result " . $self->dmp($results);
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
    $msg = '' unless defined $msg;
    $msg .= $self->{dbh}->errstr;
    $msg .= "\n\n" . trc();
    croak $msg;
}



# repository $path
sub get_rep_id {
    my $self = shift;

    my $sth = $self->{dbh}->prepare_cached(qq{
        select rep_id
          from rep
         where rep.path = ?
           and rep.active = 1
    });
    $self->db_error() if $self->{dbh}->err;

    my $result = $self->{dbh}->selectrow_hashref( $sth, {}, @_ );
    $self->db_error() if $self->{dbh}->err;
    print $self->dump_get( \@_, $result ) if $self->{debug};
    return $result->{rep_id};
}


# $rep_id
sub get_rep_authors {
    my $self = shift;

    my $sth = $self->{dbh}->prepare_cached(qq{
        select rep_author_id,
               rep_login
          from rep_author
         where rep_id = ?
    });
    $self->db_error() if $self->{dbh}->err;

    $sth->execute( @_ );
    my $result = $sth->fetchall_hashref( 'rep_login' );
    $self->db_error() if $self->{dbh}->err;
    print $self->dump_get( \@_, $result ) if $self->{debug};
    return $result;
}

# $rep_id, $rep_login (null)
sub get_rep_author_id {
    my $self = shift;


    my $sth = $self->{dbh}->prepare_cached(qq{
        select rep_author_id
          from rep_author
         where rep_id = ?
           and rep_login = ? OR (rep_login IS NULL AND ? = 1)
    });
    $self->db_error() if $self->{dbh}->err;

    my $result = $self->{dbh}->selectrow_hashref(
        $sth, {},
        $_[0], $_[1], defined($_[1]) ? 0 : 1
    );
    $self->db_error() if $self->{dbh}->err;
    print $self->dump_get( \@_, $result ) if $self->{debug};
    return $result->{rep_author_id};
}

# $rep_id, $rep_login
sub insert_rep_author {
    my $self = shift;

    my $sth = $self->{dbh}->prepare_cached(qq{
        insert into rep_author ( rep_id, rep_login ) values ( ?, ? )
    });
    $self->db_error() if $self->{dbh}->err;

    $sth->execute( @_ );
    $self->db_error() if $self->{dbh}->err;
    #my $result = $self->{dbh}->last_insert_id( undef, undef, undef, undef);
    my $result = $self->get_rep_author_id( $_[0], $_[1] );
    print $self->dump_get( \@_, $result ) if $self->{debug};
    return $result;
}


# $rep_id, $rep_path, $rev_num
sub get_rep_path_id {
    my $self = shift;
    my ( $rep_id, $rep_path, $rev_num ) = @_;

    my $sth = $self->{dbh}->prepare_cached(qq{
        select rep_path_id
          from rep_path
         where rep_id = ?
           and path = ?
           and rev_num_from <= ?
           and (rev_num_to IS NULL OR rev_num_to >= ?)
    });
    $self->db_error() if $self->{dbh}->err;

    my $result = $self->{dbh}->selectrow_hashref( $sth, {}, $rep_id, $rep_path, $rev_num, $rev_num );
    $self->db_error() if $self->{dbh}->err;
    print $self->dump_get( \@_, $result ) if $self->{debug};
    return $result->{rep_path_id};
}

# $rep_id, $rep_path, $rev_num
# TODO $base_rev_id
sub insert_rep_path {
    my $self = shift;

    my $sth = $self->{dbh}->prepare_cached(qq{
        insert into rep_path ( rep_id, path, rev_num_from ) values ( ?, ?, ? )
    });
    $self->db_error() if $self->{dbh}->err;

    $sth->execute( @_ );
    $self->db_error() if $self->{dbh}->err;
    my $result = $self->get_rep_path_id( @_ );
    print $self->dump_get( \@_, $result ) if $self->{debug};
    return $result;
}

# $rep_id, $rep_path, $rev_num
sub set_rep_path_deleted {
    my $self = shift;
    my ( $rep_id, $rep_path, $rev_num ) = @_;

    my $sth = $self->{dbh}->prepare_cached(qq{
        update rep_path
           set rev_num_to = ?
         where rep_id = ?
           and path = ?
           and rev_num_from <= ?
           and rev_num_to is null
    });
    $self->db_error() if $self->{dbh}->err;

    $sth->execute(
        $rev_num-1, $rep_id, $rep_path, $rev_num-1
    );
    my $found_err = $self->{dbh}->err;
    $self->db_error() if $found_err;
    my $result = $self->get_rep_path_id( @_ );
    return !$found_err;
}


# $rev_id, $rep_path_id
sub exists_rev_rep_path {
    my $self = shift;

    my $sth = $self->{dbh}->prepare_cached(qq{
        select 1 as found
          from rev_rep_path
         where rev_id = ?
           and rep_path_id = ?
    });
    $self->db_error() if $self->{dbh}->err;

    my $result = $self->{dbh}->selectrow_hashref( $sth, {}, @_ );
    $self->db_error() if $self->{dbh}->err;
    print $self->dump_get( \@_, $result ) if $self->{debug};
    return $result->{found};
}


# $rev_id, $rep_path_id
sub insert_rev_rep_path {
    my $self = shift;

    my $sth = $self->{dbh}->prepare_cached(qq{
        insert into rev_rep_path ( rev_id, rep_path_id ) values ( ?, ? )
    });
    $self->db_error() if $self->{dbh}->err;

    $sth->execute( @_ );
    $self->db_error() if $self->{dbh}->err;
    my $result = $self->get_rep_path_id( $_[0], $_[1] );
    print $self->dump_get( \@_, $result ) if $self->{debug};
    return $result;
}


# $rep_id, $rev_num
sub get_rev_id {
    my $self = shift;

    my $sth = $self->{dbh}->prepare_cached(qq{
        select rev_id
          from rev
         where rep_id = ?
           and rev_num = ?
    });
    $self->db_error() if $self->{dbh}->err;

    my $result = $self->{dbh}->selectrow_hashref(
        $sth,
        {},
        @_
    );
    $self->db_error() if $self->{dbh}->err;
    print $self->dump_get( \@_, $result ) if $self->{debug};
    return $result->{rev_id};
}

# $rep_id
sub get_max_rev_num {
    my $self = shift;

    my $sth = $self->{dbh}->prepare_cached(qq{
        select MAX(rev_num) as max_rev_num
          from rev
         where rep_id = ?
    });
    $self->db_error() if $self->{dbh}->err;

    my $result = $self->{dbh}->selectrow_hashref( $sth, {}, @_ );
    $self->db_error() if $self->{dbh}->err;
    print $self->dump_get( \@_, $result ) if $self->{debug};
    return $result->{max_rev_num};
}

# $rep_id
sub get_number_of_revs {
    my $self = shift;

    my $sth = $self->{dbh}->prepare_cached(qq{
        select count(1) as number_of_revs
          from rev
         where rep_id = ?
    });
    $self->db_error() if $self->{dbh}->err;

    my $result = $self->{dbh}->selectrow_hashref( $sth, {}, @_ );
    $self->db_error() if $self->{dbh}->err;
    print $self->dump_get( \@_, $result ) if $self->{debug};
    return $result->{number_of_revs};
}

# $rep_id, $rev_num, $date, $rep_author_id, $msg
sub insert_rev {
    my $self = shift;

    my $sth = $self->{dbh}->prepare_cached(qq{
        insert into rev ( rep_id, rev_num, author_id, date, msg ) values ( ?, ?, ?, ?, ? )
    });
    $self->db_error() if $self->{dbh}->err;

    $sth->execute( @_ );
    $self->db_error() if $self->{dbh}->err;
    my $result = $self->get_rev_id( $_[0], $_[1] );
    print $self->dump_get( \@_, $result ) if $self->{debug};
    return $result;
}


# $rev_id, $rev_num, $rep_file_id, $rep_change_type_id
sub insert_rep_file_change {
    my $self = shift;

    my $sth = $self->{dbh}->prepare_cached(qq{
        insert into rep_file_change ( rev_id, rev_num, rep_file_id, change_type_id ) values ( ?, ?, ?, ? )
    });
    $self->db_error() if $self->{dbh}->err;

    my $found_err = $self->{dbh}->err;
    $self->db_error() if $found_err;
    return !$found_err;
}


# $sub_path, $rep_path_id, $rev_num
sub get_rep_file_id {
    my $self = shift;
    my ( $sub_path, $rep_path_id, $rev_num ) = @_;

    my $sth = $self->{dbh}->prepare_cached(qq{
        select rep_file_id
          from rep_file
         where rep_path_id = ?
           and sub_path = ?
           and rev_num_from <= ?
           and (rev_num_to IS NULL OR rev_num_to >= ?)
    });
    $self->db_error() if $self->{dbh}->err;

    my $result = $self->{dbh}->selectrow_hashref(
        $sth,
        {},
        $rep_path_id, $sub_path, $rev_num, $rev_num
    );
    $self->db_error() if $self->{dbh}->err;
    print $self->dump_get( \@_, $result ) if $self->{debug};
    return $result->{rep_file_id};
}

# $sub_path, $rep_path_id, $rev_num
sub insert_rep_file {
    my $self = shift;

    my $sth = $self->{dbh}->prepare_cached(qq{
        insert into rep_file ( sub_path, rep_path_id, rev_num_from ) values ( ?, ?, ? )
    });
    $self->db_error() if $self->{dbh}->err;

    $sth->execute( @_ );
    $self->db_error() if $self->{dbh}->err;
    my $result = $self->get_rep_file_id( @_ );
    print $self->dump_get( \@_, $result ) if $self->{debug};
    return $result;
}


# $sub_path, $rep_path_id, $rev_num
sub set_rep_file_deleted {
    my $self = shift;
    my ( $sub_path, $rep_path_id, $rev_num ) = @_;

    my $sth = $self->{dbh}->prepare_cached(qq{
        update rep_file
           set rev_num_to = ?
         where rep_path_id = ?
           and sub_path = ?
           and rev_num_from <= ?
           and rev_num_to is null
    });
    $self->db_error() if $self->{dbh}->err;

    $sth->execute(
        $rev_num-1, $rep_path_id, $sub_path, $rev_num-1
    );
    my $found_err = $self->{dbh}->err;
    $self->db_error() if $found_err;
    return !$found_err;
}


# $sub_path, $rep_path_id, $rev_num, $rev_id
sub set_rep_file_modified {
    my $self = shift;
    my ( $sub_path, $rep_path_id, $rev_num, $rev_id ) = @_;

    my $rep_file_id = $self->get_rep_file_id( $sub_path, $rep_path_id, $rev_num );
    return 0 unless $rep_file_id;

    # M (modified) - rep_change_type_id = 2
    my $ok1 = $self->insert_rep_file_change( $rev_id, $rev_num, $rep_file_id, 2 );
    return $ok1;
}


sub str_args_md5 {
    my $self = shift;
    my $str = '';
    $str .= $_ foreach @_;
    return md5($str);
}


# $hash
sub get_build_conf_id {
    my $self = shift;
    my ( $hash ) = @_;

    my $sth = $self->{dbh}->prepare_cached(qq{
        select build_conf_id
          from build_conf
         where hash = ?
    });
    $self->db_error() if $self->{dbh}->err;

    my $result = $self->{dbh}->selectrow_hashref(
        $sth,
        {},
        $hash
    );
    $self->db_error() if $self->{dbh}->err;
    print $self->dump_get( \@_, $result ) if $self->{debug};
    return $result->{build_conf_id};
}


# $hash, $cc, $devel, $optimize
sub insert_build_conf {
    my $self = shift;

    my $sth = $self->{dbh}->prepare_cached(qq{
        insert into build_conf ( hash, cc, devel, `optimize` ) values ( ?, ?, ?, ? )
    });
    $self->db_error() if $self->{dbh}->err;

    $sth->execute( @_ );
    $self->db_error() if $self->{dbh}->err;
    my $result = $self->get_build_conf_id( $_[0] );
    print $self->dump_get( \@_, $result ) if $self->{debug};
    return $result;
}


sub get_or_insert_build_conf {
    my $self = shift;
    my $hash = $self->str_args_md5( @_ );
    my $build_conf_id = $self->get_build_conf_id($hash);
    return $build_conf_id if defined $build_conf_id;
    return $self->insert_build_conf( $hash, @_ );
}



# $rep_path_id, $rev_id, $msession_id, $build_conf_id
# TODO $start_time, $duration
sub get_build_id {
    my $self = shift;

    my $sth = $self->{dbh}->prepare_cached(qq{
        select build_id
          from build
         where rep_path_id = ?
           and rev_id = ?
           and msession_id = ?
           and conf_id = ?
    });
    $self->db_error() if $self->{dbh}->err;

    my $result = $self->{dbh}->selectrow_hashref( $sth, {}, $_[0], $_[1], $_[2], $_[3] );
    $self->db_error() if $self->{dbh}->err;
    print $self->dump_get( \@_, $result ) if $self->{debug};
    return $result->{build_id};
}

# $rep_path_id, $rev_id, $msession_id, $build_conf_id, $start_time,
# $build_duration
sub insert_build {
    my $self = shift;

    my $sth = $self->{dbh}->prepare_cached(qq{
        insert into build (
            rep_path_id, rev_id, msession_id, conf_id, start_time,
            build_duration
        ) values (
            ?, ?, ?, ?, ?,
            ?
        )
    });
    $self->db_error() if $self->{dbh}->err;

    $sth->execute( @_ );
    $self->db_error() if $self->{dbh}->err;
    my $result = $self->get_build_id( @_ );
    print $self->dump_get( \@_, $result ) if $self->{debug};
    return $result;
}

# $rep_path_id, $rev_id, $msession_id, $build_conf_id, $start_time,
# $build_duration
sub get_or_insert_build {
    my $self = shift;
    my $build_id = $self->get_build_id( @_ );
    return $build_id if defined $build_id;
    return $self->insert_build( @_ );
}


# $rev_id, $rep_path_id, $machine_id, $conf_id
sub get_max_build_id {
    my $self = shift;

    my $sth = $self->{dbh}->prepare_cached(qq{
        select MAX(build_id) as max_build_id
          from build
         where rev_id = ?
           and rep_path_id = ?
           and machine_id  = ?
           and conf_id = ?
    });
    $self->db_error() if $self->{dbh}->err;

    my $result = $self->{dbh}->selectrow_hashref( $sth, {}, @_ );
    $self->db_error() if $self->{dbh}->err;
    print $self->dump_get( \@_, $result ) if $self->{debug};
    return $result->{max_build_id};
}



# $hash
sub get_trun_conf_id {
    my $self = shift;
    my ( $hash ) = @_;

    my $sth = $self->{dbh}->prepare_cached(qq{
        select trun_conf_id
          from trun_conf
         where hash = ?
    });
    $self->db_error() if $self->{dbh}->err;

    my $result = $self->{dbh}->selectrow_hashref(
        $sth,
        {},
        $hash
    );
    $self->db_error() if $self->{dbh}->err;
    print $self->dump_get( \@_, $result ) if $self->{debug};
    return $result->{trun_conf_id};
}


# $hash, $harness_args
sub insert_trun_conf {
    my $self = shift;

    my $sth = $self->{dbh}->prepare_cached(qq{
        insert into trun_conf ( hash, harness_args ) values ( ?, ? )
    });
    $self->db_error() if $self->{dbh}->err;

    $sth->execute( @_ );
    $self->db_error() if $self->{dbh}->err;
    my $result = $self->get_trun_conf_id( $_[0] );
    print $self->dump_get( \@_, $result ) if $self->{debug};
    return $result;
}


sub get_or_insert_trun_conf {
    my $self = shift;
    my $hash = $self->str_args_md5( @_ );
    my $trun_conf_id = $self->get_trun_conf_id($hash);
    return $trun_conf_id if defined $trun_conf_id;
    return $self->insert_trun_conf( $hash, @_ );
}


# $build_id, $trun_conf_id
sub get_max_trun_id {
    my $self = shift;

    my $sth = $self->{dbh}->prepare_cached(qq{
        select MAX(trun_id) as max_trun_id
          from trun
         where build_id = ?
           and conf_id = ?
    });
    $self->db_error() if $self->{dbh}->err;

    my $result = $self->{dbh}->selectrow_hashref( $sth, {}, @_ );
    $self->db_error() if $self->{dbh}->err;
    print $self->dump_get( \@_, $result ) if $self->{debug};
    return $result->{max_trun_id};
}


# $machine_id, $rep_path_id, $rev_id, $build_conf_id, $trun_conf_id
sub get_max_trun_id_with_conf {
    my $self = shift;

    my $sth = $self->{dbh}->prepare_cached(qq{
        select MAX(trun_id) as max_trun_id
          from msession, build, trun
         where msession.machine_id = ?
           and build.msession_id = msession.msession_id
           and build.rep_path_id = ?
           and build.rev_id = ?
           and build.conf_id = ?
           and trun.build_id = build.build_id
           and trun.conf_id = ?
    });
    $self->db_error() if $self->{dbh}->err;

    my $result = $self->{dbh}->selectrow_hashref( $sth, {}, @_ );
    $self->db_error() if $self->{dbh}->err;
    print $self->dump_get( \@_, $result ) if $self->{debug};
    return $result->{max_trun_id};
}


# $trun_id, $stats
sub update_trun_stats {
    my $self = shift;
    my ( $trun_id, $stats ) = @_;

    my $sth = $self->{dbh}->prepare_cached(qq{
        update trun
          set num_notseen = ?,
              num_failed = ?,
              num_unknown = ?,
              num_todo = ?,
              num_bonus = ?,
              num_skip = ?,
              num_ok = ?
        where trun_id = ?
    });
    $self->db_error() if $self->{dbh}->err;


    my @in = @$stats;
    push @in, $trun_id;

    $sth->execute( @in );
    my $found_err = $self->{dbh}->err;
    print $self->dump_get( \@in, $found_err ) if $self->{debug};
    return !$found_err;
}


# $build_id, $trun_conf_id
sub insert_trun_base {
    my $self = shift;

    my $sth = $self->{dbh}->prepare_cached(qq{
        insert into trun ( build_id, conf_id ) values ( ?, ? )
    });
    $self->db_error() if $self->{dbh}->err;

    $sth->execute( @_ );
    my $found_err = $self->{dbh}->err;
    my $result = undef;

    # TODO
    #$result = $self->{dbh}->last_insert_id(undef,undef,undef,undef) unless $found_err;
    $result = $self->get_max_trun_id(@_) unless $found_err;

    print $self->dump_get( \@_, $result ) if $self->{debug};
    $self->db_error() if $found_err;
    return $result;
}


# TODO
# next 3 subs are created from in get_conf_id, insert_conf_id
#   and get_or_insert_conf ( s{conf}{tskipall_msg}gm )

# $hash
sub get_tskipall_msg_id {
    my $self = shift;
    my ( $hash ) = @_;

    my $sth = $self->{dbh}->prepare_cached(qq{
        select tskipall_msg_id
          from tskipall_msg
         where hash = ?
    });
    $self->db_error() if $self->{dbh}->err;

    my $result = $self->{dbh}->selectrow_hashref(
        $sth,
        {},
        $hash
    );
    $self->db_error() if $self->{dbh}->err;
    print $self->dump_get( \@_, $result ) if $self->{debug};
    return $result->{tskipall_msg_id};
}

# $hash, $tskipall_msg
sub insert_tskipall_msg {
    my $self = shift;

    my $sth = $self->{dbh}->prepare_cached(qq{
        insert into tskipall_msg ( hash, msg ) values ( ?, ? )
    });
    $self->db_error() if $self->{dbh}->err;

    $sth->execute( @_ );
    $self->db_error() if $self->{dbh}->err;
    my $result = $self->get_tskipall_msg_id( $_[0] );
    print $self->dump_get( \@_, $result ) if $self->{debug};
    return $result;
}

# $tskipall_msg
sub get_or_insert_tskipall_msg {
    my $self = shift;
    my $hash = $self->str_args_md5( @_ );
    my $tskipall_msg_id = $self->get_tskipall_msg_id($hash);
    return $tskipall_msg_id if defined $tskipall_msg_id;
    return $self->insert_tskipall_msg( $hash, @_ );
}


sub get_inserted_tfile_id {
    my $self = shift;

    return $self->{dbh}->last_insert_id(undef,undef,undef,undef);
    #my $rows = $self->{dbh}->do("select max(trun_id) from trun");
    #$self->dmp($rows); exit;
}

# $trun_id, $rep_file_id
sub get_tfile_id {
    my $self = shift;
    my ( $sub_path, $rep_path_id, $rev_num ) = @_;

    my $sth = $self->{dbh}->prepare_cached(qq{
        select tfile_id
          from tfile
         where trun_id = ?
           and rep_file_id = ?
    });
    $self->db_error() if $self->{dbh}->err;

    my $result = $self->{dbh}->selectrow_hashref( $sth, {}, @_ );
    $self->db_error() if $self->{dbh}->err;
    print $self->dump_get( \@_, $result ) if $self->{debug};
    return $result->{tfile_id};
}


# $trun_id, $rep_file_id, $all_passed, $skip_all_msg, $hang
sub insert_tfile {
    my $self = shift;
    my $skip_all_msg = $_[3];

    my $tskipall_msg_id = undef;
    if ( $skip_all_msg ) {
        my $tskipall_msg_id = $self->get_or_insert_tskipall_msg( $skip_all_msg );
        return undef unless $tskipall_msg_id;
    }

    my $sth = $self->{dbh}->prepare_cached(qq{
        insert into tfile ( trun_id, rep_file_id, all_passed, tskipall_msg_id, hang ) values ( ?, ?, ?, ?, ? )
    });
    $self->db_error() if $self->{dbh}->err;

    $sth->execute( @_ );
    my $found_err = $self->{dbh}->err;
    my $result = undef;

    # TODO
    #$result = $self->{dbh}->last_insert_id(undef,undef,undef,undef) unless $found_err;
    $result = $self->get_tfile_id( $_[0], $_[1] ) unless $found_err;

    print $self->dump_get( \@_, $result ) if $self->{debug};
    $self->db_error() if $found_err;
    return $result;
}


# $rep_file_id, $test_num
sub get_rep_test_id {
    my $self = shift;
    my ( $sub_path, $rep_path_id, $rev_num ) = @_;

    my $sth = $self->{dbh}->prepare_cached(qq{
        select rep_test_id
          from rep_test
         where rep_file_id = ?
           and number = ?
    });
    $self->db_error() if $self->{dbh}->err;

    my $result = $self->{dbh}->selectrow_hashref( $sth, {}, @_ );
    $self->db_error() if $self->{dbh}->err;
    print $self->dump_get( \@_, $result ) if $self->{debug};
    return $result->{rep_test_id};
}


# $rep_file_id, $test_num, $test_name
sub insert_rep_test {
    my $self = shift;

    my $sth = $self->{dbh}->prepare_cached(qq{
        insert into rep_test ( rep_file_id, number, name, has_another_name ) values ( ?, ?, ?, 0 )
    });
    $self->db_error() if $self->{dbh}->err;

    $sth->execute( @_ );
    $self->db_error() if $self->{dbh}->err;
    my $result = $self->get_rep_test_id( $_[0], $_[1] );
    print $self->dump_get( \@_, $result ) if $self->{debug};
    return $result;
}


# $rep_file_id, $test_num, $test_name
sub prepare_and_get_rep_test_id {
    my $self = shift;
    my ( $rep_file_id, $test_num, $test_name ) = @_;

    # TODO rep_test.has_another_name
    my $rep_test_id = $self->get_rep_test_id( $rep_file_id, $test_num );
    $rep_test_id = $self->insert_rep_test( $rep_file_id, $test_num, $test_name ) unless $rep_test_id;
    return $rep_test_id;
}


# $trun_id, $rep_test_id
sub get_ttest_id {
    my $self = shift;
    my ( $sub_path, $rep_path_id, $rev_num ) = @_;

    my $sth = $self->{dbh}->prepare_cached(qq{
        select ttest_id
          from ttest
         where trun_id = ?
           and rep_test_id = ?
    });
    $self->db_error() if $self->{dbh}->err;

    my $result = $self->{dbh}->selectrow_hashref( $sth, {}, @_ );
    $self->db_error() if $self->{dbh}->err;
    print $self->dump_get( \@_, $result ) if $self->{debug};
    return $result->{ttest_id};
}


# $trun_id, $rep_test_id, $trest_id
sub insert_ttest {
    my $self = shift;

    my $sth = $self->{dbh}->prepare_cached(qq{
        insert into ttest ( trun_id, rep_test_id, trest_id ) values ( ?, ?, ? )
    });
    $self->db_error() if $self->{dbh}->err;

    $sth->execute( @_ );
    $self->db_error() if $self->{dbh}->err;
    my $result = $self->get_ttest_id( $_[0], $_[1] );
    print $self->dump_get( \@_, $result ) if $self->{debug};
    return $result;
}


# $trun_id, $rep_file_id, $test_num, $test_name, $trest_id
sub prepare_others_and_insert_ttest {
    my $self = shift;
    my ( $trun_id, $rep_file_id, $test_num, $test_name, $trest_id ) = @_;

    my $rep_test_id = $self->prepare_and_get_rep_test_id( $rep_file_id, $test_num, $test_name );
    return 0 unless $rep_test_id;

    return $self->insert_ttest( $trun_id, $rep_test_id, $trest_id );
}


=head1 SEE ALSO

L<TapTinder>

=head1 AUTHOR

Michal Jurosz <mj@mj41.cz>

=head1 LICENSE

This file is part of TapTinder. See L<TapTinder> license.

=cut


1;
