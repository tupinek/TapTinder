clear

if [ -z "$1" ]; then
    echo "Help:"
    echo "  clear-copy-dh.sh 1   ... rewrite stable to copy"
    echo "  clear-copy-dh.sh 1 2 ... rewrite stable to copy, update schema files, upgrade schema"
    echo "  clear-copy-dh.sh 0   ... create fresh db for Parrot testing"
    echo "  clear-copy-dh.sh 0 2 ... create fresh db for Parrot testing, update schema files"
    exit
fi


if [ "$1" = "1" ]; then
    echo "Going to rewrite this database by another one:"
    echo "Press <Enter> to continue or <Ctrl+C> to cancel ..."
    read

    if [ "$2" = "1" -o "$2" = "2" ]; then
        echo "Running utils/all-sql.sh"
        ./utils/all-sql.sh $2
        echo ""
    fi

    echo "Dumping DB (perl utils/db-dump.pl ... ):"
    perl ./utils/db-dump.pl ./../../tt/server/conf/web_db.yml
    echo ""

    echo "Loading DB dump temp/tt-dump.sql (perl utils/db-run-sqlscript.pl ...):"
    perl ./utils/db-run-sqlscript.pl ./temp/tt-dump.sql 1
    echo ""

    echo "Executing utils/set_client_passwd.pl --client_conf_fpath (perl):"
    perl ./utils/set_client_passwd.pl --client_conf_fpath
    echo ""

    echo "Executing utils/set_client_passwd.pl --client_passwd_list (perl):"
    perl ./utils/set_client_passwd.pl --client_passwd_list
    echo ""

    if [ "$2" = "1" -o "$2" = "2" ]; then
        echo "Updating temp/ttcopy-online-schema.sql:"
        perl ./utils/db-schema-get.pl
        echo ""

        echo "Creating temp/schema-diff.sql:"
        sqlt-diff ./temp/ttcopy-online-schema.sql=MySQL temp/schema-raw-create.sql=MySQL > ./temp/schema-diff.sql
        echo ""

        echo "Executing temp/schema-diff.sql (perl utils/db-run-sqlscript.pl ...):"
        perl ./utils/db-run-sqlscript.pl ./temp/schema-diff.sql 1
        echo ""
    fi

    echo "Executing sql/data-after-copied.sql (perl utils/db-run-sqlscript.pl):"
    perl ./utils/db-run-sqlscript.pl ./sql/data-after-copied.sql 1
    echo ""

    echo "Executing utils/rm_uploaded_files.pl --remove --fspath_ids=3,4 (perl):"
    perl ./utils/rm_uploaded_files.pl --remove --fspath_ids=3,4
    echo ""

fi


if [ "$1" = "0" ]; then
    echo "Going to create fresh database (product repository):"
    echo "Press <Enter> to continue or <Ctrl+C> to cancel ..."
    read

    echo "Running utils/all-sql.sh"
    ./utils/all-sql.sh $2
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

    echo "Dumping and loading rep data:"
    ./utils/reptables-dump.sh
    cp ./temp/tables-dump.sql ./temp/reptables-dump.sql
    ./utils/reptables-load.sh
    echo ""

    echo "Executing sql/data-after-copied.sql (perl utils/db-run-sqlscript.pl):"
    perl ./utils/db-run-sqlscript.pl ./sql/data-after-copied.sql 1
    echo ""

    echo "Executing utils/rm_uploaded_files.pl --remove --fspath_ids=3,4 (perl):"
    perl ./utils/rm_uploaded_files.pl --remove --fspath_ids=3,4
    echo ""
fi

echo "Done."
