create() {


	server_type="VANILLA"
	server_version="LATEST"
	java_version="latest"
	java_home="$JAVA_HOME"

	while getopts ':t:v:j:r:J:' option; do
		case "$option" in 
			t) 
				server_type="$OPTARG" 
				;;
			v) 
				server_version="$OPTARG"
				;;
			j)
				java_version="$OPTARG"
				;;
			J)
				java_home="$OPTARG"
				;;
			r)
				rcon_password="$OPTARG"
				;;
			*) 
				;;
		esac
	done

	shift "$(( OPTIND-1 ))"


	if (( $# < 1 )); then
		log_error "create: missing server name and port"
		echo "usage: mccli create <server name> <port> [data path]" >&2
		exit 1;
	elif (( $# < 2 )); then
		log_error "create: missing port"
		echo "usage: mccli create [-t SERVER_TYPE] [-v MC_VERSION] [-j JAVA_VERSION | -J JAVA_HOME] [-r RCON_PASSWORD] <server name> <port> [data path]" >&2
		exit 1;
	fi

	server_name="$1"
	if [ -v "servers[$server_name]" ]; then
		log_error "server $server_name already exists"
		exit 1;
	fi

	port="$2";

	data_path="$MCCLI_DIR/servers/$server_name";

	if [ -v "$3" ]; then
		data_path="$3";	
	fi

	if [ -a "$data_path" ] && [ ! -d "$data_path" ]; then
		log_error "data path $data_path already exists and is not a directory"
		exit 1;
	fi

	mkdir -p "$MCCLI_DIR/servers/$server_name";

	tmp_file="$(mktemp)"

	# this is only used inside the container and isn't exposed, MD5sum of data dir so it's consistent
	if [ ! -v rcon_password ]; then
		rcon_password="$(md5sum <<<"$data_path" | cut -f 1 -d " ")"
	fi

	if [ MCCLI_DOCKER = "true" ]; then
		bash "$SCRIPT_ROOT"/commands/create.sh "$port" "$data_path" "$server_type" "$server_version" "$java_version" "$rcon_password" > "$tmp_file";
		success="$?"
	else
		bash "$SCRIPT_ROOT"/commands/create_nodocker.sh "$port" "$data_path" "$server_type" "$server_version" "$java_version" "$rcon_password";
		success="$?"
		echo "$server_name" > "$tmp_file";
	fi

	if [ "$success" -gt 0 ]; then
		log_error "server creation failed";
		exit 1;
	fi

	servers["$server_name"]="$(cat "$tmp_file")"
	server_info["$server_name"]="$port	$server_type	$server_version	$java_version	$rcon_password	$data_path	$java_home"
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
	bash "$SCRIPT_ROOT"/commands/delete.sh "$server_docker_id";
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
	# redirect to /dev/null to stop printing container ID
	docker start "$server_docker_id" >/dev/null
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
	bash "$SCRIPT_ROOT"/commands/cmd.sh "$server_docker_id" "stop";
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
	bash "$SCRIPT_ROOT"/commands/logs.sh "$server_docker_id";
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
	bash "$SCRIPT_ROOT"/commands/cmd_interactive.sh "$server_docker_id";
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
	bash "$SCRIPT_ROOT"/commands/cmd.sh "$server_docker_id" "$cmd";
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
	bash "$SCRIPT_ROOT"/commands/status.sh "$server_docker_id";
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
	bash "$SCRIPT_ROOT"/commands/help.sh "$@";
}

version() {
	echo "mccli $MCCLI_VERSION";
}