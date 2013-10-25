package TapTinder::Utils::Conf;

# ABSTRACT: TapTinder utilities for config file processing.

use strict;
use warnings;
use Carp qw(carp croak verbose);

use base 'Exporter';
our @EXPORT = qw(load_conf_multi);

use Config::Multi;
use File::Spec::Functions;


=func load_conf_multi

Use same way as to load config as TapTinder::Web and then delete all but required parts (keys).

=cut

sub load_conf_multi {
    my ( $cm_dir, @keys ) = @_;

    $cm_dir = catfile( $FindBin::Bin , '..', 'conf' ) unless defined $cm_dir;

    my $cm = Config::Multi->new({
         dir => $cm_dir,
         prefix => '',
         app_name => 'web',
         extension => 'yml',
    });
    my $conf = $cm->load();
    my %keys = map { $_ => 1 } @keys;
    foreach my $key ( keys %$conf ) {
        unless ( exists $keys{$key} ) {
            delete $conf->{$key};
        }
    }

    return $conf;
}

1;