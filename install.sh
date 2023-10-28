#!/usr/bin/env bash

set -e

MAIN_SCRIPT="$(dirname "$(readlink -f "$0")")/mccli.sh"

INSTALL_PATH=${INSTALL_PATH:-"/opt"}

LINK_PATH=${LINK_PATH:-"/usr/local/bin"}

DO_SYMLINK="false"

while getopts ':lL:' option; do
	case "$option" in 
		l) 
			DO_SYMLINK="true"
			;;
		L) 
			DO_SYMLINK="true"
			LINK_PATH="$OPTARG"
			;;
		*) 
			;;
	esac
done

if [ -v "$1" ]; then
	INSTALL_PATH="$1"
fi

if [ ! -e "$INSTALL_PATH" ]; then
	mkdir -p "$INSTALL_PATH"
fi

if [ -e "$INSTALL_PATH/mccli" ]; then
	echo "mccli: $INSTALL_PATH/mccli already exists, exiting"
	exit 1;
fi

if [ ! -v MCCLI_PYTHON ]; then
	if which python > /dev/null; then
		MCCLI_PYTHON="$(which python)";
	elif which python3 > /dev/null; then
		MCCLI_PYTHON="$(which python3)";
	else
		echo "mccli: python not found as 'python' or 'python3'"
		read -p "Enter path to Python interpreter: " MCCLI_PYTHON
	fi
fi

echo "mccli: using python at $MCCLI_PYTHON"

sed "s!##PYTHON!python_path=\"$MCCLI_PYTHON\"!" "$(dirname "$(readlink -f "$0")")/mccli.sh.template" > "$(dirname "$(readlink -f "$0")")/mccli.sh"
chmod 755 "$(dirname "$(readlink -f "$0")")/mccli.sh"


if [ "$DO_SYMLINK" = "true" ]; then
	set +e
	ln -s "$MAIN_SCRIPT" "$LINK_PATH/mccli";
	install_success="$?"
	set -e
else
	if [ -d "$INSTALL_PATH/mccli" ]; then
		echo "mccli: $INSTALL_PATH/mccli_install directory already exists, exiting"
		exit 1;
	fi
	mkdir "$INSTALL_PATH/mccli";
	set +e
	cp -r "$(dirname "$(readlink -f "$0")")/"* "$INSTALL_PATH/mccli";
	install_success="$?"
	touch "$INSTALL_PATH/mccli/.copy_install";
	if [ ! "$LINK_PATH" = "none" ]; then
		ln -s "$INSTALL_PATH/mccli/mccli.sh" "$LINK_PATH/mccli";
	fi
	set -e
fi

if [ "$install_success" -eq 0 ]; then
	echo "mccli: installed to $INSTALL_PATH/mccli"
else
	echo "mccli: install failed (attempted to install to $INSTALL_PATH/mccli)"
fi