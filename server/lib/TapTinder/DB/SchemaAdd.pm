package TapTinder::DB::SchemaAdd;

# version 0.04
use base 'TapTinder::DB::Schema';


package TapTinder::DB::Schema::rev_rep_path;

__PACKAGE__->add_unique_constraint([ qw/rev_id rep_path_id/ ]);


# own resultsets
package TapTinder::DB::Schema::rep_path;

# Make a new ResultSource based on the User class
my $source = __PACKAGE__->result_source_instance();
my $new_source = $source->new( $source );
$new_source->source_name( 'ActiveRepPathList' );

$new_source->name( \<<SQL );
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
SQL

TapTinder::DB::Schema->register_source( 'ActiveRepPathList' => $new_source );


# ViewMD - view metadata

package TapTinder::DB::Schema::rev_rep_path;
#__PACKAGE__->titles( [ 'Revision', 'Rep. path' ] );


package TapTinder::DB::Schema::user;
__PACKAGE__->restricted_cols( { 'passwd' => 1, } );
#__PACKAGE__->cols_in_table_view( [ qw/login first_name/ ] );

package TapTinder::DB::Schema::machine;
__PACKAGE__->restricted_cols( { 'passwd' => 1, } );


package TapTinder::DB::Schema::msession;
__PACKAGE__->restricted_cols( { 'key' => 1, 'pid' => 1, } );


1;
