set -euo pipefail

# start server
name="$1"
port="$2"
dir="$3"
type="$4"
version="$5"
javatag="$6"
docker run --name "$name" -v $dir/data:/data -d -it -p "$port":25565 -e EULA=TRUE -e "TYPE=$type" -e "VERSION=$version" "itzg/minecraft-server:$javatag"
echo "Started $type $version server $name, running on port $port, with Java version $javatag" >&2

