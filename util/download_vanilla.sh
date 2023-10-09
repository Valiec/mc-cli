#!/usr/bin/env bash

set -e

download_dir="$1"
version="$2"

echo "Downloading version manifest..."

download_data=$(curl -# "https://launchermeta.mojang.com/mc/game/version_manifest.json" | "$MCCLI_PYTHON" "$SCRIPT_ROOT/util/parse_mojang_json.py" "$version")
download_hash="$(cut -f 1 <<< "$download_data")"
download_url="$(cut -f 2- <<< "$download_data")"

cd "$download_dir"

echo "Downloading $version JAR..."

curl -# -o server.jar "$download_url"
downloaded_shasum="$(sha1sum "server.jar" | cut -f 1 -d " ")"

if [ "$download_hash" != "$downloaded_shasum" ]; then
    echo "mccli: warning: sha1 hash of downloaded file ($downloaded_shasum) does not match provided sum from Mojang ($download_hash)" >&2
    read -p "continue? [Y/n]: " answer
    if [ "$answer" != "Y" ]; then
        echo "Exiting." >&2
    fi
fi