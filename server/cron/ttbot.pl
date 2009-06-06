#!perl

use strict;
use warnings;
use Carp qw(carp croak verbose);
use FindBin qw($RealBin);

use Getopt::Long;
use Pod::Usage;

use Data::Dumper;
use File::Spec::Functions;

use Bot::BasicBot::Pluggable;

use lib "$FindBin::Bin/../lib";
use TapTinder::DB;
use TapTinder::Utils::Conf qw(load_conf_multi);
use TapTinder::Utils::DB qw(get_connected_schema);


my $help = 0;
my $ver = 2;
my $irc_server_name = 'irc.freenode.org';
my $irc_channel_name = '#taptinder';
my $irc_port = 6667;
my $options_ok = GetOptions(
    'help|h|?' => \$help,
    'ver|v=i' => \$ver,
    'server=s' => \$irc_server_name,
    'channel=s' => \$irc_channel_name,
    'port=i' => \$irc_port,
);
pod2usage(1) if $help || !$options_ok;
if ( 0 ) {
    print "No machine_id, msession_id, msjob_id or trun_id selected.\n";
    pod2usage(1);
}

my $conf = load_conf_multi( undef, 'db' );
croak "Configuration for database is empty.\n" unless $conf->{db};

my $schema = get_connected_schema( $conf->{db} );


# with useful options. pass any option
# that's valid for Bot::BasicBot.
my $bot = Bot::BasicBot::Pluggable->new(
    channels => [ $irc_channel_name ],
    server   => $irc_server_name,
    port     => $irc_port,

    nick     => "ttbot",
    altnicks => ["taptinder-bot2", "taptinder-bot3", "taptinder-bot4", "taptinder-bot5" ],
    username => "mj41",
    name     => "TapTinder bot.",

    #ignore_list => [qw(hitherto blech muttley)],
);

$bot->load("Auth");
$bot->load("Loader");
$bot->load("TapTinderBot");

my $TapTinderBot_handler = $bot->handler("TapTinderBot");
$TapTinderBot_handler->_db_connect($schema);

$bot->run();

__END__

=head1 NAME

ttbot - Start TapTinder bot.

=head1 SYNOPSIS

perl ttbot.pl [options]

Example:
    perl ttbot.pl --server irc.freenode.org --channel TapTinderBot-test

 Options:
   --help
   --ver .. Verbosity level.
   --server
   --channel
   --port

=head1 DESCRIPTION

B<This program> will start ...

=cut
