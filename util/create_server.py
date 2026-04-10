import os
import stat

from util.install_vanilla import install_vanilla


def create_server(port, data_path, server_type, version, java_home, rcon_password, rcon_port, cache):
    if server_type == "vanilla":
        version = install_vanilla(data_path, version, cache)
        if java_home is None or java_home == "" and "JAVA_HOME" in os.environ:
            java_home = os.environ["JAVA_HOME"]
        if java_home is None:
            java_home = ""
        with open(os.path.join(data_path, "start.sh"), "w") as f:
            java_str = f"JAVA_HOME='{java_home}' "
            if java_home == "":
                java_str = ""
            cmd_str = java_str+f'java -jar "$(dirname "$0")"/server.jar -nogui'
            f.write('cd "$(dirname "$0")" && '+cmd_str+' & pid="$!" && echo "$pid" > "$(dirname "$0")"/.running && wait "$pid" && rm "$(dirname "$0")"/.running')
        start_sh_perms = os.stat(os.path.join(data_path, "start.sh"))
        os.chmod(os.path.join(data_path, "start.sh"), start_sh_perms.st_mode | stat.S_IXUSR) # chmod +x start.sh
        with open(os.path.join(data_path, "server.properties"), "w") as f:
            f.write(f"rcon.password={rcon_password}\n")
            f.write(f"server-port={port}\n")
            f.write(f"enable-rcon=true\n")
            f.write(f"rcon.port={rcon_port}\n")
            f.write(f"query.port={port}\n")
            f.write(f"enable-query=true\n")
    return version