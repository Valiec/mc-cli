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
	echo "mccli: config path $MCCLI_DIR already exists and is not a directory" >&2
	exit 1;
fi

# if $MCCLI_DIR does not exist, create it and the servers file
if [ ! -a "$MCCLI_DIR" ]; then
	mkdir -p "$MCCLI_DIR";
	touch "$MCCLI_DIR"/servers.conf;
fi

declare -A servers

declare -A servers_info

while read -r line; do
	server_name=$(cut -f 1 -d $'\t' <<<"$line");
	server_docker_id=$(cut -f 2 -d $'\t' <<<"$line");
	server_info=$(cut -f 3- -d $'\t' <<<"$line");
	servers["$server_name"]="$server_docker_id";
	servers_info["$server_name"]="$server_info";
done < "$MCCLI_DIR"/servers.conf


log_error() {
	echo "mccli:" $@ >&2
}

check_server_exists() {
	if [ ! -v servers[$server_name] ]; then
		log_error "server $server_name does not exist"
		exit 1;
	fi
}

usage() {
	echo "usage: mccli <subcommand> [args...]";
}

list() {
	for server in ${!servers[@]}; do
		echo $server ":" ${servers[$server]}
	done
}

create() {
	server_name="$1"
	if [ -v servers[$server_name] ]; then
		log_error "server $server_name already exists"
		exit 1;
	fi
	echo "create";
	servers["$server_name"]="docker_id"
	server_info["$server_name"]="some	info"
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
	echo "start";
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
	echo "stop";
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
	check_server_exists "$server_name"
	server_docker_id=${servers[$server_name]}
	bash "$SCRIPT_ROOT"/cmd.sh "$server_docker_id";
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
	echo "info";
}

help() {
	bash "$SCRIPT_ROOT"/help.sh;
}


case "$action" in
	"") 
		echo "mccli: no subcommand specified";
		usage;
		exit 1;
		;;
	"list") list $@ ;;
	"create") create $@ ;;
	"delete") delete $@ ;;
	"start") start $@ ;;
	"stop") stop $@ ;;
	"logs") logs $@ ;;
	"rcon") rcon $@ ;;
	"cmd") cmd $@ ;;
	"status") status $@ ;;
	"info") info $@ ;;
	"help") help $@ ;;
	*)
		echo "mccli: invalid command: $action"
		usage;
		exit 1;
		;;
esac

# reset servers.conf
printf "" > "$MCCLI_DIR"/servers.conf;

# write new data
for server in ${!servers[@]}; do
	printf "%s\t%s\t%s\n" "$server" "${servers[$server]}" "${server_info[$server]}" >> "$MCCLI_DIR"/servers.conf
done