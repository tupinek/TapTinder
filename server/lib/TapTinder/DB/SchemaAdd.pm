package TapTinder::DB::SchemaAdd;

# version 0.04
use base 'TapTinder::DB::Schema';


package TapTinder::DB::Schema::rev_rep_path;

__PACKAGE__->add_unique_constraint([ qw/rev_id rep_path_id/ ]);


# own resultsets
package TapTinder::DB::Schema::job;

my $source = __PACKAGE__->result_source_instance();
my $new_source = $source->new( $source );
$new_source->source_name( 'NotTestedJobs' );

$new_source->name(\<<'');
(
    select a_r.*
      from (
            select a_jp.job_id,
                   a_jp.jobp_id,
                   a_jp.rep_path_id,
                   r.rev_id,
                   r.rev_num,
                   a_jp.priority,
                   j.priority as jpriority
              from (
                    select distinct sa_jp.*
                      from (
                            ( select jp.jobp_id, mjc.priority, jp.rep_path_id, jp.job_id, jp.max_age
                                from machine_job_conf mjc,
                                     rep_path rp,
                                     jobp jp
                               where mjc.machine_id = ?
                                 and rp.rep_id = mjc.rep_id
                                 and jp.rep_path_id = rp.rep_path_id
                            )
                            union all
                            ( select jp.jobp_id, mjc.priority, jp.rep_path_id, jp.job_id, jp.max_age
                                from machine_job_conf mjc,
                                     jobp jp
                               where mjc.machine_id = ?
                                 and mjc.rep_path_id is not null
                                 and jp.rep_path_id = mjc.rep_path_id
                            )
                            union all
                            ( select jp.jobp_id, mjc.priority, jp.rep_path_id, jp.job_id, jp.max_age
                                from machine_job_conf mjc,
                                     jobp jp
                               where mjc.machine_id = ?
                                 and mjc.job_id is not null
                                 and jp.job_id = mjc.job_id
                            )
                           ) sa_jp
                  ) a_jp,
                  rev_rep_path rrp,
                  rev r,
                  job j
            where rrp.rep_path_id = a_jp.rep_path_id
              and r.rev_id = rrp.rev_id
              and DATE_SUB(CURDATE(), INTERVAL a_jp.max_age HOUR) <= r.date
              and j.job_id = a_jp.job_id
            order by a_jp.priority, j.priority, r.rev_num desc, a_jp.jobp_id
          ) a_r
    where not exists (
            select 1
              from msession ms,
                   msjob msj,
                   msjobp msjp,
                   jobp jp
             where ms.machine_id = ?
               and msj.msession_id = ms.msession_id
               and msjp.msjob_id = msj.msjob_id
               and jp.jobp_id = msjp.jobp_id
               and jp.rep_path_id = a_r.rep_path_id
               and msjp.rev_id = a_r.rev_id
          )
)


TapTinder::DB::Schema->register_source( 'NotTestedJobs' => $new_source );


my $source2 = __PACKAGE__->result_source_instance();
my $new_source2 = $source2->new( $source2 );
$new_source2->source_name( 'NextJobCmd' );

$new_source2->name(\<<'');
(
    select jp.jobp_id,
           jpc.jobp_cmd_id,
           c.name as cmd_name
      from jobp jp,
           jobp_cmd jpc,
           cmd c
     where jp.job_id = ?
       and jp.rep_path_id = ?
       and jpc.jobp_id = jp.jobp_id
       and (    ( ? is null or jpc.order > ? )
             or ( ? is null or jp.order > ? )
           )
       and c.cmd_id = jpc.cmd_id
     order by jp.order, jpc.order
)


TapTinder::DB::Schema->register_source( 'NextJobCmd' => $new_source2 );


package TapTinder::DB::Schema::msession;

my $source3 = __PACKAGE__->result_source_instance();
my $new_source3 = $source3->new( $source3 );
$new_source3->source_name( 'MSessionStatus' );

# mslog_id is autoincrement
$new_source3->name(\<<'');
(
    select ms.msession_id,
           ms.client_rev,
           ms.start_time,
           ma.machine_id,
           ma.name as machine_name,
           ma.cpuarch,
           ma.osname,
           ma.archname,
           ( select max(msjpc.end_time)
               from msjob msj,
                    msjobp msjp,
                    msjobp_cmd msjpc
              where msj.msession_id = ms.msession_id
                and msjp.msjob_id = msj.msjob_id
                and msjpc.msjobp_id = msjp.msjobp_id
           ) as last_cmd_finish_time,
           ( select mss.name
               from msstatus mss,
                    mslog ml
              where mss.msstatus_id = ml.msstatus_id
                and ml.mslog_id = (
                    select max(i_ml.mslog_id)
                      from mslog i_ml
                     where i_ml.msession_id = ms.msession_id
                )
           ) as msstatus_name
      from msession ms,
           machine ma
     where ma.machine_id = ms.machine_id
       and ms.end_time is null
       and ms.abort_reason_id is null
     order by ms.machine_id, ms.start_time
)


TapTinder::DB::Schema->register_source( 'MSessionStatus' => $new_source3 );



package TapTinder::DB::Schema::rev;

my $source4 = __PACKAGE__->result_source_instance();
my $new_source4 = $source4->new( $source4 );
$new_source4->source_name( 'BuildStatus' );

$new_source4->name(\<<'');
(
   select ms.machine_id,
          r.rev_id,
          mjpc.status_id,
          cs.name as status_name,
          concat(fsp.web_path, '/', fsf.name) as web_fpath
     from rev_rep_path rrp,
          rev r,
          jobp jp,
          jobp_cmd jpc,
          msjobp mjp,
          msjobp_cmd mjpc,
          cmd_status cs,
          msjob mj,
          msession ms,
          fsfile fsf,
          fspath fsp
    where rrp.rep_path_id = ? -- <
      and r.rev_id = rrp.rev_id
      and r.rev_num > ? -- last 100 revs
      and jp.rep_path_id = ? -- <
      and jp.order = 1 -- only first part
      and jpc.jobp_id = jp.jobp_id
      and jpc.cmd_id = 5 -- only make
      and mjp.rev_id = r.rev_id
      and mjp.jobp_id = jp.jobp_id
      and mjpc.jobp_cmd_id = jpc.jobp_cmd_id
      and mjpc.msjobp_id = mjp.msjobp_id
      and cs.cmd_status_id = mjpc.status_id
      and fsf.fsfile_id = mjpc.output_id
      and fsp.fspath_id = fsf.fspath_id
      and mj.msjob_id = mjp.msjobp_id
      and ms.msession_id = mj.msession_id
)


TapTinder::DB::Schema->register_source( 'BuildStatus' => $new_source4 );



# ViewMD - view metadata

package TapTinder::DB::Schema::build_conf;
__PACKAGE__->cols_in_foreign_tables( [ qw/cc devel/ ] );

package TapTinder::DB::Schema::cmd;
__PACKAGE__->cols_in_foreign_tables( [ qw/name/ ] );

package TapTinder::DB::Schema::cmd_status;
__PACKAGE__->cols_in_foreign_tables( [ qw/name/ ] );

package TapTinder::DB::Schema::farm;
__PACKAGE__->cols_in_foreign_tables( [ qw/name/ ] );

package TapTinder::DB::Schema::fsfile;
__PACKAGE__->cols_in_foreign_tables( [ qw/fspath_id name/ ] );

package TapTinder::DB::Schema::fsfile_type;
__PACKAGE__->cols_in_foreign_tables( [ qw/name/ ] );

package TapTinder::DB::Schema::fspath;
__PACKAGE__->cols_in_foreign_tables( [ qw/path/ ] );

package TapTinder::DB::Schema::job;
__PACKAGE__->cols_in_foreign_tables( [ qw/name/ ] );

package TapTinder::DB::Schema::jobp;
__PACKAGE__->cols_in_foreign_tables( [ qw/name/ ] );

package TapTinder::DB::Schema::jobp_cmd;
__PACKAGE__->cols_in_foreign_tables( [ qw/jobp_id order cmd_id/ ] );

package TapTinder::DB::Schema::machine;
__PACKAGE__->restricted_cols( { 'passwd' => 1, } );
__PACKAGE__->cols_in_foreign_tables( [ qw/name/ ] );

package TapTinder::DB::Schema::msabort_reason;
__PACKAGE__->cols_in_foreign_tables( [ qw/name/ ] );

package TapTinder::DB::Schema::msession;
__PACKAGE__->restricted_cols( { 'key' => 1, 'pid' => 1, } );

package TapTinder::DB::Schema::msjob;
__PACKAGE__->cols_in_foreign_tables( [ qw/msession_id job_id/ ] );

package TapTinder::DB::Schema::msjobp;
__PACKAGE__->cols_in_foreign_tables( [ qw/msjob_id jobp_id/ ] );

package TapTinder::DB::Schema::msstatus;
__PACKAGE__->cols_in_foreign_tables( [ qw/name/ ] );

package TapTinder::DB::Schema::param_type;
__PACKAGE__->cols_in_foreign_tables( [ qw/name/ ] );

package TapTinder::DB::Schema::project;
__PACKAGE__->cols_in_foreign_tables( [ qw/name/ ] );

package TapTinder::DB::Schema::rep;
__PACKAGE__->cols_in_foreign_tables( [ qw/name rep_id/ ] );

package TapTinder::DB::Schema::rep_author;
__PACKAGE__->cols_in_foreign_tables( [ qw/rep_login/ ] );

package TapTinder::DB::Schema::rep_change_type;
__PACKAGE__->cols_in_foreign_tables( [ qw/desc/ ] );

package TapTinder::DB::Schema::rep_file;
__PACKAGE__->cols_in_foreign_tables( [ qw/rep_path_id sub_path rev_num_from rev_num_to/ ] );

package TapTinder::DB::Schema::rep_path;
__PACKAGE__->cols_in_foreign_tables( [ qw/rep_id path rev_num_from rev_num_to/ ] );

package TapTinder::DB::Schema::rep_test;
__PACKAGE__->cols_in_foreign_tables( [ qw/rep_file_id number/ ] );

package TapTinder::DB::Schema::rev;
__PACKAGE__->cols_in_foreign_tables( [ qw/rep_id rev_num/ ] );

package TapTinder::DB::Schema::trest;
__PACKAGE__->cols_in_foreign_tables( [ qw/name/ ] );

package TapTinder::DB::Schema::user;
__PACKAGE__->restricted_cols( { 'passwd' => 1, } );
__PACKAGE__->cols_in_foreign_tables( [ qw/login/ ] );


1;
