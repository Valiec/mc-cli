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
	echo "mccli installer: $INSTALL_PATH/mccli already exists, exiting"
	exit 1;
fi

if which python > /dev/null; then
	MCCLI_PYTHON="$(which python)";
elif which python3 > /dev/null; then
	MCCLI_PYTHON="$(which python3)";
else
	echo "mccli: python not found as 'python' or 'python3'"
	read -p "Enter path to Python interpreter: " MCCLI_PYTHON
fi

echo "mccli: using python at $MCCLI_PYTHON"

echo "Installing to $INSTALL_PATH/mccli"

sed "s!##PYTHON!export MCCLI_PYTHON=$MCCLI_PYTHON!" "$(dirname "$(readlink -f "$0")")/mccli.sh.template" > "$(dirname "$(readlink -f "$0")")/mccli.sh"
chmod 755 "$(dirname "$(readlink -f "$0")")/mccli.sh"

set +e
ln -s "$MAIN_SCRIPT" "$INSTALL_PATH/mccli";
install_success="$?"
set -e

if [ "$install_success" -eq 0 ]; then
	echo "Installed"
else
	echo "Install failed"
fi