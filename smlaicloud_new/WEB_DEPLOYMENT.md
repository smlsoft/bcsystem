# Web Deployment Guide

## Issue Resolution: Flutter Web CORS and URL Handling

This document outlines the changes made to resolve CORS issues and URL handling for the Flutter web application.

## Resolved Issues

1. **CORS Issues**: Fixed CORS-related errors when running the application in a web browser by:
   - Adding proper CORS headers to all API requests
   - Updating CORS configuration in cors.json

2. **URL Handling**: Ensured all API URLs are formed as absolute URLs by:
   - Adding URL prefix checks to all API calls
   - Properly formatting API URLs for both web and desktop environments

3. **Base Href Fix**: Implemented dynamic base href calculation in index.html to ensure proper path resolution in web mode.

## Building the Application

### For Web Deployment

Use the provided scripts to build the web version:

**Windows:**
```
build_web.bat
```

**Linux/Mac:**
```
chmod +x build_web.sh
./build_web.sh
```

These scripts will build the web application without using the `--flavor` parameter, which is not supported for web.

### For Windows Desktop

Continue using your existing build process for Windows desktop, but be aware of the `--flavor` limitation.

**Warning:** The `--flavor` parameter is only supported for Android, macOS, and iOS, not for Windows. When building for Windows, you may need to adjust your build command or configuration.

## Backend Configuration

If you continue experiencing CORS issues, ensure your API backend server has proper CORS configuration. The server should include the following headers in all responses:

```
Access-Control-Allow-Origin: *
Access-Control-Allow-Methods: GET, POST, OPTIONS, PUT, DELETE
Access-Control-Allow-Headers: Content-Type, Authorization
```

## Testing

After building, test the application thoroughly in both web browser and Windows desktop environments to ensure all API connections work correctly.
