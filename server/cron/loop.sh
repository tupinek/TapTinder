for ((i=1;1;i++)); do
echo "Run number: " $i
date
echo ""

echo "Repository update:"
nice -n 10 perl repository-update.pl --project=Parrot
echo ""

echo "Tests to DB:"
nice -n 10 perl tests-to-db.pl
echo ""

echo "Sleeping for 30 s ..."

sleep 30
echo ""
echo ""
done
