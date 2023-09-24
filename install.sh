#!/usr/bin/env bash

MAIN_SCRIPT="$(dirname "$(readlink -f "$0")")/mccli.sh"

INSTALL_PATH="/usr/local/bin"

if [ -v "$1" ]; then
	INSTALL_PATH="$1"
fi

if [ ! -a "$INSTALL_PATH" ]; then
	mkdir -p "$INSTALL_PATH"
fi


if [ -a "$INSTALL_PATH/mccli" ]; then
	echo "mccli installer: $INSTALL_PATH/mccli already exists, exiting"
	exit 1;
fi

echo "Installing to $INSTALL_PATH/mccli"

ln -s "$MAIN_SCRIPT" "$INSTALL_PATH/mccli";

echo "Installed"