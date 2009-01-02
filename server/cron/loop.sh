for ((i=1;1;i++)); do
echo "Run number: " $i
date
echo ""
nice -n 10 perl repository-update.pl Parrot && nice -n 10 perl tests-to-db.pl /tmp/taptinder/upload
echo "Sleeping for 300 s ..."
sleep 300
echo ""
echo ""
done
