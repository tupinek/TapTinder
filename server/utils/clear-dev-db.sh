clear

echo "Going to change database to clear devel version. All data will be lost."
echo "Press <Enter> to continue or <Ctrl+C> to cancel ..."
read

echo "Running utils/all-sql.sh"
./utils/all-sql.sh

perl ./utils/db-run-sqlscript.pl ./temp/all-devel.sql 1

perl ./utils/set_client_passwd.pl

perl ./cron/repository-update.pl -p TapTinder-tr1
perl ./cron/repository-update.pl -p TapTinder-tr2
perl ./cron/repository-update.pl -p TapTinder-tr3 

echo "done"