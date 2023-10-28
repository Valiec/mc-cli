#!/usr/bin/env bash

mccli_path="$(which mccli)"

set -e

if [ "$mccli_path" = "" ] && [ ! -e "$(dirname "$(readlink -f "$mccli_path")")/mccli.sh" ]; then
	echo "mccli: cannot uninstall, mccli is not installed, exiting";
	exit 1;
fi

if [ -e "$(dirname "$(readlink -f "$mccli_path")")/mccli.sh" ]; then
	rm "$(dirname "$(readlink -f "$mccli_path")")/mccli.sh"
fi

if [ -e "$(dirname "$(readlink -f "$mccli_path")")/.copy_install" ]; then
	rm -rf "$(dirname "$(readlink -f "$mccli_path")")";
fi

if [ ! "$mccli_path" = "" ]; then
	unlink "$mccli_path"
fi

echo "mccli: sucessfully uninstalled"