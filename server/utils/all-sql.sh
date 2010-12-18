echo -n "creating temp/schema-raw-create.sql - "
perl utils/wiki_schema.pl sql/schema.wiki 0 1 0 > temp/schema-raw-create.sql && echo done

if [ "$1" = "1" -o "$1" = "2" ]; then
    echo -n "updating TapTinder::DB::Schema.pm - "
    perl utils/sqlt-taptinder.pl dbix temp/schema-raw-create.sql 0 && echo done
fi


echo -n "creating temp/schema-raw-create-comments.sql - "
perl utils/wiki_schema.pl sql/schema.wiki 0 1 1 > temp/schema-raw-create-comments.sql && echo done

if [ "$1" = "2" ]; then
    echo -n "updating temp/schema.png - "
    rm -rf temp/dbdoc/*
    perl utils/sqlt-taptinder.pl dbdoc temp/schema-raw-create-comments.sql 0 && echo done
fi


echo "Executing utils/deploy --save"
perl ./utils/deploy.pl --save
echo ""
