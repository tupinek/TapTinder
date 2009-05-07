clear

echo "Going to change database to clear devel version. All data will be lost."
echo "Press <Enter> to continue or <Ctrl+C> to cancel ..."
read

echo "Are you sure? This is live productive version."
echo "Before you start:"
echo "* Stop all repository update loops."
echo ""
echo "This will be stoped automaticaly:"
echo "* httpd service"
echo ""
echo "Press <Enter> to continue or <Ctrl+C> to cancel ..."
read

echo "Stoping httpd service:"
service httpd stop
echo ""

echo "Running utils/all-sql.sh"
./utils/all-sql.sh $1
echo ""

echo "Executing temp/all-stable.sql (perl utils/db-run-sqlscript.pl):"
perl ./utils/db-run-sqlscript.pl ./temp/all-stable.sql 1
echo ""

echo "Copying temp/schema-raw-create.sql to temp/schema-raw-create-dump.sql"
cp ./temp/schema-raw-create.sql ./temp/schema-raw-create-dump.sql
echo ""

echo "Executing utils/set_client_passwd.pl --client_conf_fpath (perl):"
perl ./utils/set_client_passwd.pl --client_conf_fpath
echo ""

echo "Executing utils/set_client_passwd.pl --client_passwd_list (perl):"
perl ./utils/set_client_passwd.pl --client_passwd_list
echo ""

echo "Executing utils/reptable-load.sh:"
./utils/reptables-load.sh
echo ""

echo "Executing cron/repository-update.pl --project=Parrot (perl):"
perl ./cron/repository-update.pl --project=Parrot
echo ""

echo "Executing utils/rm_uploaded_files.pl --remove (perl):"
perl ./utils/rm_uploaded_files.pl --remove
echo ""

echo "Starting httpd service:"
service httpd start
echo ""

echo "Done."
