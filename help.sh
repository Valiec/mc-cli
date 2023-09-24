#!/usr/bin/env bash

if (( $# < 1 )); then

	cat <<- HEREDOC 
	MC-CLI help:

	usage: mccli <subcommand> [args...]

	Subcommands:

	    list:	Lists all Minecraft servers installed using MC-CLI.

	    create:	Creates a new Minecraft server with the given name and configuration.

	    delete:	Deletes a Minecraft server.

	    start:	Starts a Minecraft server.

	    stop:	Stops a Minecraft server.

	    logs:	Shows the logs for a Minecraft server.

	    rcon:	Opens an interactive RCON console for a Minecraft server.

	    cmd:	Sends the given command to the server using RCON.

	    status:	Displays live status info for a Minecraft server.

	    info:	Displays installation info for a Minecraft server.

	    help:	Displays this help message.

	Use mccli help <subcommand> for more detailed help on a given command.

	HEREDOC

else
	case "$1" in
		"list") 
			echo "Lists all Minecraft servers installed using MC-CLI."
			echo "usage: mccli list <server name>" 
			;;
		"create")
			echo "Creates a new Minecraft server with the given name and configuration." 
			echo "usage: mccli create <server name> <port> [data dir]" 
			;;
		"delete")
			echo "Deletes a Minecraft server." 
			echo "usage: mccli delete <server name>" 
			;;
		"start")
			echo "Starts a Minecraft server." 
			echo "usage: mccli start <server name>" 
			;;
		"stop")
			echo "Stops a Minecraft server. Equivalent to 'mccli cmd <server name> stop'." 
			echo "usage: mccli stop <server name>" 
			;;
		"logs")
			echo "Shows the logs for a Minecraft server."
			echo "usage: mccli logs <server name>"  
			;;
		"rcon")
			echo "Opens an interactive RCON console for a Minecraft server." 
			echo "usage: mccli rcon <server name>" 
			;;
		"cmd")
			echo "Sends the given command to the server using RCON." 
			echo "usage: mccli cmd <server name> <command>" 
			;;
		"status")
			echo "Displays live status info for a Minecraft server." 
			echo "usage: mccli status <server name>" 
			;;
		"info")
			echo "Displays installation info for a Minecraft server." 
			echo "usage: mccli info <server name>" 
			;;
		"help")
			echo "Displays help for MC-CLI." 
			echo "usage: mccli help [command]" 
			;;
		*)
			echo "unknown command: $1" >&2
			exit 1;
			;;
	esac
fi