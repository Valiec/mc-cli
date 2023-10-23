#!/usr/bin/env bash

set -e

unlink "$(which mccli)"

rm "$(dirname "$(readlink -f "$0")")/mccli.sh"

echo "mccli: sucessfully uninstalled"