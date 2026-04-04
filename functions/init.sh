init_mccli() {
	# default MCCLI_DIR is ~/.mccli, but you can configure it
	if [ ! -v MCCLI_DIR ]; then
		if [ -f "$HOME"/.mccli_dir ]; then
			MCCLI_DIR="$(cat "$HOME"/.mccli_dir)"
		else
			MCCLI_DIR="$HOME"/.mccli
		fi
	fi

	# export MCCLI_DIR so that the subcommands can access it
	export MCCLI_DIR MCCLI_VERSION

	# if $MCCLI_DIR exists, but it's not a directory
	if [ -e "$MCCLI_DIR" ] && [ ! -d "$MCCLI_DIR" ]; then
		log_error "config path $MCCLI_DIR already exists and is not a directory"
		exit 1;
	fi

	# if $MCCLI_DIR does not exist, create it and the servers file
	if [ ! -e "$MCCLI_DIR" ]; then
		mkdir -p "$MCCLI_DIR";
		touch "$MCCLI_DIR"/servers.conf;
	fi

	MCCLI_PYTHON=""
	MCCLI_DOCKER=""
	MCCLI_SCREEN=""
	MCCLI_EULA="false"

	if [ ! -e "$MCCLI_DIR/config" ]; then
		echo "VERSION=$MCCLI_VERSION" > "$MCCLI_DIR"/config;
		if which docker > /dev/null; then
			read -p "use Docker? [Y/n]: " use_docker
			if [ "$use_docker" = "Y" ]; then
				MCCLI_DOCKER="true";
			else
				MCCLI_DOCKER="false";
			fi	
		else
			MCCLI_DOCKER="false";
		fi

		if which screen > /dev/null; then
			read -p "use Screen? [Y/n]: " use_screen
			if [ "$use_screen" = "Y" ]; then
				MCCLI_SCREEN="true";
			else
				MCCLI_SCREEN="false";
			fi	
		else
			MCCLI_SCREEN="false";
		fi

		if which python > /dev/null; then
			MCCLI_PYTHON="$(which python)";
		elif which python3 > /dev/null; then
			MCCLI_PYTHON="$(which python3)";
		else
			echo "mccli: python not found as 'python' or 'python3'"
			read -p "Enter path to Python interpreter: " MCCLI_PYTHON
		fi

		echo "USE_DOCKER=$MCCLI_DOCKER" >> "$MCCLI_DIR"/config;
		echo "USE_SCREEN=$MCCLI_SCREEN" >> "$MCCLI_DIR"/config;
		echo "PYTHON_PATH=$MCCLI_PYTHON" >> "$MCCLI_DIR"/config;
		echo "AGREED_EULA=false" >> "$MCCLI_DIR"/config;

	else
		while read -r line; do
			case "$(cut -f 1 -d "=" <<< "$line")" in
				"USE_DOCKER") MCCLI_DOCKER="$(cut -f 2 -d "=" <<< "$line")"; ;;
				"USE_SCREEN") MCCLI_SCREEN="$(cut -f 2 -d "=" <<< "$line")"; ;;
				"PYTHON_PATH") MCCLI_PYTHON="$(cut -f 2 -d "=" <<< "$line")"; ;;
				"AGREED_EULA") MCCLI_EULA="$(cut -f 2 -d "=" <<< "$line")"; ;;
				*) ;;
			esac
		done < "$MCCLI_DIR"/config
	fi

	if [ ! -d "$MCCLI_DIR/venv" ]; then
		echo "initializing python venv..."
		"$MCCLI_PYTHON" -m venv "$MCCLI_DIR/venv"
		"$MCCLI_DIR/venv/bin/pip" -qq install mcrcon
	fi

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
}