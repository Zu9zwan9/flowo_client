package com.u7wells.flowo_client

import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.os.Build
import android.os.Debug
import android.app.AlarmManager
import android.provider.Settings
import androidx.annotation.RequiresApi
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.BufferedReader
import java.io.File
import java.io.InputStreamReader

class MainActivity : FlutterActivity() {
    private val securityChannel = "com.flowo.security"
    private val notificationsChannel = "flutter_local_notifications"

    @RequiresApi(Build.VERSION_CODES.P)
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Security channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, securityChannel).setMethodCallHandler { call, result ->
            when (call.method) {
                "isDebuggerAttached" -> result.success(isDebuggerAttached())
                "isRooted" -> result.success(isRooted())
                "isEmulator" -> result.success(isEmulator())
                "isFingerprintTampered" -> result.success(isFingerprintTampered())
                "isHooked" -> result.success(isHooked())
                "isTampered" -> result.success(isTampered())
                else -> result.notImplemented()
            }
        }

        // Notifications channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, notificationsChannel).setMethodCallHandler { call, result ->
            when (call.method) {
                "requestExactAlarmPermission" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
                        if (!alarmManager.canScheduleExactAlarms()) {
                            // Launch intent to request exact alarm permission
                            val intent = Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM).apply {
                                data = android.net.Uri.parse("package:$packageName")
                            }
                            startActivity(intent)
                            result.success(false) // Permission not yet granted; user must approve
                        } else {
                            result.success(true) // Permission already granted
                        }
                    } else {
                        result.success(true) // No special permission needed below Android 12
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    // Check if a debugger is attached
    private fun isDebuggerAttached(): Boolean {
        return Debug.isDebuggerConnected() || Debug.waitingForDebugger()
    }

    // Check if the device is rooted
    private fun isRooted(): Boolean {
        // Check for common root management apps
        val rootApps = arrayOf(
            "com.noshufou.android.su",
            "com.noshufou.android.su.elite",
            "eu.chainfire.supersu",
            "com.koushikdutta.superuser",
            "com.thirdparty.superuser",
            "com.yellowes.su",
            "com.topjohnwu.magisk"
        )

        val packageManager = packageManager
        for (packageName in rootApps) {
            try {
                packageManager.getPackageInfo(packageName, 0)
                return true
            } catch (e: PackageManager.NameNotFoundException) {
                // Package not found, continue checking
            }
        }

        // Check for su binary
        val paths = arrayOf(
            "/system/bin/su",
            "/system/xbin/su",
            "/sbin/su",
            "/system/su",
            "/system/bin/.ext/su",
            "/system/usr/we-need-root/su"
        )

        for (path in paths) {
            if (File(path).exists()) {
                return true
            }
        }

        // Check by executing su command
        try {
            val process = Runtime.getRuntime().exec(arrayOf("su", "-c", "id"))
            val reader = BufferedReader(InputStreamReader(process.inputStream))
            val line = reader.readLine()
            reader.close()
            if (line != null && line.contains("uid=0")) {
                return true
            }
        } catch (e: Exception) {
            // Failed to execute su, which is expected on non-rooted devices
        }

        return false
    }

    // Check if the app is running on an emulator
    private fun isEmulator(): Boolean {
        return (Build.FINGERPRINT.startsWith("generic")
                || Build.FINGERPRINT.startsWith("unknown")
                || Build.MODEL.contains("google_sdk")
                || Build.MODEL.contains("Emulator")
                || Build.MODEL.contains("Android SDK built for x86")
                || Build.MANUFACTURER.contains("Genymotion")
                || Build.BRAND.startsWith("generic") && Build.DEVICE.startsWith("generic")
                || "google_sdk" == Build.PRODUCT
                || Build.PRODUCT.contains("sdk_google")
                || Build.PRODUCT.contains("sdk")
                || Build.PRODUCT.contains("sdk_x86")
                || Build.PRODUCT.contains("vbox86p")
                || Build.PRODUCT.contains("emulator")
                || Build.PRODUCT.contains("simulator"))
    }

    // Check if the app's fingerprint has been tampered with
    @RequiresApi(Build.VERSION_CODES.P)
    private fun isFingerprintTampered(): Boolean {
        try {
            val packageInfo = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                packageManager.getPackageInfo(packageName, PackageManager.PackageInfoFlags.of(PackageManager.GET_SIGNING_CERTIFICATES.toLong()))
            } else {
                @Suppress("DEPRECATION")
                packageManager.getPackageInfo(packageName, PackageManager.GET_SIGNING_CERTIFICATES)
            }
            // In a real implementation, compare the signing certificates with a known good signature
            // For this example, we'll just return false
            return false
        } catch (e: Exception) {
            // If we can't get the signature, something might be wrong
            return true
        }
    }

    // Check if the app is being hooked by tools like Frida or Xposed
    private fun isHooked(): Boolean {
        // Check for Xposed
        val xposedPackages = arrayOf(
            "de.robv.android.xposed.installer",
            "com.saurik.substrate",
            "com.zachspong.temprootremovejb",
            "com.amphoras.hidemyroot",
            "com.formyhm.hideroot"
        )

        val packageManager = packageManager
        for (packageName in xposedPackages) {
            try {
                packageManager.getPackageInfo(packageName, 0)
                return true
            } catch (e: PackageManager.NameNotFoundException) {
                // Package not found, continue checking
            }
        }

        // Check for suspicious libraries loaded in the process
        try {
            val mapsFile = File("/proc/self/maps").readText()
            val suspiciousLibs = arrayOf("frida", "xposed", "substrate", "cynject")
            for (lib in suspiciousLibs) {
                if (mapsFile.contains(lib)) {
                    return true
                }
            }
        } catch (e: Exception) {
            // Failed to read maps file
        }

        return false
    }

    // Check if the app has been tampered with
    private fun isTampered(): Boolean {
        try {
            val appInfo = packageManager.getApplicationInfo(packageName, 0)
            // Check if the app is debuggable
            return (appInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0
        } catch (e: Exception) {
            // If we can't get the application info, something might be wrong
            return true
        }
    }
}
