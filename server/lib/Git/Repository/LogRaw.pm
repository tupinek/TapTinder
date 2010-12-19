package Git::Repository::LogRaw;

use strict;
use warnings;
use Data::Dumper;

sub new {
    my ( $class, $repo, $verbose_level ) = @_;

    my $self = {};
    $self->{repo} = $repo;
    $self->{ver} = 2;
    $self->{ver} = $verbose_level if defined $verbose_level;
    $self->{err_msg} = undef;

    if ( $self->{ver} >= 4 ) {
        # todo
        #require 'Data::Dumper';
    }
    
    bless $self, $class;
    return $self;
}


sub parse_item_log_line {
    my ( $self, $line ) = @_;

    my $colons = undef;
    unless ( ($colons) = $line =~ m/^(\:+)/g ) {
        return "Colons not found on begin of line";
    }
    
    my $last_pnum = length( $colons ) - 1;

    my $item_info = {
        name => undef,
        mode => undef,
        hash => undef,
        parents => [],
    };

    foreach my $pnum (0..$last_pnum) {
        push @{$item_info->{parents}}, {
            mode => undef,
            hash => undef,
            status => undef,
        };
    }

    my $val;

    # mode
    foreach my $pnum (0..$last_pnum) {
        unless ( ($val) = $line =~ m/ ([0-7]{6})/g ) {
            return "Mode for parent number ".($pnum+1)." not found";
        }
        $item_info->{parents}->[ $pnum ]->{mode} = $val;
    }
    unless ( ($val) = $line =~ m/ ([0-7]{6})/g ) {
        return "Mode for new item not found";
    }
    $item_info->{mode} = $val;

    # hash
    foreach my $pnum (0..$last_pnum) {
        unless ( ($val) = $line =~ m/ ([0-9a-f]{40})/g ) {
            return "Hash for parent number ".($pnum+1)." not found";
        }
        $item_info->{parents}->[$pnum]->{hash} = $val;
    }
    unless ( ($val) = $line =~ m/ ([0-9a-f]{40})/g ) {
        return "Hash for new item not found";
    }
    $item_info->{hash} = $val;

    # status
    foreach my $pnum (0..$last_pnum) {
        unless ( ($val) = $line =~ m/ ([MAD])/g ) {
            return "Status (change char) parent number ".($pnum+1)." not found";
        }
        $item_info->{parents}->[$pnum]->{status} = $val;
    }

    # name
    unless ( ($val) = $line =~ m/\t(.+)$/g ) {
        return "Name not found";
    }
    $item_info->{name} = $val;


    #print Dumper( $item_info );
    return $item_info; 
}


sub parse_person_log_line_part {
    my ( $self, $line_part ) = @_;

    if ( my ($name, $email, $lc_time, $timezone, $ts_mark, $ts_hour_offset, $ts_min_offset) = $line_part =~ /(.*) <(.*)> ([0-9]+) (([-+])([0-9]{2})([0-9]{2}))/ ) {
        my $gmtime = $lc_time + ( $ts_mark eq '-' ? -1 : 1 ) * ( $ts_hour_offset * 3600 + $ts_min_offset * 60 );
        return ( 1, $name, $email, $timezone, $gmtime );
    }

    return ( 0, "Error parsing '$line_part'" );
}


sub get_log {
    my ( $self ) = @_;
    
    my $cmd = $self->{repo}->command( 'log' => '--reverse', '--all', '--pretty=raw', '--raw', '-c', '-t', '--root', '--abbrev=40', '--raw' );
    print "LogRaw cmdline: '" . join(' ', $cmd->cmdline() ) . "'\n" if $self->{ver} >= 3;

    
    my $line_num = 0;
    my $log = [];
    my $ac_state = 'begin';
    my $commit = undef;
    my $err_msg = undef;

    my $out_fh = $cmd->stdout;
    PARSE_LOG: while ( my $line = <$out_fh> ) {
        $line_num++;
        chomp $line;
        printf( "%3d (prev %10s): '%s'\n", $line_num, $ac_state, $line ) if $self->{ver} >= 3;

        # commit 1x
        if ( my ( $commit_hash ) = $line =~ /^commit ([0-9a-f]{40})$/ ) {
            if ( defined $commit ) {
                print Dumper( $commit ) if $self->{ver} >= 4;
                push @$log, $commit;
            }


            if ( $ac_state ne 'begin' && $ac_state ne 'empty_ca' && $ac_state ne 'empty_af' ) {
                $err_msg = "Found 'commit' type line after '$ac_state'.";
                last PARSE_LOG; 
            }
            $commit = {
                commit => $commit_hash,
                tree => undef,
                parents => [],
                author => {
                    name => undef,
                    email => undef,
                    timezone => undef,
                    gmtime => undef,
                },
                committer => {
                    name => undef,
                    email => undef,
                    timezone => undef,
                    gmtime => undef,
                },
                msg => undef,
                items => [],
            };
            $ac_state = 'commit';
            next;
        }

        # tree 1x
        if ( my ( $tree ) = $line =~ /^tree ([0-9a-f]{40})$/ ) {
            if ( $ac_state ne 'commit' ) {
                $err_msg = "Found 'tree' type line after '$ac_state'.";
                last PARSE_LOG; 
            }
            $commit->{tree} = $tree;
            $ac_state = 'tree';
            next;
        }

        # parent 0+x
        if ( my ( $parent ) = $line =~ /^parent ([0-9a-f]{40})$/ ) {
            if ( $ac_state ne 'tree' && $ac_state ne 'parent' ) {
                $err_msg = "Found 'parent' type line after '$ac_state'.";
                last PARSE_LOG; 
            }
            push @{$commit->{parents}}, $parent;
            $ac_state = 'parent';
            next;
        }

        # author 1x
        if ( my ( $person_raw ) = $line =~ /^author (.*)$/ ) {
            if ( $ac_state ne 'parent' && $ac_state ne 'tree' ) {
                $err_msg = "Found 'author' type line after '$ac_state'.";
                last PARSE_LOG; 
            }
            my ( $status, $name, $email, $timezone, $gmtime ) = $self->parse_person_log_line_part( $person_raw );
            if ( $status != 1 ) {
                $err_msg = "Committer line error. $name.";
                last PARSE_LOG;
            }
            $commit->{author}->{name} = $name;
            $commit->{author}->{email} = $email;
            $commit->{author}->{timezone} = $timezone;
            $commit->{author}->{gmtime} = $gmtime;
            $ac_state = 'author';
            next;
        }

        # committer 1x
        if ( my ( $person_raw ) = $line =~ /^committer (.*)$/ ) {
            if ( $ac_state ne 'author' ) {
                $err_msg = "Found 'committer' type line after '$ac_state'.";
                last PARSE_LOG; 
            }
            my ( $status, $name, $email, $timezone, $gmtime ) = $self->parse_person_log_line_part( $person_raw );
            if ( $status != 1 ) {
                $err_msg = "Committer line error. $name.";
                last PARSE_LOG;
            }
            $commit->{committer}->{name} = $name;
            $commit->{committer}->{email} = $email;
            $commit->{committer}->{timezone} = $timezone;
            $commit->{committer}->{gmtime} = $gmtime;
            $ac_state = 'committer';
            next;
        }

        # empty lines - 1x each type
        if ( $line eq '' ) {
            # empty_cb
            if ( $ac_state eq 'committer' ) {
                $ac_state = 'empty_cb';
                next;
            }
            # empty_ca
            if ( $ac_state eq 'msg' ) {
                $ac_state = 'empty_ca';
                next;
            }
            # empty_af
            if ( $ac_state eq 'item' || $ac_state eq 'empty_ca' ) {
                $ac_state = 'empty_af';
                next;
            }
            $err_msg = "Found empty line after '$ac_state'";
            last PARSE_LOG;
        }
        
        # msg/msg line - 1+x
        if ( my ( $msg_line ) = $line =~ /^ {4}(.*)$/ ) {
            if ( $ac_state ne 'empty_cb' && $ac_state ne 'msg' ) {
                $err_msg = "Found 'msg' type line after '$ac_state'.";
                last PARSE_LOG; 
            }
            $commit->{msg} .= "\n" if $commit->{msg};
            $commit->{msg} .= $msg_line;
            $ac_state = 'msg';
            next;
        }
        
        # empty_ca 1x - code is above

        # items 0+x
        if ( $line =~ /^\:+/ ) {
            my $item_info = $self->parse_item_log_line( $line );
            if ( ref $item_info ne 'HASH' ) {
                $err_msg = "Item line error. $item_info.";
                last PARSE_LOG;
            }
            push @{$commit->{items}}, $item_info;
            $ac_state = 'item';
            next;
        }

        # empty_af 1x - code is above

        # error
        $err_msg = "Can't determine line type";
        last PARSE_LOG;
    }
    
    if ( $err_msg ) {
        print "Parsing error on line $line_num: $err_msg\n";
    }

    my $err = $cmd->stderr(); 
    my $err_out = do { local $/; <$err> };
    if ( $err_out ) {
        $self->{err_msg} = "Error:\n  $err_out\n" . $err_msg;
        print $self->{err_msg} if $self->{ver} >= 2;
        return undef;
    }
    if ( $err_msg ) {
        $self->{err_msg} = $err_msg;
        print $self->{err_msg} if $self->{ver} >= 2;
        return undef;
    }

    print Dumper( $commit ) if $self->{ver} >= 4;
    push @$log, $commit;

    $cmd->close;
    return $log;
}


sub get_err_msg {
    my ( $self ) = @_;
    return $self->{err_msg};
}



sub get_refs {
    my ( $self, $type ) = @_;
    
    my $cmd;
    if ( defined $type ) {
        $cmd = $self->{repo}->command( 'for-each-ref' => $type );
    } else {
        $cmd = $self->{repo}->command( 'for-each-ref' );
    }
    print "LogRaw cmdline: '" . join(' ', $cmd->cmdline() ) . "'\n" if $self->{ver} >= 3;

    
    my $line_num = 0;
    my $refs = {};
    my $err_msg = undef;

    my $out_fh = $cmd->stdout;
    PARSE_REF: while ( my $line = <$out_fh> ) {
        $line_num++;
        chomp $line;
        printf( "%3d: '%s'\n", $line_num, $line ) if $self->{ver} >= 3;

        if ( my ( $sha, $sha_type, $tag_name ) = $line =~ /^([0-9a-f]{40})\ (commit|tag)\t(.*)$/ ) {
            if ( my ( $name_prefix, $name_base ) = $tag_name =~ /^([^\/]+\/[^\/]+)\/(.*)$/ ) {
                my $ref_info = {
                    sha => $sha,
                    sha_type => $sha_type,
                    prefix => $name_prefix,
                };
                if ( $name_prefix eq 'refs/remotes' ) {
                    if ( my ( $repo_alias, $branch_name ) = $name_base =~ /^([^\/]+)\/(.*)$/ ) {
                        $ref_info->{type} = 'remote_ref';
                        $ref_info->{repo_alias} = $repo_alias;
                        $ref_info->{branch_name} = $branch_name;
                    } else {
                        $err_msg = "Can't split refs/remote to repo_alias and branch_name";
                        last PARSE_REF;
                    }
                } elsif ( $name_prefix eq 'refs/tags' ) {
                    $ref_info->{type} = 'tag';
                    $ref_info->{tag_name} = $name_base;
                    
                } elsif ( $name_prefix eq 'refs/heads' ) {
                    $ref_info->{type} = 'local_ref';
                    $ref_info->{ref_name} = $name_base;

                } else {
                    $ref_info->{type} = 'unknown';
                    $ref_info->{name_base} = $name_base;
                }

                $refs->{ $tag_name } = $ref_info;
            
            } else {
                $err_msg = "Can't split ref name '$tag_name' to parts";
                last PARSE_REF;
            }
            next;
        }

        # error
        $err_msg = "Can't parse line";
        last PARSE_REF;
    }
    
    if ( $err_msg ) {
        print "Parsing error on line $line_num: $err_msg\n";
    }

    my $err = $cmd->stderr(); 
    my $err_out = do { local $/; <$err> };
    if ( $err_out ) {
        $self->{err_msg} = "Error:\n  $err_out\n" . $err_msg;
        print $self->{err_msg} if $self->{ver} >= 2;
        return undef;
    }
    if ( $err_msg ) {
        $self->{err_msg} = $err_msg;
        print $self->{err_msg} if $self->{ver} >= 2;
        return undef;
    }

    $cmd->close;
    return $refs;
}


1;
