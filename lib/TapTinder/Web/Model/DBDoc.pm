package TapTinder::Web::Model::DBDoc;

# ABSTRACT: TapTinder dbdoc model.

use strict;
use base 'Catalyst::Model::File';

__PACKAGE__->config(
    root_dir => TapTinder::Web->path_to('root/dbdoc'),
);

=head1 SYNOPSIS

See L<TapTinder::Web>, L<Catalyst::Model::File>.

=cut

1;
