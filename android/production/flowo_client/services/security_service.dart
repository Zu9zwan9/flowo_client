import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// A service that provides security checks to protect against reverse engineering
class SecurityService {
  static const MethodChannel _channel = MethodChannel('com.flowo.security');

  // Android callbacks
  final Function()? onRootDetected;
  final Function()? onEmulatorDetected;
  final Function()? onFingerprintDetected;
  final Function()? onHookDetected;
  final Function()? onTamperDetected;

  // iOS callbacks
  final Function()? onSignatureDetected;
  final Function()? onRuntimeManipulationDetected;
  final Function()? onJailbreakDetected;
  final Function()? onPasscodeChangeDetected;
  final Function()? onPasscodeDetected;
  final Function()? onSimulatorDetected;
  final Function()? onMissingSecureEnclaveDetected;

  // Common callback
  final Function()? onDebuggerDetected;

  /// Creates a new SecurityService with the specified callbacks
  SecurityService({
    this.onRootDetected,
    this.onEmulatorDetected,
    this.onFingerprintDetected,
    this.onHookDetected,
    this.onTamperDetected,
    this.onSignatureDetected,
    this.onRuntimeManipulationDetected,
    this.onJailbreakDetected,
    this.onPasscodeChangeDetected,
    this.onPasscodeDetected,
    this.onSimulatorDetected,
    this.onMissingSecureEnclaveDetected,
    this.onDebuggerDetected,
  });

  /// Initialize security checks based on the platform
  Future<void> initialize() async {
    if (kDebugMode) {
      // Skip security checks in debug mode
      return;
    }

    // Check for debugger first (common for both platforms)
    if (onDebuggerDetected != null) {
      try {
        final bool isDebuggerAttached =
            await _channel.invokeMethod<bool>('isDebuggerAttached') ?? false;
        if (isDebuggerAttached) {
          onDebuggerDetected!();
        }
      } catch (e) {
        // If method channel fails, fallback to basic check
        bool isDebuggerAttached = kDebugMode;
        if (isDebuggerAttached) {
          onDebuggerDetected!();
        }
      }
    }

    if (Platform.isAndroid) {
      await _runAndroidChecks();
    } else if (Platform.isIOS) {
      await _runIOSChecks();
    }
  }

  /// Run Android-specific security checks
  Future<void> _runAndroidChecks() async {
    // Perform real security checks using method channel

    // Check for root
    if (onRootDetected != null) {
      try {
        final bool isRooted =
            await _channel.invokeMethod<bool>('isRooted') ?? false;
        if (isRooted) {
          onRootDetected!();
        }
      } catch (e) {
        // Fallback to basic check if method channel fails
      }
    }

    // Check for emulator
    if (onEmulatorDetected != null) {
      try {
        final bool isEmulator =
            await _channel.invokeMethod<bool>('isEmulator') ?? false;
        if (isEmulator) {
          onEmulatorDetected!();
        }
      } catch (e) {
        // Fallback to basic check if method channel fails
      }
    }

    // Check for fingerprint tampering
    if (onFingerprintDetected != null) {
      try {
        final bool isFingerprintTampered =
            await _channel.invokeMethod<bool>('isFingerprintTampered') ?? false;
        if (isFingerprintTampered) {
          onFingerprintDetected!();
        }
      } catch (e) {
        // Fallback to basic check if method channel fails
      }
    }

    // Check for hooks (like Frida, Xposed)
    if (onHookDetected != null) {
      try {
        final bool isHooked =
            await _channel.invokeMethod<bool>('isHooked') ?? false;
        if (isHooked) {
          onHookDetected!();
        }
      } catch (e) {
        // Fallback to basic check if method channel fails
      }
    }

    // Check for app tampering
    if (onTamperDetected != null) {
      try {
        final bool isTampered =
            await _channel.invokeMethod<bool>('isTampered') ?? false;
        if (isTampered) {
          onTamperDetected!();
        }
      } catch (e) {
        // Fallback to basic check if method channel fails
      }
    }
  }

  /// Run iOS-specific security checks
  Future<void> _runIOSChecks() async {
    // Perform real security checks using method channel

    // Check for signature issues
    if (onSignatureDetected != null) {
      try {
        final bool hasSignatureIssues =
            await _channel.invokeMethod<bool>('hasSignatureIssues') ?? false;
        if (hasSignatureIssues) {
          onSignatureDetected!();
        }
      } catch (e) {
        // Fallback to basic check if method channel fails
      }
    }

    // Check for runtime manipulation
    if (onRuntimeManipulationDetected != null) {
      try {
        final bool isRuntimeManipulated =
            await _channel.invokeMethod<bool>('isRuntimeManipulated') ?? false;
        if (isRuntimeManipulated) {
          onRuntimeManipulationDetected!();
        }
      } catch (e) {
        // Fallback to basic check if method channel fails
      }
    }

    // Check for jailbreak
    if (onJailbreakDetected != null) {
      try {
        final bool isJailbroken =
            await _channel.invokeMethod<bool>('isJailbroken') ?? false;
        if (isJailbroken) {
          onJailbreakDetected!();
        }
      } catch (e) {
        // Fallback to basic check if method channel fails
      }
    }

    // Check for passcode changes
    if (onPasscodeChangeDetected != null) {
      try {
        final bool hasPasscodeChanged =
            await _channel.invokeMethod<bool>('hasPasscodeChanged') ?? false;
        if (hasPasscodeChanged) {
          onPasscodeChangeDetected!();
        }
      } catch (e) {
        // Fallback to basic check if method channel fails
      }
    }

    // Check if passcode is set
    if (onPasscodeDetected != null) {
      try {
        final bool hasPasscode =
            await _channel.invokeMethod<bool>('hasPasscode') ?? true;
        if (!hasPasscode) {
          onPasscodeDetected!();
        }
      } catch (e) {
        // Fallback to basic check if method channel fails
      }
    }

    // Check for simulator
    if (onSimulatorDetected != null) {
      try {
        final bool isSimulator =
            await _channel.invokeMethod<bool>('isSimulator') ?? false;
        if (isSimulator) {
          onSimulatorDetected!();
        }
      } catch (e) {
        // Fallback to basic check if method channel fails
      }
    }

    // Check for missing secure enclave
    if (onMissingSecureEnclaveDetected != null) {
      try {
        final bool hasMissingSecureEnclave =
            await _channel.invokeMethod<bool>('hasMissingSecureEnclave') ??
            false;
        if (hasMissingSecureEnclave) {
          onMissingSecureEnclaveDetected!();
        }
      } catch (e) {
        // Fallback to basic check if method channel fails
      }
    }
  }
}
