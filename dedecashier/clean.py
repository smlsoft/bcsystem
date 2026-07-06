import subprocess

commands = ['clean', 'pub upgrade','pub get']
for command in commands:
    subprocess.run('flutter ' + command, shell=True)
