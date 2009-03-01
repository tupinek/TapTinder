clear

echo "Going to change database to clear devel version. All data will be lost."
echo "Press <Enter> to continue or <Ctrl+C> to cancel ..."
read

echo "Running utils/all-sql.sh"
./utils/all-sql.sh
echo ""

echo "Executing temp/all-devel.sql (perl utils/db-run-sqlscript.pl):"
perl ./utils/db-run-sqlscript.pl ./temp/all-devel.sql 1
echo ""

echo "Executing utils/set_client_passwd.pl (perl):"
perl ./utils/set_client_passwd.pl
echo ""

echo "Executing cron/repository-update.pl -p TapTinder-tr1 (perl):"
perl ./cron/repository-update.pl -p TapTinder-tr1
echo ""
echo "Executing cron/repository-update.pl -p TapTinder-tr3 (perl):"
perl ./cron/repository-update.pl -p TapTinder-tr2
echo ""
echo "Executing cron/repository-update.pl -p TapTinder-tr3 (perl):"
perl ./cron/repository-update.pl -p TapTinder-tr3 
echo "";

echo "Executing utils/rm_uploaded_files.pl --remove (perl):"
perl ./utils/rm_uploaded_files.pl --remove
echo ""

echo "Done."
