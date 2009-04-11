for ((i=1;1;i++)); do
echo "Run number: " $i
date
echo ""
nice -n 10 perl repository-update.pl -p Parrot
echo "Sleeping for 30 s ..."
sleep 30
echo ""
echo ""
done
