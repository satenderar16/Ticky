package com.environ.quthon

import android.app.NotificationManager
import android.content.*
import android.os.Build
import android.provider.Settings
import android.util.Log
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class DndService {
    companion object {
        private const val METHOD_CHANNEL = "com.environ.quthon/dnd_method"
        private const val EVENT_CHANNEL = "com.environ.quthon/dnd_stream"

        private var eventSink: EventChannel.EventSink? = null
        private var receiverRegistered = false

        fun register(engine: FlutterEngine, context: Context) {
            MethodChannel(engine.dartExecutor.binaryMessenger, METHOD_CHANNEL).setMethodCallHandler { call, result ->
                when (call.method) {
                    "enableDnd" -> {
                        setDnd(context, true)
                        result.success(null)
                        sendStatus(context)
                    }
                    "disableDnd" -> {
                        setDnd(context, false)
                        result.success(null)
                        sendStatus(context)
                    }
                    "isPermissionGranted" -> {
                        result.success(hasPermission(context))
                    }
                    "requestPermission" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            val intent = Intent(Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS)
                            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            context.startActivity(intent)
                            result.success(null)
                        } else {
                            // DND access not required or not supported on versions < M
                            result.success(null)
                        }
                    }
                    "isDndCurrentlyEnabled" -> {
                        result.success(isCurrentlyOn(context))
                    }
                   "getDndStatus" -> {
                        result.success(getCurrentDndFilter(context))
                    }
                    else -> result.notImplemented()
                }
            }

            EventChannel(engine.dartExecutor.binaryMessenger, EVENT_CHANNEL).setStreamHandler(
                object : EventChannel.StreamHandler {
                    override fun onListen(arguments: Any?, sink: EventChannel.EventSink?) {
                        eventSink = sink
//                        sendStatus(context)
                        registerReceiver(context)
                    }

                    override fun onCancel(arguments: Any?) {
                        eventSink = null

                    }
                }
            )
        }

        private fun sendStatus(context: Context) {
            val status = getCurrentDndFilter(context)
            eventSink?.success(status)
        }

        private fun registerReceiver(context: Context) {
            if (receiverRegistered) return
            receiverRegistered = true

            val filter = IntentFilter(NotificationManager.ACTION_INTERRUPTION_FILTER_CHANGED)
            context.registerReceiver(object : BroadcastReceiver() {
                override fun onReceive(ctx: Context?, intent: Intent?) {
                    sendStatus(context)
                }
            }, filter)
        }

        private fun getCurrentDndFilter(context: Context): Int {
            val TAG = "DndService"
            val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

            return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                val filter = manager.currentInterruptionFilter
                Log.d(TAG, "Current DND Filter: $filter")
                filter
            } else {
                Log.d(TAG, "SDK < M, returning default filter: INTERRUPTION_FILTER_ALL")
                NotificationManager.INTERRUPTION_FILTER_ALL
            }
        }
        private fun setDnd(context: Context, enable: Boolean) {
            val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                manager.setInterruptionFilter(
                    if (enable) NotificationManager.INTERRUPTION_FILTER_NONE
                    else NotificationManager.INTERRUPTION_FILTER_ALL
                )
            }
        }

        private fun hasPermission(context: Context): Boolean {
            return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                manager.isNotificationPolicyAccessGranted
            } else true
        }

        private fun isCurrentlyOn(context: Context): Boolean {
            val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                manager.currentInterruptionFilter == NotificationManager.INTERRUPTION_FILTER_NONE
            } else false
        }
    }
}
