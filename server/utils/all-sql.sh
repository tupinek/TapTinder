echo -n "updating some temp/*.sql - "
perl utils/wiki_schema.pl sql/schema.wiki > temp/schema.sql 
cat temp/schema.sql > temp/all.sql 
cat sql/data-base.sql >> temp/all.sql

cat temp/all.sql > temp/all-dev.sql
cat sql/data-dev.sql >> temp/all-dev.sql

cat temp/all.sql > temp/all-stable.sql
cat sql/data-stable.sql >> temp/all-stable.sql
echo done

echo -n "updating temp/sel-tables.sql - "
perl utils/wiki_schema.pl sql/schema.wiki 0 0 0 trun > temp/sel-tables.sql && echo done


echo -n "creating temp/schema-raw-create.sql - "
perl utils/wiki_schema.pl sql/schema.wiki 0 1 0 > temp/schema-raw-create.sql && echo done

if [ ! -z "$1" ]
then
    echo -n "updating TapTinder::DB::Schema.pm - "
    perl utils/sqlt-taptinder.pl dbix temp/schema-raw-create.sql 0 && echo done
fi	


echo -n "creating temp/schema-raw-create-comments.sql - "
perl utils/wiki_schema.pl sql/schema.wiki 0 1 1 > temp/schema-raw-create-comments.sql && echo done

if [ ! -z "$1" ]
then
    echo -n "updating temp/schema.png - "
    perl utils/sqlt-taptinder.pl graph temp/schema-raw-create-comments.sql 0 && echo done
fi