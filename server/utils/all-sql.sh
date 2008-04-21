echo -n "updating sql/schema.sql - "
perl utils/wiki_schema.pl sql/schema.wiki > temp/schema.sql && cat temp/schema.sql > temp/all.sql && type sql/data-base.sql >> temp/all.sql && echo done

echo -n "updating temp/sel-tables.sql - "
perl utils/wiki_schema.pl sql/schema.wiki 0 0 trun > temp/sel-tables.sql && echo done

echo -n "creating temp/schema-raw-create.sql - "
perl utils/wiki_schema.pl sql/schema.wiki 0 1 > temp/schema-raw-create.sql && echo done

echo -n "updating TapTinder::DB::Schema.pm - "
perl utils/sqlt-taptinder.pl dbix temp/schema-raw-create.sql 0 && echo done

echo -n "updating temp/schema.png - "
perl utils/sqlt-taptinder.pl graph temp/schema-raw-create.sql 0 && echo done
