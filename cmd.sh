container="$1"
shift 1
docker exec "$container" rcon-cli $@
