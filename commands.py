import subprocess
import argparse
import os
import base64
import uuid

from util.create_server import create_server
# other parts of MC-CLI
from utils import *

class Commands:
	config = None
	args = []

	def __init__(self, config, args):
		self.config = config
		self.args = args

	def create(self):
		parser = argparse.ArgumentParser(prog="mccli")
		parser.add_argument("-t", "--type", default="vanilla", help="The type of server to create.")
		parser.add_argument("-v", "--version", default="latest", help="The Minecraft version of the server to be created.")
		parser.add_argument("-j", "--java-home", default=os.getenv("JAVA_HOME"), help="The JAVA_HOME location for the server to be created.")
		parser.add_argument("-r", "--rcon-password", help="A custom password for the RCON remote console. If you are not using RCON elsewhere, \
			do not expose the RCON port to the internet, and skip this option to have MCCLI generate a random RCON password.")
		parser.add_argument("-d", "--data-path", help="The path to the server's install directory.")
		parser.add_argument("-R", "--rcon-port", default=-1, help="The port that will be used for the RCON console.")
		parser.add_argument("-p", "--port", default=-1, help="The port the new server will run on (default: next free port).")
		parser.add_argument("server_name", help="The name of the server to be created.")
		args_arr = parser.parse_args(self.args)

		if args_arr.rcon_port == -1:
			args_arr.rcon_port = self.config.servers.get_free_rcon_port()

		if args_arr.port == -1:
			args_arr.port = self.config.servers.get_free_port()

		if args_arr.java_home is None:
			args_arr.java_home = ""

		if self.config.servers.server_exists(args_arr.server_name):
			log_error("server "+args_arr.server_name+" already exists")
			sys.exit(1)

		data_path = args_arr.data_path

		if data_path is None:
			data_path = os.getenv("MCCLI_DIR")+"/servers/"+args_arr.server_name

		if os.path.exists(data_path) and not os.path.isdir(data_path):
			log_error("data path "+data_path+" already exists and is not a directory")
			sys.exit(1)

		os.makedirs(data_path, exist_ok=True)

		if args_arr.rcon_password is None:
			if os.path.exists(data_path+"/server.properties"):
				with open(data_path+"/server.properties") as server_properties:
					for line_s in server_properties:
						line = line_s.split("=", 1)
						if line[0] == "rcon.password":
							rcon_password = line[1].strip("\n")
			else:
				rcon_password = base64.b64encode(os.urandom(32)).decode('utf-8')

		success = create_server(args_arr.port, data_path, args_arr.type, args_arr.version, args_arr.java_home, rcon_password, args_arr.rcon_port)
		if success:
			args_arr.version = success
		server_id = uuid.uuid4().hex

		if not success:
			log_error("server creation failed")
			sys.exit(1)

		self.config.servers.register_server(args_arr.server_name, {
					"server_id": str(server_id),
					"server_port": str(args_arr.port),
					"server_type": str(args_arr.type),
					"server_version": str(args_arr.version),
					"rcon_password": str(rcon_password),
					"data_path": str(data_path),
					"java_home": str(args_arr.java_home),
					"rcon_port": str(args_arr.rcon_port)
				})
		self.config.servers.write_servers_conf()

	def delete(self):
		if len(self.args) < 1:
			log_error("delete: missing server name")
			stderr_print("delete: mccli delete <server name>")
			sys.exit(1)
		server_name = self.args[0]
		self.config.servers.check_server_exists_or_exit(server_name)
		self.config.servers.delete_server(server_name)
		self.config.servers.write_servers_conf() # write out the change

	def start(self):
		if len(self.args) < 1:
			log_error("start: missing server name")
			stderr_print("usage: mccli start <server name>")
			sys.exit(1)

		server_name = self.args[0]
		self.config.servers.check_server_exists_or_exit(server_name)
		self.config.servers.get_server(server_name).start()

	def stop(self):
		if len(self.args) < 1:
			log_error("stop: missing server name")
			stderr_print("usage: mccli stop <server name>")
			sys.exit(1)
		server_name = self.args[0]
		self.config.servers.check_server_exists_or_exit(server_name)
		print(self.config.servers.get_server(server_name).command("stop"))

	def path(self):
		parser = argparse.ArgumentParser(prog="mccli")
		parser.add_argument("server_name", nargs='?', help="The name of the server to be accessed. If not specified, the main MCCLI path will be provided.")
		args_arr = parser.parse_args(self.args)

		if args_arr.server_name is None:
			print(self.config.MCCLI_DIR)
		else:
			self.config.servers.check_server_exists_or_exit(args_arr.server_name)
			print(self.config.servers.get_server(args_arr.server_name).path())

	def logs(self):

		parser = argparse.ArgumentParser(prog="mccli")
		parser.add_argument("-l", "--list", action="store_true", help="List the existing log files.")
		parser.add_argument("-s", "--select", action="store_true", help="List the existing log files and prompt to select a file.")
		parser.add_argument("-i", "--index", type=int, help="Show the INDEX'th previous log file. e.g. -i 1 shows the latest log, and -i 2 the previous log.")
		parser.add_argument("-f", "--follow", action="store_true",
							help="Open the log file with tail -f. Conflicts with -t.")
		parser.add_argument("-t", "--tail", default=24, type=int,
							help="Number of lines to show in the log file. Conflicts with -f")
		parser.add_argument("server_name", help="The name of the server to be accessed.")
		args_arr = parser.parse_args(self.args)

		server_name = args_arr.server_name
		self.config.servers.check_server_exists_or_exit(server_name)
		self.config.servers.get_server(server_name).logs(args_arr.list, args_arr.select, args_arr.index, args_arr.follow, args_arr.tail)

	def cmd(self):
		parser = argparse.ArgumentParser(prog="mccli")
		parser.add_argument("-c", "--cmd", help="The command to execute. Opens an interactive console if not provided.")
		parser.add_argument("server_name", help="The name of the server to run the command on.")
		args_arr = parser.parse_args(self.args)

		server_name = args_arr.server_name
		self.config.servers.check_server_exists_or_exit(server_name)
		if args_arr.cmd is not None:
			cmds = args_arr.cmd.split(self.config.MCCLI_DELIMITER)
			for cmd in cmds:
				print(self.config.servers.get_server(server_name).command(cmd.strip()))
		else:
			self.config.servers.get_server(server_name).command()

	def status(self):
		if len(self.args) < 1:
			log_error("status: missing server name")
			stderr_print("usage: mccli status <server name>")
			sys.exit(1)
		server_name = self.args[0]
		self.config.servers.check_server_exists_or_exit(server_name)
		server = self.config.servers.get_server(server_name)
		server_data = server.get_server_data()
		running = self.config.servers.get_server(server_name).running()
		if running:
			query = server.query()
			pid = server.get_pid()
			proc_data = subprocess.run(["bash", self.config.SCRIPT_ROOT+"/util/procstats.sh", str(pid)], text=True, capture_output=True).stdout.strip().split("\t")
			print(f"Version: {server_data['server_version']}\nPlayers Online: {query['numplayers']}/{query['maxplayers']}\nMOTD: {query['motd']}")
			print(f"PID: {pid}, Started: {proc_data[8]}\n%CPU: {proc_data[2]}, %MEM: {proc_data[3]}")
			print(self.config.servers.get_server(server_name).command("list"))
		else:
			print(f"Server {server_name} not running.")

	def info(self):
		if len(self.args) < 1:
			log_error("info: missing server name")
			stderr_print("usage: mccli info <server name>")
			sys.exit(1)
		server_name = self.args[0]
		self.config.servers.check_server_exists_or_exit(server_name)
		server_data=self.config.servers.get_server_info(server_name)
		running_test = self.config.servers.get_server(server_name).running()
		running = "Yes" if running_test else "No"

		print(server_name+" info:")
		print("Running: "+running)
		print("Port: "+server_data["server_port"])
		print("RCON Port: "+server_data["rcon_port"])
		print("Data folder: "+server_data["data_path"])
		print("Type: "+server_data["server_type"])
		print("Minecraft version: "+server_data["server_version"])
		print("Java home: "+server_data["java_home"])

	def help(self):
		subprocess.run([self.config.SCRIPT_ROOT+"/commands/help.sh"]+self.args)

	def version(self):
		print(self.config.MCCLI_VERSION)

	def list(self):

		parser = argparse.ArgumentParser(prog="mccli")
		parser.add_argument("-l", "--long", action="store_true", help="List servers in long format")
		parser.add_argument("-n", "--name-only", action="store_true", help="List only server names")
		args_arr = parser.parse_args(self.args)

		if args_arr.long:
			for server_name in self.config.servers.get_server_names():
				server = self.config.servers.get_server(server_name)
				data = server.get_server_data()
				print(
					server_name + "\t" +
					("RUNNING" if server.running() else "       ") + "\t" +
					data["server_port"] + "\t" +
					data["server_version"] + "\t" +
					data["server_type"] + "\t" +
					server.path() + "\t"
				)
		elif args_arr.name_only:
			for server in self.config.servers.get_server_names():
				print(server)
		else:
			for server_name in self.config.servers.get_server_names():
				server = self.config.servers.get_server(server_name)
				data = server.get_server_data()
				print(("(Running)" if server.running() else "         ") + " " + server_name + "\t" + f":{data['server_port']}" + "\t" + f"{data['server_type']} {data['server_version']}" + "\t")