export DBIC_TRACE=1
#export DBIC_TRACE="1=/tmp/tt-copy-trace.out"
export CATALYST_PORT=4000
perl script/taptinder_web_server.pl -r -d
