for ((i=1;1;i++)); do
echo "Run number: " $i
date
echo ""
nice -n 10 perl repository-update.pl && nice -n 10 perl tests-to-db.pl 
echo "Sleeping for 300 s ..."
sleep 300
echo ""
echo ""
done
