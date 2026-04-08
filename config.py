from utils import *
from servers import Servers

class Config:
	MCCLI_VERSION = "1.0.0"
	MCCLI_DIR = None
	MCCLI_PYTHON=""
	#MCCLI_SCREEN=False
	MCCLI_EULA=False
	MCCLI_DELIMITER="|"
	SCRIPT_ROOT=None
	servers = None
	config_path = None

	def init_servers(self, conf_path):
		self.servers = Servers(conf_path, self)


	def read_config(self):
		with open(self.MCCLI_DIR+"/config.conf") as config_file:
			for line in config_file:
				key = line.split("=")[0]
				value = "=".join(line.split("=")[1:])
				#if key == "USE_SCREEN":
				#	self.MCCLI_SCREEN = (value == "true")
				if key == "AGREED_EULA":
					self.MCCLI_EULA = (value == "true")
				elif key == "CMD_DELIMITER":
					self.MCCLI_DELIMITER = value.strip()

	def write_config(self):
		with open(self.MCCLI_DIR+"/config.conf", "w") as config_file:
			config_file.write("VERSION="+self.MCCLI_VERSION+"\n")
			#config_file.write("USE_SCREEN="+bool_str(self.MCCLI_SCREEN)+"\n")
			config_file.write("AGREED_EULA="+bool_str(self.MCCLI_EULA)+"\n")
			config_file.write("CMD_DELIMITER="+self.MCCLI_DELIMITER+"\n")

