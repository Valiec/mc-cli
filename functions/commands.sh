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

	if [ -e "$data_path" ] && [ ! -d "$data_path" ]; then
		log_error "data path $data_path already exists and is not a directory"
		exit 1;
	fi

	mkdir -p "$MCCLI_DIR/servers/$server_name";

	tmp_file="$(mktemp)"

	if [ ! -v rcon_password ]; then
			if [ -e "$data_path/server.properties" ]; then
				while read -r line; do
					if [ "$(cut -f 1 -d "=" <<< "$line")" = "rcon.password" ]; then
						# use existing RCON password
						rcon_password="$(cut -f 2 -d "=" <<< "$line")"
						break
					fi
				done
			else
				# randomized RCON password
				rcon_password="$(head -c 32 /dev/random | base64)"
			fi
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
	if [ "$MCCLI_DOCKER" = "true" ]; then
		docker start "$server_docker_id" >/dev/null
	else
		data_dir="$(cut -f 6 -d $'\t' <<<"${servers_info["$server_name"]}")"
		server_name="$(cut -f 3 -d $'\t' <<<"${servers_info["$server_name"]}")"
		java_home="$(cut -f 7 -d $'\t' <<<"${servers_info["$server_name"]}")"
		if [ ! -e "$data_dir/eula.txt" ]; then
			if [ "$MCCLI_EULA" = "true" ]; then
				echo "eula=true" > "$data_dir/eula.txt";
			else
				echo "You must agree to the Minecraft EULA to start the server."
				read -p "agree? [Y/n]: " answer
			    if [ "$answer" != "Y" ]; then
			        echo "Exiting." >&2
			        exit 1;
			    fi
			    echo "Your EULA agreement will been saved for future servers."
			    echo "eula=true" > "$data_dir/eula.txt";

			    # User has accepted the EULA, save this and don't prompt again
			    export MCCLI_EULA="true";
			fi
		fi
		bash "$SCRIPT_ROOT"/util/start_server.sh "$server_name" "$data_dir" "$java_home";
	fi
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

	docker ps --no-trunc 2>/dev/null | grep "$server_docker_id" 2>&1 >/dev/null

	server_running="$?"

	running="Yes"

	if [ "$server_running" -gt 0 ]; then
		running="No"
	fi

	echo "$server_name info:"
	echo "Container ID: $server_docker_id"
	echo "Running: $running"
	echo "Port: $(cut -f 1 -d $'\t' <<<"${servers_info["$server_name"]}")"
	echo "Data folder: $(cut -f 6 -d $'\t' <<<"${servers_info["$server_name"]}")"
	echo "Type: $(cut -f 2 -d $'\t' <<<"${servers_info["$server_name"]}")"
	echo "Minecraft version: $(cut -f 3 -d $'\t' <<<"${servers_info["$server_name"]}")"
	echo "Java version: $(cut -f 4 -d $'\t' <<<"${servers_info["$server_name"]}")"
	echo "Java home: $(cut -f 7 -d $'\t' <<<"${servers_info["$server_name"]}")"
}

help() {
	bash "$SCRIPT_ROOT"/commands/help.sh "$@";
}

version() {
	echo "mccli $MCCLI_VERSION";
}