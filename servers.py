import glob
import os
import shutil
import subprocess
import time

from mctools import RCONClient
from mctools import QUERYClient

from utils import *

class Server:
	server_name = None
	server_data = None
	servers = None

	def __init__(self, server_name, server_data, servers):
		self.server_name = server_name
		self.server_data = server_data
		self.servers = servers

	def get_server_id(self):
		return self.server_data["server_id"]

	def get_server_data(self):
		return self.server_data

	def delete(self):
		if os.path.exists(os.path.join(self.server_data["data_path"])):
			if os.path.exists(os.path.join(self.server_data["data_path"], ".running")):
					self.command("stop")
			while os.path.exists(os.path.join(self.server_data["data_path"], ".running")):
				time.sleep(1)
			shutil.rmtree(os.path.join(self.server_data["data_path"]))


	def running(self):
		if os.path.exists(self.server_data["data_path"]):
			return os.path.exists(os.path.join(self.server_data["data_path"], ".running"))
		else:
			return False

	def query(self):
		query = QUERYClient('127.0.0.1', port=self.server_data["server_port"])
		stats = query.get_basic_stats()
		query.stop()
		return stats

	def logs(self, list_logs=False, select_log=False, log_index=None, follow=False, tail_lines=24):
		logs = glob.glob(os.path.join(self.server_data["data_path"], "mccli_*.log"))
		logs.sort()
		selected_log = logs[-1]

		if log_index is not None:
			# 1 is -1, i.e. the latest, 2 is -2 the next to last, etc.
			if log_index > len(logs):
				log_error(f"Log index {log_index} out of range.")
				return False
			selected_log = logs[-1*int(log_index)]

		if list_logs or select_log:
			i = 1
			for log in logs:
				if select_log:
					print(f"{i}) {os.path.basename(log)}")
				else:
					print(os.path.basename(log))
				i += 1
			if not select_log:
				return True

		if select_log:
			log_index = input("Select log: ")
			selected_log = logs[int(log_index)-1]

		if follow:
			subprocess.run(["tail", "-f", selected_log])
		else:
			subprocess.run(["tail", "-n", str(tail_lines), selected_log])

		return True


	def get_pid(self):
		if os.path.exists(os.path.join(self.server_data["data_path"],".running")):
			with open(os.path.join(self.server_data["data_path"],".running")) as f:
				return int(f.read().strip())
		else:
			return None

	def path(self):
		return self.server_data["data_path"]

	def command(self, command=None):
		rcon = RCONClient("127.0.0.1", port=int(self.server_data["rcon_port"]))
		try:
			rcon.login(self.server_data["rcon_password"])
		except ConnectionRefusedError:
			log_error(f"server {self.server_name} rcon connection failed, server may be still starting")
			exit(1)
		resp = None
		if command is None:
			prompt = f"{self.server_name} > "
			try:
				while True:
					cmd = input(prompt)
					print(rcon.command(cmd))
			except KeyboardInterrupt:
				sys.exit(0)
		else:
			resp = rcon.command(command)
		rcon.stop()
		return resp

	def start(self):
		server_info = self.server_data
		data_dir = server_info["data_path"]
		java_home = server_info["java_home"]

		if not os.path.exists(os.path.join(data_dir, "eula.txt")):
			if self.servers.config.MCCLI_EULA:
				with open(os.path.join(data_dir, "eula.txt"), "w") as eula_file:
					eula_file.write("eula=true\n")
			else:
				print("You must agree to the Minecraft EULA to start the server.")
				if input("agree? [Y/n]: ") != "Y":
					print("Exiting.")
					sys.exit(1)
				print("Your EULA agreement will been saved for future servers.")
				with open(os.path.join(data_dir, "eula.txt"), "w") as eula_file:
					eula_file.write("eula=true\n")
				# User has accepted the EULA, save this and don't prompt again
				self.servers.config.MCCLI_EULA = True
				self.servers.config.write_config()

		subprocess.Popen(["bash", os.path.join(self.server_data["data_path"],"start.sh")])
		print(f"Server {self.server_name} starting.")

	def stop(self):
		self.command("stop")


class Servers:
	servers = {}
	used_ports = []
	conf_path = None
	config = None

	def __init__(self, conf_path, config):
		self.conf_path = conf_path
		self.config = config

	def get_free_port(self):
		port_num = 25565
		while port_num in self.used_ports:
			port_num += 1
		return port_num

	def get_free_rcon_port(self):
		port_num = 25575
		while port_num in self.used_ports:
			port_num += 1
		return port_num

	def server_exists(self, server_name):
		return server_name in self.servers

	def check_server_exists_or_exit(self, server_name):
		if not self.server_exists(server_name):
			log_error("server "+server_name+" does not exist")
			sys.exit(1)

	def delete_server(self, server_name):
		self.servers[server_name].delete()
		del self.servers[server_name]

	def get_server_id(self, server_name):
		return self.servers[server_name].get_server_id()

	def get_server(self, server_name):
		return self.servers[server_name]

	def get_server_names(self):
		return self.servers.keys()

	def get_server_info(self, server_name):
		return self.servers[server_name].get_server_data()

	def register_server(self, server_name, server_data):
		self.servers[server_name] = Server(server_name, server_data, self)
		self.used_ports.append(int(server_data["server_port"]))
		self.used_ports.append(int(server_data["rcon_port"]))

	def read_servers_conf(self):
		with open(self.conf_path) as servers_conf:
			for line in servers_conf:
				server_data_str = line.strip().split("\t")
				server_name = server_data_str[0]
				server_data = {
					"server_id": server_data_str[1],
					"server_port": server_data_str[2],
					"server_type": server_data_str[3],
					"server_version": server_data_str[4],
					"server_mod_version": server_data_str[5],
					"rcon_password": server_data_str[6],
					"data_path": server_data_str[7],
					"java_home": server_data_str[8],
					"rcon_port": server_data_str[9]
				}
				self.register_server(server_name, server_data)

	def write_servers_conf(self):
		with open(self.conf_path, "w") as servers_conf:
			for server_name in self.get_server_names():
				server_data = self.get_server_info(server_name)
				info_list = [server_name, server_data["server_id"], server_data["server_port"], server_data["server_type"], server_data["server_version"], server_data["server_mod_version"], server_data["rcon_password"], server_data["data_path"], server_data["java_home"], server_data["rcon_port"]]
				info_str = "\t".join(info_list)
				servers_conf.write(info_str+"\n")


				
				
		