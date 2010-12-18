package TapTinder::Web::Model::DBDoc;

use strict;
use base 'Catalyst::Model::File';

__PACKAGE__->config(
    root_dir => TapTinder::Web->path_to('root/dbdoc'),
);

=head1 NAME

MyApp::Model::DBDoc - Catalyst File Model

=head1 SYNOPSIS

See L<MyApp>

=head1 DESCRIPTION

L<Catalyst::Model::File> Model storing files under
L<>

=head1 AUTHOR

Michal Jurosz

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
