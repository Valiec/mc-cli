import sys
from utils import *

class Config:
	MCCLI_VERSION = "1.0.0"
	MCCLI_DIR = None
	MCCLI_PYTHON=None
	MCCLI_DOCKER=None
	MCCLI_SCREEN=None
	MCCLI_EULA=None
	SCRIPT_ROOT=None
	servers = {}
	servers_info = {}


	def check_server_exists(self, server_name):
		if not server_name in self.servers:
			log_error("server "+server_name+" does not exist")
			sys.exit(1)