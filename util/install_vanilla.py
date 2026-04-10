import os.path
import shutil
import sys
from urllib.error import HTTPError

import requests

from utils import log_error, stderr_print


def install_vanilla(download_dir, version_id, cache):

	manifest_url = "https://launchermeta.mojang.com/mc/game/version_manifest.json"

	try:
		with requests.get(manifest_url) as manifest_resp:
			manifest_resp.raise_for_status()
			manifest = manifest_resp.json()
			latest = manifest["latest"]["release"]
			latest_snapshot = manifest["latest"]["snapshot"]
	except HTTPError:
		log_error("failed to download version manifest data")
		sys.exit(1)

	versions = {}

	for entry in manifest["versions"]:
		versions[entry["id"]] = entry

	if version_id == "latest":
		version_id = latest
	elif version_id == "latest_snapshot":
		version_id = latest_snapshot

	if version_id in versions:
		version_url = versions[version_id]["url"]
	else:
		log_error("no such version \'"+version_id+"\'")
		sys.exit(1)

	try:
		with requests.get(version_url) as version_resp:
			version_resp.raise_for_status()
			version_json = version_resp.json()
			server_download = version_json["downloads"]["server"]
	except HTTPError:
		log_error("failed to download version data for \'" + version_id + "\'")
		sys.exit(1)

	fetch_result = cache.get("vanilla", version_id, server_download["sha1"], server_download["url"], "server.jar")
	if fetch_result[0] != "success":
		if fetch_result[1] == "hash_mismatch":
			stderr_print("Exiting.")
		sys.exit(1)
	else:
		shutil.copy(fetch_result[2], os.path.join(download_dir, "server.jar"))
	return version_id
