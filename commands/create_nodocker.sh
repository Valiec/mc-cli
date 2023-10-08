#!/usr/bin/env bash

set -eu 

# start server
port="$1"
dir="$2"
type="$3"
version="$4"
javatag="$5"
rcon_pass="$6"
mkdir -p "$dir"
bash "$SCRIPT_ROOT/util/install_server.sh" -t "$type" -v "$version" -l "latest" "$dir"
echo "Started $type $version server, running on port $port, with Java version $javatag" >&2

