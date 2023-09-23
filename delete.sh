docker exec "$1" rcon-cli stop
echo "Waiting for server to stop..." >&2
while $(docker ps | grep "$1"); do
	sleep 5;
done
docker rm "$1"
echo "Deleted server $1" >&2
