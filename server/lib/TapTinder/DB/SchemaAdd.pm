package TapTinder::DB::SchemaAdd;

use base 'TapTinder::DB::Schema';


# Own resultsets:

package TapTinder::DB::Schema::msession;

my $source3 = __PACKAGE__->result_source_instance();
my $new_source3 = $source3->new( $source3 );
$new_source3->source_name( 'MSessionStatus' );

# mslog_id is autoincrement
$new_source3->name(\<<'SQLEND');
(
    select xm.*,
           msl.mslog_id,
           msl.change_time as mslog_change_time,
           mss.name as msstatus_name,
           c.name as last_cmd_name,
           mjpc.end_time as last_cmd_end_time,
           rc.rcommit_id as last_cmd_rcommit_id,
           s.sha as last_cmd_rcommit_sha,
           ra.rep_login as last_cmd_author,
           project.name as last_cmd_project_name
      from (
        select ma.machine_id,
               ma.name as machine_name,
               ma.cpuarch,
               ma.osname,
               ma.archname,
               ms.msession_id,
               ms.client_rev,
               ms.start_time,
               ( select max(msjpc.msjobp_cmd_id)
                   from msproc msp,
                        msjob msj,
                        msjobp msjp,
                        msjobp_cmd msjpc
                  where msp.msession_id = ms.msession_id
                    and msj.msproc_id = msp.msproc_id
                    and msjp.msjob_id = msj.msjob_id
                    and msjpc.msjobp_id = msjp.msjobp_id
               ) as last_finished_msjobp_cmd_id,
               ( select max(i_ml.mslog_id)
                   from mslog i_ml
                  where i_ml.msession_id = ms.msession_id
               ) as max_mslog_id
          from msession ms,
               machine ma
         where ma.machine_id = ms.machine_id
           and ms.end_time is null
           and ms.abort_reason_id is null
      ) xm,
      mslog msl,
      msstatus mss,
      msjobp_cmd mjpc,
      msjobp mjp,
      jobp_cmd jpc,
      jobp jp,
      cmd c,
      rcommit rc,
      sha s,
      rauthor ra,
      rep,
      project
    where msl.mslog_id = xm.max_mslog_id
      and msl.change_time > ?
      and mss.msstatus_id = msl.msstatus_id
      and mjpc.msjobp_cmd_id = last_finished_msjobp_cmd_id
      and mjp.msjobp_id = mjpc.msjobp_id
      and jpc.jobp_cmd_id = mjpc.jobp_cmd_id
      and jp.jobp_id = jpc.jobp_id
      and c.cmd_id = jpc.cmd_id
      and rc.rcommit_id = mjp.rcommit_id
      and s.sha_id = rc.sha_id
      and ra.rauthor_id = rc.author_id
      and rep.rep_id = rc.rep_id
      and rep.project_id = jp.project_id
      and project.project_id = rep.project_id
    order by xm.machine_id, xm.msession_id, xm.start_time
)
SQLEND

TapTinder::DB::Schema->register_extra_source( 'MSessionStatus' => $new_source3 );



package TapTinder::DB::Schema::msjobp_cmd;

my $source5 = __PACKAGE__->result_source_instance();
my $new_source5 = $source5->new( $source5 );
$new_source5->source_name( 'NotLoadedTruns' );

$new_source5->name(\<<'SQLEND');
(
select mjpc.msjobp_cmd_id,
       fsp.path as file_path,
       fsf.name as file_name,
       mjp.rev_id,
       r.rev_num,
       jp.rep_path_id
 from msjobp_cmd mjpc,
      jobp_cmd jpc,
      fsfile fsf,
      fspath fsp,
      msjobp mjp,
      rev r,
      msjob mj,
      jobp jp
where mjpc.outdata_id is not null
  and jpc.jobp_cmd_id = mjpc.jobp_cmd_id
  and jpc.cmd_id = 6 -- trun
    and not exists (
    select 1
      from trun tr
     where tr.msjobp_cmd_id = mjpc.msjobp_cmd_id
  )
  and fsf.fsfile_id = mjpc.outdata_id
  and fsp.fspath_id = fsf.fspath_id
  and mjp.msjobp_id = mjpc.msjobp_id
  and r.rev_id = mjp.rev_id
  and mj.msjob_id = mjp.msjob_id
  and jp.jobp_id = mjp.jobp_id
order by mjpc.msjobp_cmd_id desc
)
SQLEND

TapTinder::DB::Schema->register_extra_source( 'NotLoadedTruns' => $new_source5 );



package TapTinder::DB::Schema::rpath;

my $source6 = __PACKAGE__->result_source_instance();
my $new_source6 = $source5->new( $source6 );
$new_source6->source_name( 'ActiveRepPathList' );

$new_source6->name(\<<'SQLEND');
(
   SELECT rp.*,
          mr.max_rev_num,
          r.rev_id, r.author_id, r.date,
          ra.rep_login
     FROM rep_path rp,
        ( SELECT rrp.rep_path_id, max(r.rev_num) as max_rev_num
           FROM rev_rep_path  rrp, rev r
          WHERE r.rev_id = rrp.rev_id
          GROUP BY rrp.rep_path_id
        ) mr,
        rev r,
        rep_author ra
    WHERE rp.rep_id = ?
      and rp.rev_num_to is null -- optimalization
      and rp.path not like "tags/%"
      and mr.rep_path_id = rp.rep_path_id
      and r.rev_num = mr.max_rev_num
      and ra.rep_author_id = r.author_id
    ORDER BY max_rev_num DESC
)
SQLEND

TapTinder::DB::Schema->register_extra_source('ActiveRepPathList' => $new_source6);


# ViewMD - view metadata

package TapTinder::DB::Schema::machine;
__PACKAGE__->cwm_conf( {
    auth => {
        'passwd' => 'R',
        'ip' => 'R',
    },
} );


package TapTinder::DB::Schema::msession;
__PACKAGE__->cwm_conf( {
    auth => {
        'key' => 'R',
        'pid' => 'R',
    },
} );


package TapTinder::DB::Schema::msjob;
__PACKAGE__->cwm_conf( {
     max_deep => 2,
} );


package TapTinder::DB::Schema::msjobp;
__PACKAGE__->cwm_conf( {
     max_deep => 2,
} );


package TapTinder::DB::Schema::mslog;
__PACKAGE__->cwm_conf( {
     max_deep => 1,
} );


package TapTinder::DB::Schema::msstatus;
__PACKAGE__->cwm_conf( {
    col_type => {
        'name' => 'G',
    },
} );


package TapTinder::DB::Schema::msproc_log;
__PACKAGE__->cwm_conf( {
     max_deep => 1,
} );


package TapTinder::DB::Schema::rauthor;
__PACKAGE__->cwm_conf( {
    col_type => {
        'rep_login' => 'S',
        'email' => 'S',
    },
} );


package TapTinder::DB::Schema::rcparent;
__PACKAGE__->cwm_conf( {
     max_deep => 1,
} );


package TapTinder::DB::Schema::rref_rcommit;
# ToDo SQL::Translator...
__PACKAGE__->set_primary_key('rref_id', 'rcommit_id');
__PACKAGE__->add_unique_constraint(
    'primary' => [ qw/ rref_id rcommit_id / ],
);

__PACKAGE__->cwm_conf( {
     max_deep => 1,
} );


package TapTinder::DB::Schema::sha;
__PACKAGE__->cwm_conf( {
    col_type => {
        'sha' => 'S',
    },
} );


package TapTinder::DB::Schema::rfile;
__PACKAGE__->cwm_conf( {
    col_type => {
        'sub_path' => 'G',
    },
} );


package TapTinder::DB::Schema::rtest;
__PACKAGE__->cwm_conf( {
    col_type => {
        'number' => 'G',
    },
} );


package TapTinder::DB::Schema::user;
__PACKAGE__->cwm_conf( {
    auth => {
        'passswd' => 'R',
    },
} );


1;
