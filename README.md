# flowo_client

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Flutter Daemon Error Workaround

### Issue Description

This repository includes a script to work around an issue with the Flutter daemon where it sometimes fails with the error:

```
app '5bb69f46-c7e7-4a64-8e1c-8ff643d0ef65' not found
```

This error occurs in the Flutter daemon when it tries to stop an app that it can't find. This can happen due to race conditions in the daemon or if the app was already stopped or crashed.

### Solution

The `flutter_restart.sh` script provides a simple workaround for this issue by:

1. Killing any existing Flutter processes
2. Waiting for processes to terminate
3. Starting the Flutter app with a clean state

### Usage

Make the script executable:

```bash
chmod +x flutter_restart.sh
```

Run the app using the script:

```bash
./flutter_restart.sh
```

You can also pass arguments to the Flutter run command:

```bash
./flutter_restart.sh --debug
```

### Why This Works

The script ensures that all Flutter processes are properly terminated before starting a new one. This helps prevent race conditions where the Flutter daemon tries to stop an app that it can't find.

This is a workaround for what appears to be a bug in the Flutter daemon itself, not in the application code.
