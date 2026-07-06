#!/bin/bash
echo "Building Flutter web application for UAT environment"

# Set environment variables
export ENVIRONMENT=UAT

# Clean and build web application
echo "Cleaning previous builds..."
flutter clean

echo "Building web application..."
flutter build web --release --web-renderer html

echo "Web application built successfully! Files are in build/web directory"
