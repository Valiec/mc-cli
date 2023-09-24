set -eu 

# start server
port="$1"
dir="$2"
type="$3"
version="$4"
javatag="$5"
rcon_pass="$6"
mkdir -p "$dir"
docker run -v $dir/data:/data -d -it -p "$port":25565 -e EULA=TRUE -e "TYPE=$type" -e "VERSION=$version" -e "RCON_PASSWORD=$rcon_pass" "itzg/minecraft-server:$javatag"
echo "Started $type $version server, running on port $port, with Java version $javatag" >&2

