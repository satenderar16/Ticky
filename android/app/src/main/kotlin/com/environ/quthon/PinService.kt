package com.environ.quthon

import android.app.Activity
import android.app.ActivityManager
import android.app.admin.DevicePolicyManager
import android.content.Context
import android.os.Build
import android.util.Log
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import android.content.Intent
import android.provider.Settings


class PinService {

    companion object {
        private const val METHOD_CHANNEL = "com.environ.quthon/pin_method"
        private const val EVENT_CHANNEL = "com.environ.quthon/pin_events"

        var monitor: Boolean = false

        private var eventSink: EventChannel.EventSink? = null

        fun register(activity: Activity, engine: FlutterEngine) {
            MethodChannel(engine.dartExecutor.binaryMessenger, METHOD_CHANNEL).setMethodCallHandler { call, result ->
                when (call.method) {
                    "startPin" -> {
                        startPin(activity)
                        result.success(null)
                    }

                    "stopPin" -> {
                        stopPin(activity)
                        result.success(null)
                    }

                    "getStatus" -> {
                        result.success(getCurrentPinStatus(activity))
                    }

                    "setMonitorState" -> {
                        monitor = call.argument<Boolean>("monitor") == true
                        result.success(null)
                    }
                    "checkPermission" -> {
                        result.success(isPinningEnabled(activity))
                    }

                    "requestPermission" -> {
                        openPinningSettings(activity)
                        result.success(null)
                    }


                    else -> result.notImplemented()
                }
            }

            EventChannel(engine.dartExecutor.binaryMessenger, EVENT_CHANNEL).setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, sink: EventChannel.EventSink?) {
                    eventSink = sink
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                }
            })
        }


        private fun startPin(activity: Activity) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                activity.startLockTask()
                Log.d("PinService", "startPin() -> sending 'pinned'")
            }
        }


        private fun stopPin(activity: Activity) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                activity.stopLockTask()
                Log.d("PinService", "stopPin() -> sending 'unpinned'")
            }
        }

        private fun getCurrentPinStatus(context: Context): Int {
            val state = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                val am = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
                am.lockTaskModeState
            } else {
                0
            }

            when (state) {
                ActivityManager.LOCK_TASK_MODE_PINNED,
                ActivityManager.LOCK_TASK_MODE_LOCKED -> {
                    Log.d("PinService", "getCurrentPinStatus() -> emitting 'pinned'")
                    eventSink?.success("pinned")
                }

                ActivityManager.LOCK_TASK_MODE_NONE -> {
                    Log.d("PinService", "getCurrentPinStatus() -> emitting 'unpinned'")
                    eventSink?.success("unpinned")
                }
            }

            return state
        }

        private fun isPinningEnabled(context: Context): Boolean {
            return try {
                Settings.Secure.getInt(
                    context.contentResolver,
                    "lock_to_app_enabled"
                ) == 1
            } catch (e: Settings.SettingNotFoundException) {
                false
            }
        }

        private fun openPinningSettings(activity: Activity) {
            val intent = Intent(Settings.ACTION_SECURITY_SETTINGS)
            intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
            activity.startActivity(intent)
        }

        fun onWindowFocusChanged(activity: Activity, hasFocus: Boolean) {
            Log.d("PinService", "Window focus changed: $hasFocus | monitor=$monitor")

            if (!hasFocus && monitor) {
                Log.d("PinService", "Focus lost while monitoring -> sending 'violation'")
                eventSink?.success("violation")
            }
        }


    }
}
