import os
import stat

from util.install_server import install_vanilla, install_paper
from utils import log_error


def create_server(port, data_path, server_type, version, java_home, rcon_password, rcon_port, cache, mod_version):
    start_cmd = None

    if server_type == "paper":
        success, version, mod_version, flags = install_paper(data_path, version, mod_version, cache)
        start_cmd = f"java {' '.join(flags)} -jar server.jar nogui"

    if server_type == "vanilla":
        if mod_version is not None:
            log_error("-V/--server-version has no effect for vanilla servers, use -v/--version", "error")
            exit(1)
        success, version, mod_version, _ = install_vanilla(data_path, version, cache)
        start_cmd = "java -jar server.jar nogui"


    if java_home is None or java_home == "" and "JAVA_HOME" in os.environ:
        java_home = os.environ["JAVA_HOME"]
    if java_home is None:
        java_home = ""

    with open(os.path.join(data_path, "start.sh"), "w") as f:
        java_str = f"JAVA_HOME='{java_home}' "
        if java_home == "":
            java_str = ""
        f.write('cd "$(dirname "$0")" || exit 1\n')
        f.write(f'{java_str}{start_cmd} > "mccli_$(date +%F_%T).log" 2>&1 &\n')
        f.write('pid="$!"\n')
        f.write('echo "$pid" > .running &&\n')
        f.write('wait "$pid" &&\n')
        f.write('rm .running')

    start_sh_perms = os.stat(os.path.join(data_path, "start.sh"))
    os.chmod(os.path.join(data_path, "start.sh"), start_sh_perms.st_mode | stat.S_IXUSR)  # chmod +x start.sh

    with open(os.path.join(data_path, "server.properties"), "w") as f:
        f.write(f"rcon.password={rcon_password}\n")
        f.write(f"server-port={port}\n")
        f.write(f"enable-rcon=true\n")
        f.write(f"rcon.port={rcon_port}\n")
        f.write(f"query.port={port}\n")
        f.write(f"enable-query=true\n")

    return [success, version, mod_version]