import os
import subprocess
import datetime
import re

commands = ['clean', 'pub upgrade','pub get']
for xcommand in commands:
    subprocess.run('flutter ' + xcommand, shell=True)

# Define the command as a list of strings
command = [
    'flutter',
    'build',
    'windows',
    '-t',
    'lib/main.dart',
    '--dart-define=ENVIRONMENT=DEV'
]

# Run the command
subprocess.run(command, shell=True)

command = [
    'flutter',
    'pub',
    'run',
    'msix:create',
    '--build-windows',
    'false'
]

# Run the command
subprocess.run(command, shell=True)

buildDir = r'build\windows\x64\runner\Release'
msixFileName = 'dedeorder.msix'
firstFileName = 'dede_staff_windows_'

# Generate a new file name based on the current date and time
now = datetime.datetime.now()
newFileName = firstFileName + now.strftime("%Y-%m-%d-%H-%M-%S") + '.msix'

# Rename the file to the new name
os.rename(os.path.join(buildDir, msixFileName), os.path.join(buildDir, newFileName))
print("\n")
print(f"File renamed to: {newFileName}")

