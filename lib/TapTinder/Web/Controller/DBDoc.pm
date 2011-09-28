package TapTinder::Web::Controller::DBDoc;

use strict;
use warnings;
use base 'TapTinder::Web::ControllerBase';

=head1 NAME

TapTinder::Web::Controller::DBDoc - Catalyst Controller

=head1 DESCRIPTION

Catalyst controller for TapTinder. Shows static documentation files.

=head1 METHODS

=head2 index

=cut

sub index : Args(0)  {
    my ( $self, $c ) = @_;

    my @items = $c->model('DBDoc')->list( mode => 'both' );

    my $content = '';
    my $prefix = 'root/dbdoc/';
    my $full_path = TapTinder::Web->path_to($prefix);

    my $prev_dir = '';
    foreach my $item ( @items ) {
        my $name = substr( $item, length($prefix) );
        my ( $dir, $fname ) = $name =~ /^(?:(.*)\/)?([^\/]+)$/;
        if ( $dir ne $prev_dir ) {
            $content .= "</ul>\n" if $prev_dir;
            $content .= "<h2>$dir</h2>";
            $content .= "<ul>\n";
            $prev_dir = $dir;
        }
        if ( -f $full_path.'/'.$name ) {
            $content .= '<li><a href="' . $c->uri_for($name) . '">' . $fname . "</a></li>\n";
        }
        #$content .= $full_path.'/'.$name . '<br>';
    }

    $c->stash->{content} = $content;

    return 1;
}



=head1 SEE ALSO

L<TapTinder::Web>, L<Catalyst::Controller>

=head1 AUTHOR

Michal Jurosz <mj@mj41.cz>

=head1 LICENSE

This file is part of TapTinder. See L<TapTinder> license.

=cut


1;
