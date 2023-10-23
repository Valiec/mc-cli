#!/usr/bin/env bash

set -e

MAIN_SCRIPT="$(dirname "$(readlink -f "$0")")/mccli.sh"

INSTALL_PATH="/usr/local/bin"

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

set +e
ln -s "$MAIN_SCRIPT" "$INSTALL_PATH/mccli";
install_success="$?"
set -e

if [ "$install_success" -eq 0 ]; then
	echo "mccli: installed to $INSTALL_PATH/mccli"
else
	echo "mccli: install failed (attempted to install to $INSTALL_PATH/mccli)"
fi