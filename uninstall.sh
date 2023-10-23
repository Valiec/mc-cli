#!/usr/bin/env bash

mccli_path="$(which mccli)"

set -e

if [ "$mccli_path" = "" ] && [ ! -e "$(dirname "$(readlink -f "$0")")/mccli.sh" ]; then
	echo "mccli: cannot uninstall, mccli is not installed, exiting";
	exit 1;
fi

if [ ! "$mccli_path" = "" ]; then
	unlink "$mccli_path"
fi

if [ -e "$(dirname "$(readlink -f "$0")")/mccli.sh" ]; then
	rm "$(dirname "$(readlink -f "$0")")/mccli.sh"
fi

echo "mccli: sucessfully uninstalled"