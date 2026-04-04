import sys
from utils import *
from servers import Servers

class Config:
	MCCLI_VERSION = "1.0.0"
	MCCLI_DIR = None
	MCCLI_PYTHON=None
	MCCLI_DOCKER=None
	MCCLI_SCREEN=None
	MCCLI_EULA=None
	SCRIPT_ROOT=None
	servers = None
	config_path = None

	def init_servers(self, conf_path):
		self.servers = Servers(conf_path)


	def read_config(self):
		with open(self.MCCLI_DIR+"/config.conf") as config_file:
			for line in config_file:
				key = line.split("=")[0]
				value = "=".join(line.split("=")[1:])
				if key == "USE_DOCKER":
					self.MCCLI_DOCKER = (value == "true")
				elif key == "USE_SCREEN":
					self.MCCLI_SCREEN = (value == "true")
				elif key == "PYTHON_PATH":
					self.MCCLI_PYTHON = (value == "true")
				elif key == "AGREED_EULA":
					self.MCCLI_EULA = (value == "true")

	def write_config(self):
		with open(self.MCCLI_DIR+"/config.conf", "w") as config_file:
			config_file.write("VERSION="+self.MCCLI_VERSION+"\n")
			config_file.write("USE_DOCKER="+bool_str(self.MCCLI_DOCKER))
			config_file.write("USE_SCREEN="+bool_str(self.MCCLI_SCREEN))
			config_file.write("PYTHON_PATH="+bool_str(self.MCCLI_PYTHON))
			config_file.write("AGREED_EULA="+bool_str(self.MCCLI_EULA))

