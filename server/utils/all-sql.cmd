@ECHO OFF
echo Old version.
exit 1;

echo updating sql\schema.sql and temp\all.sql ...
perl utils\wiki_schema.pl sql\schema.wiki > temp\schema.sql && type temp\schema.sql > temp\all.sql && type sql\data-base.sql >> temp\all.sql && echo done
echo temp\sel-tables.sql (with trun table) ...
perl utils\wiki_schema.pl sql\schema.wiki 0 0 0 trun > temp\sel-tables.sql && echo done
