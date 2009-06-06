=head1 NAME

Bot::BasicBot::Pluggable::Module::TapTinderBot - report status

=head1 IRC USAGE

...

=cut

package Bot::BasicBot::Pluggable::Module::TapTinderBot;
use base qw(Bot::BasicBot::Pluggable::Module);
use warnings;
use strict;

our $tick_counter = 0;

sub init {
    my $self = shift;

    $self->{loop_num} = 0;
    $self->set('user_tick', "1") unless defined ( $self->get('user_tick') );
}


sub tick {
    my $self = shift;

    my $period = $self->get('user_tick');
    my $tick_counter++;
    return if ( $tick_counter < $period);
    $tick_counter = 0;
    return $self->_check_news();
}


sub _check_news {
    my ( $self ) = @_;

    $self->{loop_num}++;
    foreach my $channel ( keys %{$self->{Bot}->{channel_data}} ) {
        $self->tell( $channel, "tick test $self->{loop_num}\n");
    }
    return $self;
}


sub help {
    return "Gives TapTinder report status.";
}


sub _db_connect {
    my ( $self, $schema ) = @_;
    $self->{schema} = $schema;
    return $self;
}



=head1 SEE ALSO

L<TapTinder>, L<Bot::BasicBot::Pluggable>

=head1 AUTHOR

Michal Jurosz <mj@mj41.cz>

=head1 LICENSE

This file is part of TapTinder. See L<TapTinder> license.

=cut

1;
