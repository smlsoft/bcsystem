#!/bin/bash

# Step 1: Build the APK
flutter build apk --dart-define=ENVIRONMENT=PROD

# Check if the build process was successful
if [ $? -eq 0 ]; then
    echo "Build Successful"

    # Step 2: Get the current date and time
    current_date_time=$(date '+%Y%m%d_%H%M%S')

    # Step 3: Rename and move the APK
    mv build/app/outputs/flutter-apk/app-release.apk build/app/outputs/flutter-apk/dede-order-station-app-release-$current_date_time.apk

    echo "APK renamed to dede-order-station-app-release-$current_date_time.apk"

    # Define FTP credentials and remote directory
    ftp_server="${FTP_HOST}"
    ftp_username="${FTP_USER}"
    ftp_password="${FTP_PASSWORD}"
    remote_directory='/public_html/downloads'

    # Disable SSL verification (Insecure)
    echo "set ssl:verify-certificate no" >> ~/.lftprc

    # Step 4: Remove old APK versions on the FTP server using lftp
    echo "Removing old APK versions from $ftp_server..."
    lftp -u $ftp_username, $ftp_password $ftp_server <<EOF
cd $remote_directory
mrm dede-order-station-app-release-*.apk
quit
EOF

    # Step 5: Upload the APK to the FTP server
    echo "Uploading APK to $ftp_server..."
    lftp -u $ftp_username, $ftp_password $ftp_server <<EOF
cd $remote_directory
put build/app/outputs/flutter-apk/dede-order-station-app-release-$current_date_time.apk
quit
EOF

    echo "APK successfully uploaded to $ftp_server"

else
    echo "Build Failed"
fi
