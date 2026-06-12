package com.fridgi.app

import android.Manifest
import android.content.pm.PackageManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.work.ExistingWorkPolicy
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.TimeUnit

class MainActivity : FlutterActivity() {
    private var pendingNotificationPermissionResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL_NAME,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "hasNotificationPermission" -> {
                    result.success(hasNotificationPermission())
                }

                "requestNotificationPermission" -> {
                    requestNotificationPermission(result)
                }

                "syncExpiryNotifications" -> {
                    syncExpiryNotifications(call.arguments as? Map<*, *>, result)
                }

                "clearExpiryNotifications" -> {
                    WorkManager.getInstance(this)
                        .cancelAllWorkByTag(ExpiryNotificationWorker.WORK_TAG)
                    result.success(null)
                }

                "clearExpiryNotificationsForItem" -> {
                    val itemId =
                        (call.argument<Number>("itemId")?.toInt()) ?: run {
                            result.success(null)
                            return@setMethodCallHandler
                        }
                    WorkManager.getInstance(this)
                        .cancelAllWorkByTag("item_$itemId")
                    result.success(null)
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun hasNotificationPermission(): Boolean {
        return if (android.os.Build.VERSION.SDK_INT < android.os.Build.VERSION_CODES.TIRAMISU) {
            true
        } else {
            ContextCompat.checkSelfPermission(
                this,
                Manifest.permission.POST_NOTIFICATIONS,
            ) == PackageManager.PERMISSION_GRANTED
        }
    }

    private fun requestNotificationPermission(result: MethodChannel.Result) {
        if (hasNotificationPermission()) {
            result.success(true)
            return
        }

        if (pendingNotificationPermissionResult != null) {
            result.error(
                "permission_request_in_progress",
                "Another notification permission request is already active.",
                null,
            )
            return
        }

        pendingNotificationPermissionResult = result
        ActivityCompat.requestPermissions(
            this,
            arrayOf(Manifest.permission.POST_NOTIFICATIONS),
            NOTIFICATION_PERMISSION_REQUEST_CODE,
        )
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)

        if (requestCode != NOTIFICATION_PERMISSION_REQUEST_CODE) {
            return
        }

        val granted =
            grantResults.isNotEmpty() &&
                grantResults[0] == PackageManager.PERMISSION_GRANTED

        pendingNotificationPermissionResult?.success(granted)
        pendingNotificationPermissionResult = null
    }

    private fun syncExpiryNotifications(
        arguments: Map<*, *>?,
        result: MethodChannel.Result,
    ) {
        val requests = arguments?.get("requests") as? List<*> ?: emptyList<Any>()
        val workManager = WorkManager.getInstance(this)

        workManager.cancelAllWorkByTag(ExpiryNotificationWorker.WORK_TAG)

        for (request in requests) {
            val requestMap = request as? Map<*, *> ?: continue
            val workName = requestMap["workName"] as? String ?: continue
            val notificationId =
                (requestMap["notificationId"] as? Number)?.toInt() ?: continue
            val scheduleAtMillis =
                (requestMap["scheduleAtMillis"] as? Number)?.toLong() ?: continue
            val title = requestMap["title"] as? String ?: continue
            val body = requestMap["body"] as? String ?: continue
            val itemTag = requestMap["itemTag"] as? String ?: continue

            val delayMillis = scheduleAtMillis - System.currentTimeMillis()
            val requestBuilder = OneTimeWorkRequestBuilder<ExpiryNotificationWorker>()
            if (delayMillis > 0L) {
                requestBuilder.setInitialDelay(delayMillis, TimeUnit.MILLISECONDS)
            }

            val workRequest = requestBuilder
                .addTag(ExpiryNotificationWorker.WORK_TAG)
                .addTag(itemTag)
                .setInputData(
                    androidx.work.workDataOf(
                        ExpiryNotificationWorker.KEY_NOTIFICATION_ID to notificationId,
                        ExpiryNotificationWorker.KEY_TITLE to title,
                        ExpiryNotificationWorker.KEY_BODY to body,
                    ),
                )
                .build()

            workManager.enqueueUniqueWork(
                workName,
                ExistingWorkPolicy.REPLACE,
                workRequest,
            )
        }

        result.success(null)
    }

    companion object {
        private const val CHANNEL_NAME = "com.fridgi.app/expiry_notifications"
        private const val NOTIFICATION_PERMISSION_REQUEST_CODE = 7401
    }
}
