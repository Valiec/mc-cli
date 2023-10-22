import sys
import os
import subprocess

# other parts of MC-CLI
from commands import Commands
from utils import *
from config import Config

config = Config()

os.environ["MCCLI_VERSION"] = config.MCCLI_VERSION
config.SCRIPT_ROOT = os.environ["SCRIPT_ROOT"]

def write_config():
	# rewrite the config file
	with open(config.MCCLI_DIR+"/config", "w") as config_file:
		config.write("VERSION="+config.MCCLI_VERSION+"\n")
		config.write("USE_DOCKER="+config.MCCLI_DOCKER+"\n")
		config.write("USE_SCREEN="+config.MCCLI_SCREEN+"\n")
		config.write("PYTHON_PATH="+config.MCCLI_PYTHON+"\n")
		config.write("AGREED_EULA="+config.MCCLI_EULA+"\n")

def parse_config():
	if not "MCCLI_DIR" in os.environ:
		if os.path.exists(os.environ['HOME']+"/.mccli_dir"):
			with open(os.environ['HOME']+"/.mccli_dir", "w") as mccli_dir_file:
				config.MCCLI_DIR = mccli_dir_file.read().strip("\n")
		else:
				config.MCCLI_DIR = os.environ['HOME']+"/.mccli"
		os.environ["MCCLI_DIR"] = config.MCCLI_DIR
	else:
		config.MCCLI_DIR = os.environ["MCCLI_DIR"]


	# if $config.MCCLI_DIR exists, but it's not a directory
	if os.path.exists(config.MCCLI_DIR) and not os.path.isdir(config.MCCLI_DIR):
		log_error("config path "+config.MCCLI_DIR+" already exists and is not a directory")
		sys.exit(1)

	# if $config.MCCLI_DIR does not exist, create it and the servers file
	if not os.path.exists(config.MCCLI_DIR):
		os.mkdir(config.MCCLI_DIR)
		with open(config.MCCLI_DIR+"/servers.conf", "w") as servers_conf:
			servers_conf.write("")



	if not os.path.exists(config.MCCLI_DIR+"/config"):
		with open(config.MCCLI_DIR+"/config", "w") as config_file:
			config_file.write("VERSION="+config.MCCLI_VERSION+"\n")

			if subprocess.run("which docker").exitcode == 0:
				config.MCCLI_DOCKER = (input("use Docker? [Y/n]: ") == "Y")
			else:
				config.MCCLI_DOCKER = False

			if subprocess.run("which screen").exitcode == 0:
				config.MCCLI_SCREEN = (input("use Screen? [Y/n]: ") == "Y")
			else:
				config.MCCLI_SCREEN = False

			python_which = subprocess.run("which python")

			config.MCCLI_PYTHON = os.environ["MCCLI_PYTHON"]

			config_file.write("USE_DOCKER="+bool_str(config.MCCLI_DOCKER))
			config_file.write("USE_SCREEN="+bool_str(config.MCCLI_SCREEN))
			config_file.write("PYTHON_PATH="+bool_str(config.MCCLI_PYTHON))
			config_file.write("AGREED_EULA=false")

	else:
		with open(config.MCCLI_DIR+"/config") as config_file:
			for line in config_file:
				key = line.split("=")[0]
				value = "=".join(line.split("=")[1:])
				if key == "USE_DOCKER":
					config.MCCLI_DOCKER = (value == "true")
				elif key == "USE_SCREEN":
					config.MCCLI_SCREEN = (value == "true")
				elif key == "PYTHON_PATH":
					config.MCCLI_PYTHON = (value == "true")
				elif key == "AGREED_EULA":
					config.MCCLI_EULA = (value == "true")

	if not os.path.isdir(config.MCCLI_DIR+"/venv"):
		subprocess.run(["python", "-m", "venv", config.MCCLI_DIR+"/venv"])
		subprocess.run([config.MCCLI_DIR+"/venv/bin/pip", "-qq", "install", "mcrcon"])

	config.init_servers(config.MCCLI_DIR+"/servers.conf")
	config.servers.read_servers_conf()


def usage():
	print("usage: mccli <subcommand> [args...]")

parse_config()

if len(sys.argv) == 1:
	log_error("no subcommand specified")
	usage()
	sys.exit(1)


action = sys.argv[1]

commands = Commands(config, sys.argv[2:])

if action == "list":
	commands.list()
elif action == "create":
	print("create")
elif action == "delete":
	commands.delete()
elif action == "start":
	print("start")
elif action == "stop":
	commands.stop()
elif action == "logs":
	commands.logs()
elif action == "rcon":
	commands.rcon()
elif action == "cmd":
	commands.cmd()
elif action == "status":
	commands.status()
elif action == "info":
	commands.info()
elif action == "version":
	commands.version()
elif action == "help":
	commands.help()
else:
	log_error("invalid command: "+action)
	usage()
	exit(1)