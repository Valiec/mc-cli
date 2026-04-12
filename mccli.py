# other parts of MC-CLI
from commands import Commands
from utils import *
from config import Config
from version_cache import VersionCache

config = Config()

os.environ["MCCLI_VERSION"] = config.MCCLI_VERSION
config.SCRIPT_ROOT = os.environ["SCRIPT_ROOT"]

def parse_config():
	if not "MCCLI_DIR" in os.environ:
		if os.path.exists(os.path.join(os.environ['HOME'], ".mccli_dir")):
			with open(os.path.join(os.environ['HOME'], ".mccli_dir"), "w") as mccli_dir_file:
				config.MCCLI_DIR = mccli_dir_file.read().strip("\n")
		else:
				config.MCCLI_DIR = str(os.path.join(os.environ['HOME'],".mccli"))
		os.environ["MCCLI_DIR"] = config.MCCLI_DIR
	else:
		config.MCCLI_DIR = os.environ["MCCLI_DIR"]


	# if config.MCCLI_DIR exists, but it's not a directory
	if os.path.exists(config.MCCLI_DIR) and not os.path.isdir(config.MCCLI_DIR):
		log_error("config path "+config.MCCLI_DIR+" already exists and is not a directory")
		sys.exit(1)

	# if $config.MCCLI_DIR does not exist, create it and the servers file
	if not os.path.exists(config.MCCLI_DIR):
		os.mkdir(config.MCCLI_DIR)
		with open(os.path.join(config.MCCLI_DIR, "servers.conf"), "w") as servers_conf:
			servers_conf.write("")



	if not os.path.exists(os.path.join(config.MCCLI_DIR, "config.conf")):
		#if subprocess.run("which screen", shell=True).returncode == 0:
		#	config.MCCLI_SCREEN = (input("use Screen? [Y/n]: ") == "Y")
		#else:
		#	config.MCCLI_SCREEN = False

		config.write_config()

	else:
		config.read_config()

	config.init_servers(os.path.join(config.MCCLI_DIR, "servers.conf"))
	config.servers.read_servers_conf()

	cache = VersionCache(config)

	config.cache = cache


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
	commands.create()
elif action == "delete":
	commands.delete()
elif action == "start":
	commands.start()
elif action == "stop":
	commands.stop()
elif action == "logs":
	commands.logs()
elif action == "path":
	commands.path()
elif action == "cmd":
	commands.cmd()
elif action == "kill":
	commands.kill()
elif action == "status":
	commands.status()
elif action == "info":
	commands.info()
elif action == "version":
	commands.version()
elif action == "agree-eula":
	commands.agree_eula()
elif action == "help":
	commands.help()
else:
	log_error("invalid command: "+action)
	usage()
	exit(1)