# dedeorder

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

python apkupload.py

## Build dedeorder windows
```
flutter build windows -t lib/main.dart --dart-define=ENVIRONMENT=PROD  --dart-define=FLAVOR=dedeorder
flutter pub run msix:create --build-windows false
```


Configure Telegram bot credentials with local `--dart-define` values such as `TELEGRAM_BOT_TOKEN` and `TELEGRAM_CHAT_ID`. Do not commit real bot tokens.

For a description of the Bot API, see this page: https://core.telegram.org/bots/api

https://api.telegram.org/bot<TELEGRAM_BOT_TOKEN>/sendMessage?chat_id=<TELEGRAM_CHAT_ID>&text=<MESSAGE>
