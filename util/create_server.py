import os

from util.install_vanilla import install_vanilla


def create_server(port, data_path, server_type, version, java_home, rcon_password):
    if server_type == "vanilla":
        install_vanilla(data_path, version)
        with open(os.path.join(data_path, "server.properties"), "w") as f:
            f.write(f"rcon.password={rcon_password}\n")
            f.write(f"server-port={port}\n")