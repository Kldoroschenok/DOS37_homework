#!/usr/bin/python
import socket
import os
import pwd
user_name = pwd.getpwuid(os.getuid())[0]
host_name = socket.gethostname()
print(f"Hello, {user_name} you inside in {host_name}")
