import argparse
import sys
from mcrcon import MCRcon


port = sys.argv[1]

rcon_password = sys.argv[2]

cmd = None

if len(sys.argv) >= 4:
	cmd = sys.argv[3]

with MCRcon("localhost:"+port, rcon_password) as server:
	if cmd is not None:
		print(mcr.command("/"+cmd))
	else:
		while True:
			cmd = input("rcon> ")
			print(mcr.command("/"+cmd))