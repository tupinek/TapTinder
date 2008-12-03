package TapTinder::DB::SchemaAdd;

# version 0.04
use base 'TapTinder::DB::Schema';


package TapTinder::DB::Schema::rev_rep_path;

__PACKAGE__->add_unique_constraint([ qw/rev_id rep_path_id/ ]);

=pod

# own resultsets
package TapTinder::DB::Schema::rep_path;

my $source = __PACKAGE__->result_source_instance();
my $new_source = $source->new( $source );
$new_source->source_name( 'ActiveRepPathList' );

$new_source->name(\<<'');
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


TapTinder::DB::Schema->register_source( 'ActiveRepPathList' => $new_source );

=cut


# ViewMD - view metadata

package TapTinder::DB::Schema::build_conf;
__PACKAGE__->cols_in_foreign_tables( [ qw/cc devel/ ] );

package TapTinder::DB::Schema::farm;
__PACKAGE__->cols_in_foreign_tables( [ qw/name/ ] );

package TapTinder::DB::Schema::machine;
__PACKAGE__->restricted_cols( { 'passwd' => 1, } );
__PACKAGE__->cols_in_foreign_tables( [ qw/name/ ] );

package TapTinder::DB::Schema::msession;
__PACKAGE__->restricted_cols( { 'key' => 1, 'pid' => 1, } );

package TapTinder::DB::Schema::param_type;
__PACKAGE__->cols_in_foreign_tables( [ qw/name/ ] );

package TapTinder::DB::Schema::project;
__PACKAGE__->cols_in_foreign_tables( [ qw/name/ ] );

package TapTinder::DB::Schema::rep;
__PACKAGE__->cols_in_foreign_tables( [ qw/name/ ] );

package TapTinder::DB::Schema::rep_author;
__PACKAGE__->cols_in_foreign_tables( [ qw/rep_login/ ] );

package TapTinder::DB::Schema::rep_change_type;
__PACKAGE__->cols_in_foreign_tables( [ qw/info/ ] );

package TapTinder::DB::Schema::rep_file;
__PACKAGE__->cols_in_foreign_tables( [ qw/rep_path_id sub_path rev_num_from rev_num_to/ ] );

package TapTinder::DB::Schema::rep_path;
__PACKAGE__->cols_in_foreign_tables( [ qw/path rev_num_from rev_num_to/ ] );

package TapTinder::DB::Schema::rep_test;
__PACKAGE__->cols_in_foreign_tables( [ qw/rep_file_id number/ ] );

package TapTinder::DB::Schema::rev;
__PACKAGE__->cols_in_foreign_tables( [ qw/rev_num/ ] );

package TapTinder::DB::Schema::trest;
__PACKAGE__->cols_in_foreign_tables( [ qw/title/ ] );

package TapTinder::DB::Schema::user;
__PACKAGE__->restricted_cols( { 'passwd' => 1, } );
__PACKAGE__->cols_in_foreign_tables( [ qw/login/ ] );


1;
