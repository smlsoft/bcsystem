# Launch Config

## Mac OS

```json
        {
            "name": "smlaicloud-macos",
            "request": "launch",
            "type": "dart",
            "program": "lib/main_smlaicloud.dart"           
        },
        {
            "name": "vfmerchant-macos",
            "request": "launch",
            "type": "dart",
            "program": "lib/main_vfmerchant.dart"           
        },
```

## Web

```json
        {
            "name": "smlaicloud-flutter",
            "request": "launch",
            "type": "dart",
            "program": "lib/main_smlaicloud.dart",
            "args": [
                "--flavor",
                "smlaicloud",
            ]
        },
        {
            "name": "vfmerchant-flutter",
            "request": "launch",
            "type": "dart",
            "program": "lib/main_vfmerchant.dart",
            "args": [
                "--flavor",
                "vfmerchant",
            ]
        },
``