#!/usr/bin/env bash

set -e

mc_version="latest"

server_type="vanilla"

# this is an internal script, this is checked in the calling script
data_dir="$1"

case "$server_type" in 
	"FORGE") ;;
	"PAPER") ;;
	"SPIGOT") ;;
	"QUILT") ;;
	"PURPUR") ;;
	"FABRIC") ;;
	*) echo "Invalid server type $server_type" >&2 ;;
esac