import sys
from utils import *

class Servers:
	servers = {}
	servers_data = {}
	used_ports = []
	conf_path = None

	def __init__(self, conf_path):
		self.conf_path = conf_path

	def check_server_exists(self, server_name):
		if not server_name in self.servers:
			log_error("server "+server_name+" does not exist")
			sys.exit(1)

	def delete_server(self, server_name):
		del self.servers[server_name]
		del self.servers_info[server_name]

	def get_server_id(self, server_name):
		return self.servers[server_name]

	def get_server_names(self):
		return self.servers.keys()

	get_server_info:

	def register_server(self, server_name, server_data):
		self.servers[server_name] = server_data["server_id"]
		self.servers_data[server_name] = server_data
		self.used_ports.append(server_data["server_port"])

	def read_servers_conf(self):
		with open(self.conf_path) as servers_conf:
			for line in servers_conf:
				server_data_str = line.split("\t")
				server_name = server_data_str[0]
				server_data = {
					"server_id": server_data_str[1],
					"server_port": server_data_str[2],
					"server_type": server_data_str[3],
					"server_version": server_data_str[4],
					"java_version": server_data_str[5],
					"rcon_password": server_data_str[6],
					"data_path": server_data_str[7],
					"java_home": server_data_str[8]
				}
				self.register_server(server_name, server_data)

	def write_servers_conf(self):
		with open(self.conf_path, "w") as servers_conf:
			for server in self.get_server_names:
				info_list = [server_name, server_data["server_id"], server_data["server_port"], server_data["server_type"], server_data["server_version"], 
				server_data["java_version"], server_data["rcon_password"], server_data["data_path"], server_data["java_home"]]
				info_str = "\t".join(info_list)
				servers_conf.write(info_str+"\n")


				
				
		