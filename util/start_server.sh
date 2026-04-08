server_name="$1"
server_dir="$2"

if [ ! -e "$server_dir/.running" ]; then
	nohup bash "$server_dir/start.sh" > "$server_dir/mccli_$(date +%F_%T).log" 2>&1 &
	disown
	echo "Server $server_name starting."
fi

