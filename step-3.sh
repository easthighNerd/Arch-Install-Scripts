echo 'Enter the name for your user account'
read ARCHIE
case "$ARCHIE" in
	*);;
esac

useradd --create-home $ARCHIE && passwd $ARCHIE && gpasswd --add $ARCHIE wheel

EDITOR=nano visudo

if [ -e ./step-3.sh ]; then
	rm ./step-3.sh
fi

exit