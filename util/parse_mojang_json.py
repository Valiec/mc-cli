import json
import sys
from urllib.error import HTTPError
from urllib.request import urlopen

version_id = sys.argv[1]

manifest=json.loads(sys.stdin.read())

latest = manifest["latest"]["release"]

latest_snapshot = manifest["latest"]["snapshot"]

versions = {}

for entry in manifest["versions"]:
	versions[entry["id"]] = entry

if version_id in versions:
	version_url = versions[version_id]["url"]
else:
	sys.stderr.write("mccli: error: no such version \'"+version_id+"\'\n")
	sys.exit(1)

try:
	with urlopen(version_url) as version_response:
		server_download = json.loads(version_response.read())["downloads"]["server"]
		print(server_download["sha1"]+"\t"+server_download["url"])
except HTTPError:
	sys.stderr.write("mccli: error: failed to download version data for \'"+version_id+"\'\n")
	sys.exit(1)

