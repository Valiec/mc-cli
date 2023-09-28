#!/usr/bin/env bash

set -e

mc_version="latest"

server_type="vanilla"

# this is an internal script, this is checked in the calling script
data_dir="$1"

case "$server_type" in 
	"FORGE") "$MCCLI_DIR/mc-image-helper/bin/mc-image-helper" install-forge --minecraft-version "$mc_version" --output-directory "$data_dir" ;;
	"PAPER") "$MCCLI_DIR/mc-image-helper/bin/mc-image-helper" install-paper --version "$mc_version" --output-directory "$data_dir" ;;
	"SPIGOT") echo "spigot (I need to do buildtools)" ;;
	"QUILT") echo "quilt (I need to run the installer JAR (and maybe install vanilla? idk if it does that for me))" ;;
	"PURPUR") "$MCCLI_DIR/mc-image-helper/bin/mc-image-helper" install-purpur --version "$mc_version" --output-directory "$data_dir" ;;
	"FABRIC") echo "fabric (I need to run the installer JAR (and maybe install vanilla? idk if it does that for me))" ;;
	"VANILLA") echo "vanilla (I need to parse Mojang's JSON and download the right JAR)" ;;
	*) echo "Invalid server type $server_type" >&2 ;;
esac