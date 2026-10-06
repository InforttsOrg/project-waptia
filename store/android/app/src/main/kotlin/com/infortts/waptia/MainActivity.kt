package com.infortts.waptia

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.app.ActivityCompat
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.infortts.waptia/system"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getInstalledPackages" -> {
                    val packages = call.argument<List<String>>("packages") ?: emptyList()
                    val installedMap = mutableMapOf<String, Map<String, Any>>()
                    val pm = packageManager

                    for (pkg in packages) {
                        try {
                            val info = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                                pm.getPackageInfo(pkg, PackageManager.PackageInfoFlags.of(0))
                            } else {
                                @Suppress("DEPRECATION")
                                pm.getPackageInfo(pkg, 0)
                            }
                            val versionCode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                                info.longVersionCode
                            } else {
                                @Suppress("DEPRECATION")
                                info.versionCode.toLong()
                            }
                            installedMap[pkg] = mapOf(
                                "installed" to true,
                                "versionName" to (info.versionName ?: "1.0.0"),
                                "versionCode" to versionCode
                            )
                        } catch (e: PackageManager.NameNotFoundException) {
                            // Package is not installed
                        }
                    }
                    result.success(installedMap)
                }
                "openApp" -> {
                    val pkg = call.argument<String>("packageName") ?: ""
                    if (pkg.isNotEmpty()) {
                        val launchIntent = packageManager.getLaunchIntentForPackage(pkg)
                        if (launchIntent != null) {
                            launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            startActivity(launchIntent)
                            result.success(true)
                            return@setMethodCallHandler
                        }
                    }
                    result.success(false)
                }
                "canRequestPackageInstalls" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        result.success(packageManager.canRequestPackageInstalls())
                    } else {
                        result.success(true)
                    }
                }
                "requestInstallPermission" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        try {
                            val intent = Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES).apply {
                                data = Uri.parse("package:$packageName")
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            startActivity(intent)
                            result.success(true)
                            return@setMethodCallHandler
                        } catch (e: Exception) {
                            val intent = Intent(Settings.ACTION_SECURITY_SETTINGS).apply {
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            startActivity(intent)
                            result.success(true)
                            return@setMethodCallHandler
                        }
                    }
                    result.success(true)
                }
                "installApk" -> {
                    val filePath = call.argument<String>("filePath") ?: ""
                    if (filePath.isNotEmpty()) {
                        val file = File(filePath)
                        if (file.exists()) {
                            try {
                                val contentUri = FileProvider.getUriForFile(
                                    this,
                                    "${applicationContext.packageName}.fileprovider",
                                    file
                                )
                                val intent = Intent(Intent.ACTION_VIEW).apply {
                                    setDataAndType(contentUri, "application/vnd.android.package-archive")
                                    addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                }
                                startActivity(intent)
                                result.success(true)
                                return@setMethodCallHandler
                            } catch (e: Exception) {
                                result.error("INSTALL_ERROR", e.message, null)
                                return@setMethodCallHandler
                            }
                        } else {
                            result.error("FILE_NOT_FOUND", "APK file not found at $filePath", null)
                            return@setMethodCallHandler
                        }
                    }
                    result.success(false)
                }
                "isNotificationPermissionGranted" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        val granted = ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED
                        result.success(granted)
                    } else {
                        val areEnabled = NotificationManagerCompat.from(this).areNotificationsEnabled()
                        result.success(areEnabled)
                    }
                }
                "requestNotificationPermission" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        if (ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) {
                            ActivityCompat.requestPermissions(this, arrayOf(Manifest.permission.POST_NOTIFICATIONS), 101)
                        }
                    }
                    result.success(true)
                }
                "showNotification" -> {
                    val title = call.argument<String>("title") ?: "Waptia Store"
                    val message = call.argument<String>("message") ?: ""
                    val channelId = "waptia_store_events"
                    val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        val channel = NotificationChannel(
                            channelId,
                            "Waptia Store Alerts",
                            NotificationManager.IMPORTANCE_HIGH
                        ).apply {
                            description = "Notifications for package downloads, installs, and updates"
                        }
                        notificationManager.createNotificationChannel(channel)
                    }

                    val builder = NotificationCompat.Builder(this, channelId)
                        .setSmallIcon(android.R.drawable.stat_sys_download_done)
                        .setContentTitle(title)
                        .setContentText(message)
                        .setPriority(NotificationCompat.PRIORITY_HIGH)
                        .setAutoCancel(true)

                    notificationManager.notify((System.currentTimeMillis() % 100000).toInt(), builder.build())
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }
}
