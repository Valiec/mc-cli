import os.path
import shutil
import sys
from urllib.error import HTTPError

import requests

from config import Config
from utils import log_error, stderr_print


def install_vanilla(download_dir, version_id, cache):

	manifest_url = "https://launchermeta.mojang.com/mc/game/version_manifest.json"

	try:
		with requests.get(manifest_url, headers=Config.default_headers) as manifest_resp:
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
		with requests.get(version_url, headers=Config.default_headers) as version_resp:
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
	return ["success", version_id, None, ["nogui"]]

def install_paper(download_dir, mc_version_id, paper_version_id, cache):

	manifest_url = "https://fill.papermc.io/v3/projects/paper/versions"

	versions = {}

	latest_version = mc_version_id == "latest"

	try:
		with requests.get(manifest_url, headers=Config.default_headers) as manifest_resp:
			manifest_resp.raise_for_status()
			manifest = manifest_resp.json()
			for version in manifest["versions"]:
				versions[version["version"]["id"]] = version
			latest = manifest["versions"][0]["version"]["id"]

			if mc_version_id == "latest":
				mc_version_id = latest

			if mc_version_id not in versions:
				log_error("no paper version for Minecraft version \'"+mc_version_id+"\'", "error")
				exit(1)


	except HTTPError:
		log_error("failed to download version manifest data")
		sys.exit(1)

	if paper_version_id is None:
		paper_version_id = "latest_stable"

	str_builds = [str(build) for build in versions[mc_version_id]["builds"]]
	if paper_version_id not in str_builds and paper_version_id != "latest" and not paper_version_id.startswith("latest_"):
		log_error(f"paper version {paper_version_id} not found", "error")
		exit(1)

	if "_" in paper_version_id and paper_version_id.startswith("latest_"):
		channel = paper_version_id.split("_")[1]
		paper_version_id = "latest"

		version_list = list(versions.keys())
		version_index = 0

		while version_index < len(version_list):
				mc_version_id = version_list[version_index]
				builds_channel_url = f"https://fill.papermc.io/v3/projects/paper/versions/{mc_version_id}/builds?channel={channel.upper()}"
				try:
					with requests.get(builds_channel_url, headers=Config.default_headers) as build_resp:
						build_resp.raise_for_status()
						builds = build_resp.json()

						if not builds:
							if not latest_version:
								log_error(f"no builds found for channel {channel.upper()} and Minecraft version {mc_version_id}","error")
								exit(1)
							else:
								version_index += 1
						else:
							paper_version_id = builds[0]["id"]
							break

				except HTTPError:
					log_error("failed to download version build data")
					sys.exit(1)

	build_url = f"https://fill.papermc.io/v3/projects/paper/versions/{mc_version_id}/builds/{paper_version_id}"

	try:
		with requests.get(build_url, headers=Config.default_headers) as build_resp:
			build_resp.raise_for_status()
			build = build_resp.json()

	except HTTPError:
		log_error("failed to download version build data")
		sys.exit(1)

	sha256_hash = build["downloads"]["server:default"]["checksums"]["sha256"]
	download_url = build["downloads"]["server:default"]["url"]
	paper_version_id = build["id"]  # resolve "latest" to a real version ID
	recommended_flags = versions[mc_version_id]["version"]["java"]["flags"]["recommended"]

	fetch_result = cache.get("paper", mc_version_id+"_"+str(paper_version_id), sha256_hash, download_url, "server.jar", "sha256")
	if fetch_result[0] != "success":
		if fetch_result[1] == "hash_mismatch":
			stderr_print("Exiting.")
		sys.exit(1)
	else:
		shutil.copy(fetch_result[2], os.path.join(download_dir, "server.jar"))

	return ["success", mc_version_id, paper_version_id, recommended_flags]


# fabric_meta_url = "https://meta.fabricmc.net/v2/versions/installer"