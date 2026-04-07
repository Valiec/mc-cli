#!/usr/bin/env bash

set -e

server_id="$1"
data_dir="$2"
use_docker="$3"

if [ "$use_docker" = "true" ]; then
    test -e "$data_dir"/.running
    exit "$?"
else
    docker ps --no-trunc 2>/dev/null | grep "$server_docker_id" 2>&1 >/dev/null
    exit "$?"
fi

