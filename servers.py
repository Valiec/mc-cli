import os
import shutil
import sys
import time

from mctools import RCONClient
from mctools import QUERYClient

from utils import *

class Server:
	server_name = None
	server_data = None

	def __init__(self, server_name, server_data):
		self.server_name = server_name
		self.server_data = server_data

	def get_server_id(self):
		return self.server_data["server_id"]

	def get_server_data(self):
		return self.server_data

	def delete(self):
		if os.path.exists(os.path.join(self.server_data["data_path"])):
			if os.path.exists(os.path.join(self.server_data["data_path"], ".running")):
				with open(os.path.join(self.server_data["data_path"], ".running")) as f:
					self.command("stop")
			while os.path.exists(os.path.join(self.server_data["data_path"], ".running")):
				time.sleep(1)
			shutil.rmtree(os.path.join(self.server_data["data_path"]))


	def is_running(self):
		pass

	def query(self):
		query = QUERYClient('127.0.0.1', port=self.server_data["server_port"])
		stats = query.get_basic_stats()
		query.stop()
		return stats

	def get_pid(self):
		if os.path.exists(os.path.join(self.server_data["data_path"],".running")):
			with open(os.path.join(self.server_data["data_path"],".running")) as f:
				return int(f.read().strip())
		else:
			return None

	def command(self, command=None):
		rcon = RCONClient("127.0.0.1", port=int(self.server_data["rcon_port"]))
		rcon.login(self.server_data["rcon_password"])
		resp = None
		if command is None:
			try:
				while True:
					cmd = input("rcon> ")
					print(rcon.command(cmd))
			except KeyboardInterrupt:
				sys.exit(0)
		else:
			resp = rcon.command(command)
		rcon.stop()
		return resp

	def start(self):
		pass

	def stop(self):
		self.command("stop")


class Servers:
	servers = {}
	used_ports = []
	conf_path = None

	def __init__(self, conf_path):
		self.conf_path = conf_path

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

	def check_server_exists(self, server_name):
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
		self.servers[server_name] = Server(server_name, server_data)
		self.used_ports.append(server_data["server_port"])
		self.used_ports.append(server_data["rcon_port"])

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
					"java_version": server_data_str[5],
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
				info_list = [server_name, server_data["server_id"], server_data["server_port"], server_data["server_type"], server_data["server_version"], 
				server_data["java_version"], server_data["rcon_password"], server_data["data_path"], server_data["java_home"], server_data["rcon_port"]]
				info_str = "\t".join(info_list)
				servers_conf.write(info_str+"\n")


				
				
		