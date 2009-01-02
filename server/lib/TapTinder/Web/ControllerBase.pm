package TapTinder::Web::ControllerBase;

use strict;
use warnings;
use base 'Catalyst::Controller::BindLex';

use Data::Page::HTML qw();
use DBIx::Dumper qw();

=head1 NAME

TapTinder::Web::Controller::Report - Catalyst Controller

=head1 DESCRIPTION

Base class for some TapTinder::Web::Controller::*.

=head1 METHODS

=cut

sub dadd {
    my $self = shift;
    my $c = shift;
    my $str = shift;
    $c->stash->{ot} .= $str;
}


sub dumper {
    my $self = shift;
    my $c = shift;
    #return unless $c->log->is_debug;
    $c->stash->{ot} .= DBIx::Dumper::Dumper( @_ );
}


sub get_projname_params {
    my ( $self, $c, $p_project, $par1, $par2 ) = @_;


    my $is_index = 0;
    my $project_name = undef;
    my $params;

    $is_index = 1 if !$p_project; # project list
    # project name found
    if ( $p_project ) {
        $project_name = $p_project;
        $project_name =~ s{^pr-}{};
        $c->stash->{project_name} = $project_name;
    }
    $c->stash->{project_uri} = $c->uri_for( $c->action->namespace . '/pr-'.$project_name.'/' );

    # project name, nothing else
    if ( !$par1 ) {
        $is_index = 1;
    # project name and parameters
    } elsif ( $par1 =~ /^(page|rows|offset)\-/ ) {
        $params = $par1;
        $is_index = 1;
    # probably rep_path name
    } else {
        $params = $par2 if $par2;
    }

    $self->dumper( $c, { p_project => $p_project, par1 => $par1, par2 => $par2 } );
    $self->dumper( $c, { is_index => $is_index, project_name => $project_name, params => $params } );

    return ( $is_index, $project_name, $params );
}


sub get_page_params {
    my ( $self, $params ) = @_;

    # default page listing values
    my $pr = {
        page => 1,
    };
    if ( $params ) {
        # try to set page, rows, ... values from url params
        my @parts = split( ',', $params );
        foreach my $part ( @parts ) {
            if ( $part =~ m/^ page-(\d+) $/x ) {
                $pr->{page} = $1;
                next;
            }
            if ( $part =~ m/^ (rows|offset)-(\d+) $/x ) {
                $pr->{$1} = $2;
                next;
            }
        }
        $pr->{page} = 1 if $pr->{page} < 1;
    }
    return $pr;
}


sub get_pager_html {
    my $self = shift;
    return Data::Page::HTML::get_pager_html( @_ );
}


=head1 SEE ALSO

L<TapTinder::Web>, L<Catalyst::Controller>

=head1 AUTHOR

Michal Jurosz <mj@mj41.cz>

=head1 LICENSE

This file is part of TapTinder. See L<TapTinder> license.

=cut


1;
