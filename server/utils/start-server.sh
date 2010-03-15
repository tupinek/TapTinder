#!/bin/bash

function echo_help {
cat <<USAGE_END
Usage:
  utils/start-server.sh dev|copy|prod d|dp|f

  dev ... devel
  copy ... copy of production
  prod ... production
  
  d ... http server, normal engine
  dp ... http server, Prefork::Engine
  f ... FastCGI

Example:
  utils/start-server.sh dev d
  utils/start-server.sh dev p

USAGE_END
}


if [ "$1" == "dev" ]; then
    export CATALYST_DEBUG=1
    export DBIC_TRACE=1

    if [ "$2" == "d" -o "$2" == "dp" ]; then 
        if [ "$2" = "dp" ]; then
          export CATALYST_ENGINE='HTTP::Prefork'
        fi 
        export CATALYST_PORT=2000
        perl script/taptinder_web_server.pl -r
        exit
    fi

    if [ "$2" == "f" ]; then 
        perl script/taptinder_web_fastcgi.pl -l :3000 -n 2 -p temp/ttdev.pid -d
        exit
    fi

    echo_help
    exit
fi

if [ "$1" == "copy" ]; then
    if [ "$2" == "d" -o "$2" == "dp" ]; then 
        if [ "$2" = "dp" ]; then
          export CATALYST_ENGINE='HTTP::Prefork'
        fi 
        export DBIC_TRACE=1
        export CATALYST_PORT=2000
        perl script/taptinder_web_server.pl -r -d
        exit
    fi

    if [ "$2" == "f" ]; then 
        perl script/taptinder_web_fastcgi.pl -l :4000 -n 2 -p temp/ttcopy.pid -d
        exit
    fi

    echo_help
    exit
fi


if [ "$1" == "prod" ]; then
    if [ "$2" == "d" -o "$2" == "dp" ]; then 
        if [ "$2" = "dp" ]; then
          export CATALYST_ENGINE='HTTP::Prefork'
        fi 
        export DBIC_TRACE=1
        export CATALYST_PORT=2000
        perl script/taptinder_web_server.pl -r -d
        exit
    fi

    if [ "$2" == "f" ]; then 
        perl script/taptinder_web_fastcgi.pl -l :5000 -n 2 -p temp/tt.pid -d
        exit
    fi

    echo_help
    exit
fi


echo_help
