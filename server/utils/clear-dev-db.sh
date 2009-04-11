clear

echo "Going to change database to clear devel version. All data will be lost."
echo "Press <Enter> to continue or <Ctrl+C> to cancel ..."
read

echo "Running utils/all-sql.sh"
./utils/all-sql.sh
echo ""

echo "Executing temp/all-dev.sql (perl utils/db-run-sqlscript.pl):"
perl ./utils/db-run-sqlscript.pl ./temp/all-dev.sql 1
echo ""

echo "Executing utils/set_client_passwd.pl --client_conf_fpath (perl):"
perl ./utils/set_client_passwd.pl --client_conf_fpath
echo ""

echo "Executing utils/set_client_passwd.pl --client_passwd_list (perl):"
perl ./utils/set_client_passwd.pl --client_passwd_list
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
