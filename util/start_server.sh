server_name="$1"
server_dir="$2"
java_home="$3"

if [ "$MCCLI_SCREEN" = "true" ]; then
	screen -S "mccli_$server_name" -dm bash -c "cd $server_dir && JAVA_HOME=$java_home $server_dir/start.sh;"
else
	nohup bash -c "cd $server_dir && JAVA_HOME=$java_home $server_dir/start.sh;"
fi