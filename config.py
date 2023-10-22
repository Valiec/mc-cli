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

	def init_servers(self, conf_path):
		self.servers = Servers(conf_path)
