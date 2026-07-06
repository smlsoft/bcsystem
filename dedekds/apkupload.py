import os
import subprocess
import datetime
from ftplib import FTP
import re

ftpServer=os.environ["FTP_HOST"]
ftpUser=os.environ["FTP_USER"]
ftpPass=os.environ["FTP_PASSWORD"]
ftpPath = "/public_html/downloads"

# Define the command as a list of strings
command = [
    'flutter',
    'build',
    'apk',
    '--release',
]

# Run the command
subprocess.run(command, shell=True)
buildDir = r'build\app\outputs\flutter-apk'
apkFileName = 'app-release.apk'
firstFileName = 'dede_kds_'

# Generate a new file name based on the current date and time
now = datetime.datetime.now()
newFileName = firstFileName + now.strftime("%Y%m%d%H%M%S") + '.apk'

# Rename the file to the new name
os.rename(os.path.join(buildDir, apkFileName), os.path.join(buildDir, newFileName))
print("\n")
print(f"File renamed to: {newFileName}")

# Upload file to FTP server
try:
    with FTP(ftpServer) as ftp:
        ftp.login(ftpUser, ftpPass)
        ftp.cwd(ftpPath)
        
        # Delete old version if it exists
        oldFiles = ftp.nlst()
        for file in oldFiles:
            if re.match(rf'{firstFileName}\d+.apk', file):
                ftp.delete(file)
                print(f"Deleted ftp server : old file : {file}")        
        ftp.quit()
        
        
    with FTP(ftpServer) as ftp:
        ftp.login(ftpUser, ftpPass)
        ftp.cwd(ftpPath)
        with open(os.path.join(buildDir, newFileName), 'rb') as file:
            ftp.storbinary(f"STOR {newFileName}", file)
        print(f"File {newFileName} uploaded successfully to {ftpServer}:{ftpPath}")
        ftp.quit()
except Exception as e:
    print(f"Error uploading file to FTP server: {e}")
    
    
