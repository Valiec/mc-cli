action="$1"

shift 1;

usage() {
	echo "usage: mccli <subcommand> [args...]";
}

list() {
	echo "list";
}

create() {
	echo "create";
}

delete() {
	echo "delete";
}

start() {
	echo "start";
}

stop() {
	echo "stop";
}

logs() {
	echo "logs";
}

rcon() {
	echo "rcon";
}

cmd() {
	echo "cmd";
}

status() {
	echo "status";
}

info() {
	echo "info";
}

help() {
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

	Use mccli <subcommand> help for more detailed help on a given command.

	HEREDOC
}


case "$action" in
	"") 
		echo "mccli: no subcommand specified";
		usage;
		exit 1;
		;;
	"list") list $@ ;;
	"create") create $@ ;;
	"delete") delete $@ ;;
	"start") start $@ ;;
	"stop") stop $@ ;;
	"logs") logs $@ ;;
	"rcon") rcon $@ ;;
	"cmd") cmd $@ ;;
	"status") status $@ ;;
	"info") info $@ ;;
	"help") help $@ ;;
	*)
		echo "mccli: invalid command: $action"
		usage;
		exit 1;
		;;
esac