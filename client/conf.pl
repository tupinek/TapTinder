use strict;
my $make_cmd;

my ( $conf_cmd );
if ( $^O eq 'MSWin32' ) {
    my $rc = system( "mingw32-make --version > nul" );
    if ( $rc == 0 ) {
        $make_cmd = 'mingw32-make';
    } else {
        $make_cmd = 'nmake';
    }
    if ( -e '\usr\lib\icu' ) {
        $conf_cmd = 'perl Configure.pl --cc=gcc --icushared="c:\usr\lib\icu\lib\icudt.lib c:\usr\lib\icu\lib\icuuc.lib" --icuheaders="c:\usr\lib\icu\include" --icudatadir="c:\usr\lib\icu\data"';
    } else {
        $conf_cmd = 'perl Configure.pl --cc=gcc --without-icu';
    }
} else {
    $make_cmd = 'make';
    $conf_cmd = 'perl Configure.pl';
}


my $conf = [];

# Defaults:
# $req_ok = $cmd[-1]
# $name = $cmd

push @$conf, {
    'name' => 'parrot',
    'after_temp_copied' => sub {
        my ( $cn, $state, $ver ) = @_;
        unless ( -d $cn->{src_add_dn} ) {
            print "src_add dir '$cn->{src_add_dn}' not found!\n" if $ver > 1;
            return 0;
        }
        unless ( copy( $cn->{src_add_dn} . '/harnessnew', $cn->{temp_dn}.'/t/' ) ) {
            print "Cant't copy 'harnessnew' $!\n" if $ver > 1;
            return 0;
        }
        return 1;
    },

    'commands' => [
        { 
            'name' => 'configure',
            'cmd' => $conf_cmd,
            'mt' => 10*60,
        },
        { 
            'name' => 'make',
            'cmd' => $make_cmd,
            'mt'  => 1*60*60,
        },
        { 
            'name' => 'harnessnew',
            'cmd'  => 'perl t/harnessnew --yaml',
            'mt'  => 30*60,
            'after'  => sub {
                my ( $cn, $state, $ver ) = @_;
                my $rc = copy( 
                    'taptinder-results.yaml',  
                    catfile($state->{results_path_prefix}, 'taptinder-results.yaml')
                );
                print 'ERROR: ' . $! unless $rc;
                print "make smoke - after return code: $rc\n" if $ver > 1;
                return $rc;
            },
        },
        { 
            'name' => 'sending to server',
            'cmd' => 
                'perl ' . catfile( $RealBin, 'upload.pl' )
                . ' parrot'
                . ' taptinder-results.yaml'
                . ' ' . catfile( $RealBin, '..', 'client-conf', 'client-conf.yaml' )
            ,
            'mt'  => 10*60,
        },
    ]
};

return $conf;
