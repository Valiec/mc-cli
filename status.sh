while true; do
	health_str=$(docker exec "$1"  mc-health | sed "s/localhost:25565 : //" | sed -E "s/version=([^ ]+) online=([^ ]+) max=([^ ]+) motd='(.+)'/Version: \1\nPlayers Online: \2\/\3\nMOTD: \4/g")
	cpu_ram_str=$(docker exec "$1" top -b -n 1 -E k | grep java | awk '{ print "Total Memory: " $5/1024, "MiB\nPhysical Memory: " $6, "\n%CPU: " $9 }')
        list_str=$(docker exec "$1" rcon-cli list | sed -E "s/There are [0-9]+ of a max of [0-9]+ players online:[ ]+//" | sed "s/, /,/g" | tr ", " "\n")
	player_line_count=$(echo "$health_str" | head -n 2 | tail -n 1 | sed -E "s/Players Online: ([0-9]+)\/[0-9]+/\1/")
        printf "%s\n%s\n" "$health_str" "$cpu_ram_str"
        if [ $player_line_count -gt 0 ]; then
        	printf "\nPlayers online:\n$list_str\n"
	        player_line_count=$((player_line_count+2))
        fi
        line_count=$((player_line_count + 6))
	sleep 5
	for i in $(seq 1 "$line_count"); do
		printf "\r$(tput el)$(tput cuu1)"
        done
        printf "$(tput el)"
done
