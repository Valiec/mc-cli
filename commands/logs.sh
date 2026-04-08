#!/usr/bin/env bash

data_dir="$2"

if [ "$MCCLI_DOCKER" = "true" ]; then
	docker ps --no-trunc | grep "$1" >/dev/null	
else
	[ -e "$data_dir/.running" ]
fi
server_running="$?"

if [ "$server_running" -gt 0 ]; then
	echo "mccli: server is stopped or Docker container is missing" >&2
	exit 1;
fi

echo "logs go here"
ls "$data_dir"/mccli_*.log
