export DBIC_TRACE=1
export NYTPROF=trace=3:start=no
perl -d:NYTProf utils/profile.pl
rm -rf ./nytprof/
nytprofhtml

