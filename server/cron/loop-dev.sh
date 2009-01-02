for ((i=1;1;i++)); do
echo "Run number: " $i
date
echo ""
nice -n 10 perl repository-update.pl -p TapTinder-tr1
nice -n 10 perl repository-update.pl -p TapTinder-tr2
nice -n 10 perl repository-update.pl -p TapTinder-tr3
echo "Sleeping for 300 s ..."
sleep 300
echo ""
echo ""
done
