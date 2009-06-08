
for ((i=1;1;i++)); do
    perl ./ttclient.pl $1
    if [ ! -f './.do_ttclient_upgrade' ]; then
        exit;
    fi
    echo "Trying to do client upgrade with 'svn up ..'."
    svn up .. || exit
    unlink './.do_ttclient_upgrade'
done
