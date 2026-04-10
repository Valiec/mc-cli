import hashlib
import json
import os
import sys
from urllib.error import HTTPError

import requests


class VersionCache:
    config = None
    cache_data = {}

    def __init__(self, config):
        self.config = config
        self.read_cache_data()

    def get_cache_path(self, category, version):
        return str(os.path.join(self.config.CACHE_DIR, category, version))

    def read_cache_data(self):
        if not os.path.exists(self.config.CACHE_DIR):
            os.makedirs(self.config.CACHE_DIR)

        if not os.path.exists(os.path.join(self.config.CACHE_DIR, 'cache_data.json')):
            self.cache_data = {}
        else:
            with open(os.path.join(self.config.CACHE_DIR, 'cache_data.json')) as f:
                self.cache_data = json.load(f)["cache_data"]

    def write_cache_data(self):
        with open(os.path.join(self.config.CACHE_DIR, 'cache_data.json'), 'w') as f:
            json.dump({"cache_version": 1, "cache_data": self.cache_data}, f)

    def get(self, category, version, file_hash=None, download_url=None, filename="server.jar"):

        cache_miss = True

        if category in self.cache_data and version in self.cache_data[category]:
            if file_hash is not None and file_hash == self.cache_data[category][version]['hash']:
                cache_miss = False
            elif file_hash is None:
                cache_miss = False

        if cache_miss:
            if download_url is not None:
                try:
                    cache_path = self.get_cache_path(category, version)
                    if not os.path.exists(cache_path):
                        os.makedirs(cache_path)
                    path = os.path.join(cache_path, filename)
                    with requests.get(download_url, stream=True) as jar_stream:
                        jar_stream.raise_for_status()
                        with open(path, 'wb') as f:
                            for chunk in jar_stream.iter_content(chunk_size=8192):
                                if chunk:
                                    f.write(chunk)
                    if category not in self.cache_data:
                        self.cache_data[category] = {}

                    with open(path, "rb") as f:
                        sha1 = hashlib.file_digest(f, "sha1").hexdigest()
                        if file_hash is not None and sha1 != file_hash:
                            sys.stderr.write(
                                f"mccli: warning: sha1 hash of downloaded file {sha1} does not match provided sum {file_hash}\n")
                            ignore = input("continue? [Y/n] ")
                            if ignore != "Y":
                                os.remove(path)
                                return ["failed", "hash_mismatch", None]

                        self.cache_data[category][version] = {"hash": sha1}
                        self.write_cache_data()
                except HTTPError:
                    sys.stderr.write(f"mccli: error: failed to download for '{category} {version}'\n")
                    return ["failed", "download_error", None]
            else:
                return ["failed", "not_found", None]

        return ["success", "fetched" if cache_miss else "cached", os.path.join(self.get_cache_path(category, version), filename)]


