@ECHO OFF
perl utils\wiki_schema.pl sql\schema.wiki > sql\schema.sql && type sql\schema.sql > temp\all.sql && type sql\data-base.sql >> temp\all.sql
echo sql\schema.sql and temp\all.sql updated
