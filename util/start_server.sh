server_name="$1"
server_dir="$2"
java_home="$3"


if [ "$MCCLI_DOCKER" = "true" ]; then
	docker ps --no-trunc | grep "$1" >/dev/null	
else
	[ -e "$data_dir/.running" ]
fi
server_running="$?"

if [ "$server_running" -eq 0 ]; then
	if [ "$MCCLI_SCREEN" = "true" ]; then
		screen -S "mccli_$server_name" -dm bash -c "cd $server_dir && touch .runnning && JAVA_HOME=$java_home $server_dir/start.sh; rm .running;"
	else
		nohup bash -c "cd $server_dir && touch .runnning && JAVA_HOME=$java_home $server_dir/start.sh; rm .running;" > "$server_dir/mccli_$(date +%F_%T).log" 2>&1 &
		disown
	fi
	echo "Server $server_name starting."
fi

