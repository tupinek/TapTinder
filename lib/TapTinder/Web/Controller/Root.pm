package TapTinder::Web::Controller::Root;

# ABSTRACT: TapTinder::Web root controller.

use base 'Catalyst::Controller';
use strict;
use warnings;


# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in Web.pm

__PACKAGE__->config->{namespace} = '';


=head1 DESCRIPTION

TapTinder root path action.

=method default

=cut

sub homepage :Path :Args(0) {
    my ( $self, $c ) = @_;

    $c->stash->{template} =  'index.tt2';
}

=method end

Attempt to render a view, if needed.

=cut

sub end : ActionClass('RenderView') {}


=head1 SEE ALSO

L<TapTinder::Web>, L<Catalyst::Controller>

=cut


1;
