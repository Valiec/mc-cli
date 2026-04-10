import os
import sys

def bool_str(bool_value):
	return "true" if bool_value else "false"

def stderr_print(msg):
	sys.stderr.write(msg+"\n")

def log_error(msg, level="error", prefix="mccli"):
	stderr_print(prefix+": "+level+": "+str(msg))


def pid_exists(pid):
	try:
		os.kill(pid, 0)
	except OSError:
		return False

	return True