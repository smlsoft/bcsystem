import os
import subprocess
import datetime
from ftplib import FTP
import re

ftpServer=os.environ["FTP_HOST"]
ftpUser=os.environ["FTP_USER"]
ftpPass=os.environ["FTP_PASSWORD"]
ftpPath = "/public_html/downloads"

commands = ['clean', 'pub upgrade','pub get']
for xcommand in commands:
    subprocess.run('flutter ' + xcommand, shell=True)


# Define the command as a list of strings
command = [
    'flutter',
    'build',
    'apk',
    '--release',
    '--no-tree-shake-icons',
]

# Run the command
subprocess.run(command, shell=True)
buildDir = r'build\app\outputs\flutter-apk'
apkFileName = 'app-release.apk'
firstFileName = 'dede_order_'

# Generate a new file name based on the current date and time
now = datetime.datetime.now()
newFileName = firstFileName + now.strftime("%Y-%m-%d-%H-%M-%S") + '.apk'

# Rename the file to the new name
os.rename(os.path.join(buildDir, apkFileName), os.path.join(buildDir, newFileName))
print("\n")
print(f"File renamed to: {newFileName}")

