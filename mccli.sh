#!/usr/bin/env bash

action="$1"

shift 1;

SCRIPT_ROOT=$(dirname "$0")

# default MCCLI_DIR is ~/.mccli, but you can configure it
if [ ! -v MCCLI_DIR ]; then
	MCCLI_DIR="$HOME"/.mccli
fi

# export MCCLI_DIR so that the subcommands can access it
export MCCLI_DIR

# if $MCCLI_DIR exists, but it's not a directory
if [ -a "$MCCLI_DIR" ] && [ ! -d "$MCCLI_DIR" ]; then
	log_error "config path $MCCLI_DIR already exists and is not a directory"
	exit 1;
fi

# if $MCCLI_DIR does not exist, create it and the servers file
if [ ! -a "$MCCLI_DIR" ]; then
	mkdir -p "$MCCLI_DIR";
	touch "$MCCLI_DIR"/servers.conf;
fi

declare -A servers

declare -A servers_info

# a colon-separated list of ports used so I can detect a reused port before Docker complains
used_ports=""

while read -r line; do
	server_name=$(cut -f 1 -d $'\t' <<<"$line");
	server_docker_id=$(cut -f 2 -d $'\t' <<<"$line");
	server_info=$(cut -f 3- -d $'\t' <<<"$line");
	servers["$server_name"]="$server_docker_id";
	servers_info["$server_name"]="$server_info";
	used_ports="$used_ports:$(cut -f 1 -d $'\t' <<<"${servers_info["$server_name"]}")"
done < "$MCCLI_DIR"/servers.conf


log_error() {
	echo "mccli:" "$@" >&2
}

check_server_exists() {
	if [ ! -v "servers[$server_name]" ]; then
		log_error "server $server_name does not exist"
		exit 1;
	fi
}

usage() {
	echo "usage: mccli <subcommand> [args...]";
}

list() {
	for server in "${!servers[@]}"; do
		echo "$server" ":" "${servers[$server]}"
	done
}

create() {
	if (( $# < 1 )); then
		log_error "create: missing server name and port"
		echo "usage: mccli create <server name> <port> [data path]" >&2
		exit 1;
	elif (( $# < 2 )); then
		log_error "create: missing port"
		echo "usage: mccli create <server name> <port> [data path]" >&2
		exit 1;
	fi

	server_name="$1"
	if [ -v "servers[$server_name]" ]; then
		log_error "server $server_name already exists"
		exit 1;
	fi

	port="$2";

	data_path="$MCCLI_DIR/$server_name/data";

	if [ -v "$3" ]; then
		data_path="$3";	
	fi

	if [ -a "$data_path" ] && [ ! -d "$data_path" ]; then
		log_error "data path $data_path already exists and is not a directory"
		exit 1;
	fi

	mkdir -p "$MCCLI_DIR/$server_name/data";

	tmp_file="$(mktemp)"

	# this is only used inside the container and isn't exposed, MD5sum of data dir so it's consistent
	rcon_password="$(md5sum <<<"$data_path" | cut -f 1 -d " ")"

	bash "$SCRIPT_ROOT"/create.sh "$port" "$data_path" "VANILLA" "LATEST" "latest" "$rcon_password" > "$tmp_file";
	success="$?"

	if [ "$success" -gt 0 ]; then
		log_error "server creation failed";
		exit 1;
	fi

	servers["$server_name"]="$(cat "$tmp_file")"
	server_info["$server_name"]="25565	VANILLA	LATEST	latest	some-rcon-password	$data_path"
}

delete() {
	if (( $# < 1 )); then
		log_error "delete: missing server name"
		echo "usage: mccli delete <server name>" >&2
		exit 1;
	fi
	server_name="$1"
	check_server_exists "$server_name"
	server_docker_id=${servers[$server_name]}
	bash "$SCRIPT_ROOT"/delete.sh "$server_docker_id";
	unset 'servers[$server_name]'
	unset 'server_info[$server_name]'
}

start() {
	if (( $# < 1 )); then
		log_error "start: missing server name"
		echo "usage: mccli start <server name>" >&2
		exit 1;
	fi
	server_name="$1"
	check_server_exists "$server_name"
	server_docker_id=${servers[$server_name]}
	docker start "$server_docker_id"
}

stop() {
	if (( $# < 1 )); then
		log_error "stop: missing server name"
		echo "usage: mccli stop <server name>" >&2
		exit 1;
	fi
	server_name="$1"
	check_server_exists "$server_name"
	server_docker_id=${servers[$server_name]}
	bash "$SCRIPT_ROOT"/cmd.sh "$server_docker_id" "stop";
}

logs() {
	if (( $# < 1 )); then
		log_error "logs: missing server name"
		echo "usage: mccli logs <server name>" >&2
		exit 1;
	fi
	server_name="$1"
	check_server_exists "$server_name"
	server_docker_id=${servers[$server_name]}
	bash "$SCRIPT_ROOT"/logs.sh "$server_docker_id";
}

rcon() {
	if (( $# < 1 )); then
		log_error "rcon: missing server name"
		echo "usage: mccli rcon <server name>" >&2
		exit 1;
	fi
	server_name="$1"
	check_server_exists "$server_name"
	server_docker_id=${servers[$server_name]}
	bash "$SCRIPT_ROOT"/cmd_interactive.sh "$server_docker_id";
}

cmd() {
	if (( $# < 1 )); then
		log_error "cmd: missing server name and command"
		echo "usage: mccli cmd <server name> <command>" >&2
		exit 1;
	elif (( $# < 2 )); then
		log_error "delete: missing command"
		echo "usage: mccli cmd <server name> <command>" >&2
		exit 1;
	fi
	server_name="$1"
	cmd="$2"
	check_server_exists "$server_name"
	server_docker_id=${servers[$server_name]}
	bash "$SCRIPT_ROOT"/cmd.sh "$server_docker_id" "$cmd";
}

status() {
	if (( $# < 1 )); then
		log_error "status: missing server name"
		echo "usage: mccli status <server name>" >&2
		exit 1;
	fi
	server_name="$1"
	check_server_exists "$server_name"
	server_docker_id=${servers[$server_name]}
	bash "$SCRIPT_ROOT"/status.sh "$server_docker_id";
}

info() {
	if (( $# < 1 )); then
		log_error "info: missing server name"
		echo "usage: mccli info <server name>" >&2
		exit 1;
	fi
	server_name="$1"
	check_server_exists "$server_name"
	server_docker_id=${servers[$server_name]}

	docker ps --no-trunc | grep "$server_docker_id" >/dev/null

	server_running="$?"

	running="Yes"

	if [ "$server_running" -gt 0 ]; then
		running="No"
	fi

	echo "$server_name info:"
	echo "Container ID: $server_docker_id"
	echo "Running: $running"
	echo "Port: $(cut -f 1 -d $'\t' <<<"${servers_info["$server_name"]}")"
	echo "Data folder: $(cut -f 6- -d $'\t' <<<"${servers_info["$server_name"]}")"
	echo "Type: $(cut -f 2 -d $'\t' <<<"${servers_info["$server_name"]}")"
	echo "Minecraft version: $(cut -f 3 -d $'\t' <<<"${servers_info["$server_name"]}")"
	echo "Java version: $(cut -f 4 -d $'\t' <<<"${servers_info["$server_name"]}")"
}

help() {
	bash "$SCRIPT_ROOT"/help.sh "$@";
}


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