#!/usr/bin/env bash

set -e

mc_version="latest"

server_type="VANILLA"

loader_version="latest"

while getopts ':v:t:l:' option; do
	case "$option" in 
		t) 
			server_type="$OPTARG" 
			;;
		v) 
			mc_version="$OPTARG"
			;;
		l)
			loader_version="$OPTARG"
			;;
		*) 
			;;
	esac
done



shift "$(( OPTIND-1 ))"

# this is an internal script, this is checked in the calling script

# lowercase all type names
data_dir=$(echo "$1" | tr "[:upper:]" "[:lower:]")

case "$server_type" in 
	"forge") 
		"$MCCLI_DIR/mc-image-helper/bin/mc-image-helper" install-forge --minecraft-version "$mc_version" --output-directory "$data_dir";
		;;
	"paper") 
		"$MCCLI_DIR/mc-image-helper/bin/mc-image-helper" install-paper --version "$mc_version" --output-directory "$data_dir";
		;;
	"spigot") 
		"$SCRIPT_ROOT/install_spigot.sh" "$data_dir" "$mc_version";
		;;
	"quilt")
		"$MCCLI_DIR/mc-image-helper/bin/mc-image-helper" install-quilt --minecraft-version "$mc_version" \
		--output-directory "$data_dir" --loader-version "$mc_version";
		;;
	"purpur")
		"$MCCLI_DIR/mc-image-helper/bin/mc-image-helper" install-purpur --version "$mc_version" --output-directory "$data_dir";
		;;
	"fabric")
		"$MCCLI_DIR/mc-image-helper/bin/mc-image-helper" install-fabric-loader --minecraft-version "$mc_version" \
		--output-directory "$data_dir" --loader-version "$mc_version";
		;;
	"vanilla")
		"$SCRIPT_ROOT/util/download_vanilla.sh" "$data_dir" "$mc_version";
		;;
	*)
		echo "Unsupported server type for non-containerized install: $server_type">&2;
		;;
esac