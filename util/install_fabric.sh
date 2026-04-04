#!/usr/bin/env bash

set -e

download_dir="$1"
version="$2"

cd "$download_dir"

curl "https://meta.fabricmc.net/v2/versions/installer"
