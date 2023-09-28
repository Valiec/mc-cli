#!/usr/bin/env bash

set -e

MAIN_SCRIPT="$(dirname "$(readlink -f "$0")")/mccli.sh"

INSTALL_PATH="/usr/local/bin"

if [ -v "$1" ]; then
	INSTALL_PATH="$1"
fi

if [ ! -a "$INSTALL_PATH" ]; then
	mkdir -p "$INSTALL_PATH"
fi

if ! which docker; then
	echo "mccli installer: docker is required and cannot be found, exiting"
	exit 1;
fi

if [ -a "$INSTALL_PATH/mccli" ]; then
	echo "mccli installer: $INSTALL_PATH/mccli already exists, exiting"
	exit 1;
fi

echo "Installing to $INSTALL_PATH/mccli"

set +e
ln -s "$MAIN_SCRIPT" "$INSTALL_PATH/mccli";
install_success="$?"
set -e

if [ "$install_success" -eq 0 ]; then
	echo "Installed"
else
	echo "Install failed"
fi