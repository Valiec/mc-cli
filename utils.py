import sys

def bool_str(bool):
	return "true" if bool else "false"

def stderr_print(msg):
	sys.stderr.write(msg+"\n")

def log_error(msg, prefix="mccli: "): 
	stderr_print(prefix+str(msg))


