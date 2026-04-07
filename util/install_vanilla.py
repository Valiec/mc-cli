import hashlib
import os
import sys
from urllib.error import HTTPError

import requests


def install_vanilla(download_dir, version_id):

	manifest_url = "https://launchermeta.mojang.com/mc/game/version_manifest.json"

	try:
		with requests.get(manifest_url) as manifest_resp:
			manifest_resp.raise_for_status()
			manifest = manifest_resp.json()
			latest = manifest["latest"]["release"]
			latest_snapshot = manifest["latest"]["snapshot"]
	except HTTPError:
		sys.stderr.write("mccli: error: failed to download version manifest data\n")
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
		sys.stderr.write("mccli: error: no such version \'"+version_id+"\'\n")
		sys.exit(1)

	try:
		with requests.get(version_url) as version_resp:
			version_resp.raise_for_status()
			version_json = version_resp.json()
			server_download = version_json["downloads"]["server"]
			#print(server_download["sha1"] + "\t" + server_download["url"])
	except HTTPError:
		sys.stderr.write("mccli: error: failed to download version data for \'"+version_id+"\'\n")
		sys.exit(1)

	try:
		with requests.get(server_download["url"], stream=True) as jar_stream:
			jar_stream.raise_for_status()
			with open(os.path.join(download_dir, "server.jar"), 'wb') as f:
				for chunk in jar_stream.iter_content(chunk_size=8192):
					if chunk:
						f.write(chunk)
	except HTTPError:
		sys.stderr.write("mccli: error: failed to download server jar for \'"+version_id+"\'\n")
		sys.exit(1)

	with open(os.path.join(download_dir, "server.jar"), "rb") as f:
		sha1 = hashlib.file_digest(f, "sha1").hexdigest()
		if sha1 != server_download["sha1"]:
			sys.stderr.write(f"mccli: warning: sha1 hash of downloaded file {sha1} does not match provided sum from Mojang {server_download['sha1']}\n")
			ignore = input("continue? [Y/n] ")
			if ignore != "Y":
				sys.stderr.write("Exiting.")
				sys.exit(1)
	return version_id

if __name__ == "__main__":
	download_dir_param = sys.argv[1]
	version_id_param = sys.argv[2]
	install_vanilla(download_dir_param, version_id_param)
