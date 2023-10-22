#!/usr/bin/env bash

if [ "$MCCLI_DOCKER" = "true" ]; then
	docker ps --no-trunc | grep "$1" >/dev/null	
else
	[ -e "$data_dir/.running" ]
fi
server_running="$?"

if [ "$server_running" -eq 0 ]; then
	docker exec "$1" rcon-cli stop
	success="$?"
	if [ $success -gt 0 ]; then
		echo "Could not connect to server $1 using RCON." >&2
		exit 1;
	fi
	echo "Waiting for server to stop..." >&2
	while docker ps --no-trunc | grep "$1" > /dev/null; do
	        echo "Server $1 still running..." >&2
		sleep 5;
	done
fi
docker rm "$1"
echo "Deleted server $1" >&2
