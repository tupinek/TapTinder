clear

function echo_help {
cat <<USAGE_END
Usage:
  utils/clear-dev-db.sh c|l [u|uu] [ld]

  c ... create fresh
  l ... load data from temp/ttdev-dump.sql

  u ... update schema files
  uu ... update schema files, upgrade schema
  
  ld ... load default repositories
  
Example:
  utils/clear-dev-db.sh c 
  utils/clear-dev-db.sh c uu ld

USAGE_END
}


if [ -z "$1" ]; then
    echo_help
    exit
fi


if [ "$1" = "l" ]; then
    echo "Going to rewrite database from dump. All new data will be lost."
    echo "Press <Enter> to continue or <Ctrl+C> to cancel ..."
    read

    if [ "$2" = "u" ]; then
        echo "Running utils/all-sql.sh 1"
        ./utils/all-sql.sh 1
        echo ""
    fi
    if [ "$2" = "uu" ]; then
        echo "Running utils/all-sql.sh 2"
        ./utils/all-sql.sh 2
        echo ""
    fi

    echo "Loading DB dump temp/tt-dump.sql (perl utils/db-run-sqlscript.pl ...):"
    perl ./utils/db-run-sqlscript.pl ./temp/ttdev-dump.sql 1
    echo ""

    echo "Executing utils/set_client_passwd.pl --client_conf_fpath (perl):"
    perl ./utils/set_client_passwd.pl --client_conf_fpath
    echo ""

    echo "Executing utils/set_client_passwd.pl --client_passwd_list (perl):"
    perl ./utils/set_client_passwd.pl --client_passwd_list
    echo ""

    if [ "$2" = "1" -o "$2" = "2" ]; then
        echo "Creating temp/schema-diff.sql:"
        sqlt-diff ./temp/schema-raw-create-dump.sql=MySQL temp/schema-raw-create.sql=MySQL > ./temp/schema-diff.sql
        echo ""

        echo "Executing temp/schema-diff.sql (perl utils/db-run-sqlscript.pl ...):"
        perl ./utils/db-run-sqlscript.pl ./temp/schema-diff.sql 1
        echo ""
    fi
fi

if [ "$1" = "c" ]; then

    echo "Going to change database to clear devel version. All data will be lost."
    echo "Press <Enter> to continue or <Ctrl+C> to cancel ..."
    read

    if [ "$2" = "u" ]; then
        echo "Running utils/all-sql.sh 1"
        ./utils/all-sql.sh 1
        echo ""
    fi
    if [ "$2" = "uu" ]; then
        echo "Running utils/all-sql.sh 2"
        ./utils/all-sql.sh 2
        echo ""
    fi

    echo "Executing utils/deploy --drop --deploy --data=dev"
    perl ./utils/deploy.pl --drop --deploy --data=dev
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

    echo "Executing utils/rm_uploaded_files.pl --remove (perl):"
    perl ./utils/rm_uploaded_files.pl --remove
    echo ""

    if [ "$3" = "ld" ]; then
        echo "Executing cron/repository-update.pl -p TapTinder-tr1 (perl):"
        perl ./cron/repository-update.pl --project=TapTinder-tr1
        echo ""
        echo "Executing cron/repository-update.pl -p TapTinder-tr3 (perl):"
        perl ./cron/repository-update.pl --project=TapTinder-tr2
        echo ""
        echo "Executing cron/repository-update.pl -p TapTinder-tr3 (perl):"
        perl ./cron/repository-update.pl --project=TapTinder-tr3
        echo "";
    fi
fi

echo "Done."
