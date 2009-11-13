rm -rf ./nytprof/
mkdir ./nytprof/

export -u NYTPROF
export -u DBIC_TRACE
perl ./utils/profile.pl 1 > ./nytprof/profile-out.txt

cp ./utils/profile.pl ./nytprof/profile.pl.txt
cp ./utils/profile.sh ./nytprof/profile.sh.txt

export DBIC_TRACE="1=/tmp/tt-profile.out"
export NYTPROF=trace=3:start=no
perl -d:NYTProf ./utils/profile.pl 2>&1 1>nytprof-cmd-out.txt

cp /tmp/tt-profile.out ./nytprof/dbictrace.txt

cp ./nytprof.out ./nytprof/

nytprofhtml



