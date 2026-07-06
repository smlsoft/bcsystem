# API Connection in Flutter Web - Testing Notes

## Overview
This document provides information on testing the Flutter web application's API connections, particularly focusing on resolving CORS issues and ensuring proper URL handling.

## Main Changes Made to Fix API Connection Issues

1. **Absolute URL Handling**
   - Modified all API call functions to ensure URLs always start with proper protocol (https://)
   - Implemented proper prefixing: `if (!apiPath.startsWith('http')) { apiPath = 'https://' + apiPath; }`

2. **CORS Headers**
   - Added CORS headers to all API requests:
   ```dart
   headers: {
     'Content-Type': 'application/json',
     'Access-Control-Allow-Origin': '*',
   }
   ```

3. **JSON Body Encoding**
   - Fixed issue with body encoding in clickhouseSelect:
   ```dart
   body: jsonEncode({"query": query}),  // Uses jsonEncode instead of direct object
   ```

4. **Base Href Configuration**
   - Implemented dynamic base href detection in index.html:
   ```javascript
   <script>
     var baseHref = window.location.pathname;
     if (!baseHref.endsWith('/')) {
       baseHref = baseHref.substring(0, baseHref.lastIndexOf('/') + 1);
     }
     document.write('<base href="' + baseHref + '">');
   </script>
   ```

## Testing the Application

### Running in Chrome
To run the application in Chrome for testing:

```bash
# Use the convenience script for running in UAT environment
.\run_web_uat.bat

# Or run directly with Flutter
flutter run -d chrome --target=lib/main_smlaiuat.dart
```

### Testing UAT API Connections
1. Launch the app in Chrome with UAT configuration
2. Navigate to the `/uat_api_test.html` page to test UAT endpoints
3. Click on the various API test buttons to verify connections

## UAT Environment API Endpoints

The following endpoints are used in the UAT environment:

| API Type | URL |
|----------|-----|
| Service API | https://smlaicloudapi.dedepos.com |
| Report API | https://api.dedepos.com/apireport |
| Clickhouse | https://api.dev.dedepos.com/apireport/clickhouse |
| Version API | https://goapi.uat.dedepos.com/version |

## Common Issues and Solutions

### CORS Errors
If you're seeing Cross-Origin Resource Sharing (CORS) errors:
- Ensure the backend server has CORS properly configured
- Check that all requests include `Access-Control-Allow-Origin` header
- Make sure the web browser isn't blocking CORS requests

### Network/Connectivity Issues
- Check if the API endpoints are accessible from your network
- Verify that there are no proxy settings interfering with requests
- Some corporate networks block certain API endpoints

### URL Construction Problems
- URLs must be absolute (start with http:// or https://)
- The API port must be correctly specified
- The path components must be correctly formed

## Testing Tools

### Browser Tools
- Use Chrome DevTools Network tab to analyze requests
- Check Console for any JavaScript errors
- Use the Application tab to inspect localStorage/sessionStorage if used

### API Testing Tools
- Postman or Insomnia for testing API endpoints directly
- curl commands for terminal-based testing
- The included `uat_api_test.html` page for browser-based testing

## Troubleshooting Backend Issues

If the frontend is configured correctly but you still experience issues, check:

1. Backend server CORS configuration
2. Server firewall settings
3. Load balancer configurations
4. SSL/TLS certificate validity

### Common CORS Issues & Resolutions

If you still encounter CORS issues after the fixes:

1. **Backend Configuration**: Ensure your backend API servers include the proper CORS headers:
   ```
   Access-Control-Allow-Origin: *
   Access-Control-Allow-Methods: GET, POST, OPTIONS, PUT, DELETE
   Access-Control-Allow-Headers: Content-Type, Authorization
   ```

2. **CORS Proxy**: Consider using a CORS proxy if you don't control the backend servers:
   ```
   https://cors-anywhere.herokuapp.com/YOUR_API_URL
   ```

3. **Chrome CORS Extensions**: For development testing, consider installing a CORS extension that disables CORS checks locally.

## Web Deployment Considerations

When deploying the application to a web server:

1. Use the provided build scripts (build_web.bat/build_web.sh)
2. Ensure your web server is properly configured for SPA (Single Page Applications)
3. Copy the web/cors.json to your server and configure accordingly
4. Make sure API endpoints are accessible from your web server's domain

## Troubleshooting

1. Use the browser's developer tools console (F12) to check for any CORS errors
2. Verify API endpoints are correctly formatted with proper protocol
3. Test API connections independently using the provided test page (api_test.html)
4. Check network tab in developer tools to see actual request/response details

## Next Steps

1. Ensure all API endpoints have proper CORS configuration 
2. Test application with actual user workflows
3. Continue monitoring for any CORS issues as new API endpoints are added
