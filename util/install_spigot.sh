#!/usr/bin/env bash

set -e

download_dir="$1"
version="$2"

cd "$download_dir"

curl -O "https://hub.spigotmc.org/jenkins/job/BuildTools/lastSuccessfulBuild/artifact/target/BuildTools.jar"

java -jar BuildTools.jar --rev "$version"

