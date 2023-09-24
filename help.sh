cat << HEREDOC 
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