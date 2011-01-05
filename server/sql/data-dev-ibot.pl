use strict;
use warnings;
use utf8;

return sub {
    my ( $schema, $delete_all, $data ) = @_;

    # table: ibot_log
    $schema->resultset('ibot_log')->delete_all() if $delete_all;
    return 1;
};
