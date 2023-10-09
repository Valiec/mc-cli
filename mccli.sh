#!/usr/bin/env bash

action="$1"

export MCCLI_VERSION="1.0.0"

shift 1;

SCRIPT_ROOT="$(dirname "$(readlink -f "$0")")"

declare -A servers

declare -A servers_info

declare MCCLI_DOCKER MCCLI_SCREEN MCCLI_PYTHON SCRIPT_ROOT

source "$SCRIPT_ROOT/functions/init.sh"

init_mccli; # shell function, defined in init.sh

export MCCLI_DOCKER MCCLI_SCREEN MCCLI_PYTHON SCRIPT_ROOT

# defines the commands
source "$SCRIPT_ROOT/functions/commands.sh"


case "$action" in
	"list") list "$@" ;;
	"create") create "$@" ;;
	"delete") delete "$@" ;;
	"start") start "$@" ;;
	"stop") stop "$@" ;;
	"logs") logs "$@" ;;
	"rcon") rcon "$@" ;;
	"cmd") cmd "$@" ;;
	"status") status "$@" ;;
	"info") info "$@" ;;
	"version") version "$@" ;;
	"help") help "$@" ;;
	"") 
		log_error "no subcommand specified";
		usage;
		exit 1;
		;;
	*)
		log_error "invalid command: $action"
		usage;
		exit 1;
		;;
esac

# reset servers.conf
printf "" > "$MCCLI_DIR"/servers.conf;

# write new data
for server in "${!servers[@]}"; do
	printf "%s\t%s\t%s\n" "$server" "${servers[$server]}" "${server_info[$server]}" >> "$MCCLI_DIR"/servers.conf
done

# rewrite the config file
echo "VERSION=$MCCLI_VERSION" > "$MCCLI_DIR"/config;
echo "USE_DOCKER=$MCCLI_DOCKER" >> "$MCCLI_DIR"/config;
echo "USE_SCREEN=$MCCLI_SCREEN" >> "$MCCLI_DIR"/config;
echo "PYTHON_PATH=$MCCLI_PYTHON" >> "$MCCLI_DIR"/config;
echo "AGREED_EULA=$MCCLI_EULA" >> "$MCCLI_DIR"/config;