import sys

fabric_meta_url = "https://meta.fabricmc.net/v2/versions/installer"


if __name__ == "__main__":
    download_dir = sys.argv[1]
    version_id = sys.argv[2]
    fabric_version_id = sys.argv[3]