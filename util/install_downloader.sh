#!/usr/bin/env bash

set -e

dl_temp="$(mktemp -d)"

echo "Installing mc-image-helper..."

cd "$dl_temp";
curl -OL "https://github.com/itzg/mc-image-helper/releases/download/1.35.2/mc-image-helper-1.35.2.tgz";
tar xzf "mc-image-helper-1.35.2.tgz";
mv "mc-image-helper-1.35.2" "$MCCLI_DIR/mc-image-helper";

# I'm just not sure what will happen if I delete the directory I'm in
cd;

rm -rf "$dl_temp";

echo "Installed mc-image-helper";

echo "Installing spigot buildtools...";

cd "$MCCLI_DIR/spigot-buildtools"

curl -OL "https://hub.spigotmc.org/jenkins/job/BuildTools/lastSuccessfulBuild/artifact/target/BuildTools.jar"

echo "Installed spigot buildtools";