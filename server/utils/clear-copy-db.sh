clear

echo "Going to rewrite this database by another one:"
echo "Press <Enter> to continue or <Ctrl+C> to cancel ..."
read

echo "Rewriting DB (perl utils/db-rewrite.pl):"
perl ./utils/db-rewrite.pl
echo ""

echo "Executing utils/set_client_passwd.pl --client_conf_fpath (perl):"
perl ./utils/set_client_passwd.pl --client_conf_fpath
echo ""

echo "Executing utils/set_client_passwd.pl --client_passwd_list (perl):"
perl ./utils/set_client_passwd.pl --client_passwd_list
echo ""

echo "Add new upload paths.";

echo "Done."
