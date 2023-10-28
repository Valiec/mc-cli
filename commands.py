import subprocess
import sys
import argparse
import os
import base64

# other parts of MC-CLI
from utils import *
from config import Config
from servers import Servers

class Commands:
	config = None
	args = []

	def __init__(self, config, args):
		self.config = config
		self.args = args

	def create(self):
		parser = argparse.ArgumentParser(prog="mccli")
		parser.add_argument("-t", "--type", default="VANILLA", help="The type of server to create.")
		parser.add_argument("-v", "--version", default="LATEST", help="The Minecraft version of the server to be created.")
		parser.add_argument("-j", "--java-version", default="latest", help="The Java version for the server to be created. Only used for Docker installations.")
		parser.add_argument("-J", "--java-home", default=os.getenv("JAVA_HOME"), help="The JAVA_HOME location for the server to be created. Only used for non-Docker installations.")
		parser.add_argument("-r", "--rcon-password", help="A custom password for the RCON remote console. If you are not using RCON elsewhere, \
			do not expose the RCON port to the internet, and skip this option to have MCCLI generate a random RCON password.")
		parser.add_argument("-p", "--data-path", help="The Minecraft version of the server to be created.")
		parser.add_argument("server_name", help="The name of the server to be created.")
		parser.add_argument("port", help="The port the new server will run on.")
		args_arr = parser.parse_args(self.args)

		self.config.servers.check_server_exists(args_arr.server_name)

		data_path = args_arr.data_path

		if data_path is None:
			data_path = os.getenv(MCCLI_DIR)+"/servers/"+args_arr.server_name

		if os.path.exists(data_path) and not os.path.isdir(data_path):
			log_error("data path "+data_path+" already exists and is not a directory")
			sys.exit(1)

		os.mkdirs(data_path, exist_ok=True)

		if args.rcon_password is None:
			if os.path.exists(data_path+"/server.properties"):
				with open(data_path+"/server.properties") as server_properties:
					for line_s in server_properties:
						line = line_s.split("=", 1)
						if line[0] == "rcon.password":
							rcon_password = line[1].strip("\n")
			else:
				rcon_password = base64.b64encode(os.urandom(32))

		server_creation_proc = None

		if self.config.MCCLI_DOCKER:
			server_creation_proc = subprocess.run(["bash", self.config.SCRIPT_ROOT+"/commands/create.sh", args_arr.port, args_arr.data_path, args_arr.type, args_arr.version, args_arr.java_version, rcon_password], capture_output=True)
		else:
			server_creation_proc = subprocess.run(["bash", self.config.SCRIPT_ROOT+"/commands/create_nodocker.sh", args_arr.port, args_arr.data_path, args_arr.type, args_arr.version, args_arr.java_home, rcon_password], capture_output=True)

		success = server_creation_proc.returncode

		if success > 0:
			log_error("server creation failed")
			sys.exit(1)

		server_id = server_creation_proc.stdout.strip("\n")

		config.servers.register_server(server_name, {
					"server_id": server_id,
					"server_port": args_arr.port,
					"server_type": args_arr.type,
					"server_version": args_arr.version,
					"java_version": args_arr.java_version,
					"rcon_password": rcon_password,
					"data_path": args_arr.data_path,
					"java_home": args_arr.java_home
				})

	def delete(self):
		if len(self.args) < 1:
			log_error("delete: missing server name")
			stderr_print("delete: mccli stop <server name>")
			sys.exit(1)
		server_name = self.args[0]
		self.config.servers.check_server_exists(server_name)
		server_id=self.config.servers.get_server_id(server_name)
		subprocess.run([self.config.SCRIPT_ROOT+"/commands/delete.sh", server_id])
		config.servers.delete_server(server_name)

	def start(self):
		if len(self.args) < 1:
			log_error("start: missing server name")
			stderr_print("usage: mccli start <server name>")
			sys.exit(1)

		server_name = self.args[0]
		self.config.servers.check_server_exists(server_name)
		server_id=self.config.servers.get_server_id(server_name)

		if self.config.MCCLI_DOCKER:
			subprocess.run(["docker", "start", server_id])
		else:
			server_info = self.config.servers.get_server_info(server_name)
			data_dir = server_info["data_dir"]
			java_home = server_info["java_home"]

			if not os.path.exists(data_dir+"/eula.txt"):
				if self.config.MCCLI_EULA:
					with open(data_dir+"/eula.txt", "w") as eula_file:
						eula_file.write("eula=true\n")
				else:
					print("You must agree to the Minecraft EULA to start the server.")
					if input("agree? [Y/n]: ") != "Y":
						print("Exiting.")
						sys.exit(1)
					print("Your EULA agreement will been saved for future servers.")
					with open(data_dir+"/eula.txt", "w") as eula_file:
						eula_file.write("eula=true\n")

					# User has accepted the EULA, save this and don't prompt again
					self.config.MCCLI_EULA = True

			subprocess.run(["bash", self.config.SCRIPT_ROOT+"/util/start_server.sh", server_name, data_dir, java_home])

	def stop(self):
		if len(self.args) < 1:
			log_error("stop: missing server name")
			stderr_print("usage: mccli stop <server name>")
			sys.exit(1)
		server_name = self.args[0]
		self.config.servers.check_server_exists(server_name)
		server_id=self.config.servers.get_server_id(server_name)
		subprocess.run([self.config.SCRIPT_ROOT+"/commands/cmd.sh", server_id, "stop"])

	def logs(self):
		if len(self.args) < 1:
			log_error("logs: missing server name")
			stderr_print("usage: mccli logs <server name>")
			sys.exit(1)
		server_name = self.args[0]
		self.config.servers.check_server_exists(server_name)
		server_id=self.config.servers.get_server_id(server_name)
		subprocess.run([self.config.SCRIPT_ROOT+"/commands/logs.sh", server_id])

	def rcon(self):
		if len(self.args) < 1:
			log_error("rcon: missing server name")
			stderr_print("usage: mccli rcon <server name>")
			sys.exit(1)
		server_name = self.args[0]
		self.config.servers.check_server_exists(server_name)
		server_id=self.config.servers.get_server_id(server_name)
		subprocess.run([self.config.SCRIPT_ROOT+"/commands/cmd_interactive.sh", server_id])

	def cmd(self):
		pass
		if len(self.args) < 1:
			log_error("cmd: missing server name")
			stderr_print("usage: mccli cmd <server name> <command>")
			sys.exit(1)
		elif len(self.args) < 1:
			log_error("cmd: missing command")
			stderr_print("usage: mccli cmd <server name> <command>")
			sys.exit(1)
		server_name = self.args[0]
		cmd = self.args[1]
		self.config.servers.check_server_exists(server_name)
		server_id=self.config.servers.get_server_id(server_name)
		subprocess.run([self.config.SCRIPT_ROOT+"/commands/cmd.sh", server_id, cmd])

	def status(self):
		if len(self.args) < 1:
			log_error("status: missing server name")
			stderr_print("usage: mccli status <server name>")
			sys.exit(1)
		server_name = self.args[0]
		self.config.servers.check_server_exists(server_name)
		server_id=self.config.servers.get_server_id(server_name)
		subprocess.run([self.config.SCRIPT_ROOT+"/commands/status.sh", server_id])

	def info(self):
		if len(self.args) < 1:
			log_error("info: missing server name")
			stderr_print("usage: mccli info <server name>")
			sys.exit(1)
		server_name = self.args[0]
		self.config.servers.check_server_exists(server_name)
		server_id=self.config.servers.get_server_id(server_name)
		server_data=self.config.servers.get_server_info(server_name)
		running_test = (subprocess.run([self.config.SCRIPT_ROOT+"/util/check_running.sh", server_id, server_data["data_dir"], bool_str(config.MCCLI_DOCKER)]).exitcode == 0)
		running = "Yes" if running_test else "No"

		print(server_name+" info:")
		if MCCLI_DOCKER:
			print("Container ID: "+server_id)
		print("Running: "+running)
		print("Port: "+server_data["server_port"])
		print("Data folder: "+server_data["data_path"])
		print("Type: "+server_data["server_type"])
		print("Minecraft version: "+server_data["server_version"])
		print("Java version: "+server_data["java_version"])
		print("Java home: "+server_data["java_home"])

	def help(self):
		subprocess.run([self.config.SCRIPT_ROOT+"/commands/help.sh"]+self.args)

	def version(self):
		print(self.config.MCCLI_VERSION)

	def list(self):
		for server in self.config.servers.get_server_names():
			print(server+": "+self.config.servers.get_server_id(server))