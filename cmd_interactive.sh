docker ps --no-trunc | grep "$1" >/dev/null

server_running="$?"

if [ "$server_running" -gt 0 ]; then
	echo "mccli: server is stopped or Docker container is missing" >&2
	exit 1;
fi

docker exec -i "$1" rcon-cli 
