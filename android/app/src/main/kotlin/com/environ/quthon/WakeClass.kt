package com.environ.quthon

import android.app.Activity
import android.view.WindowManager
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class WakeClass(private val activity: Activity) {
    companion object {
        private const val WAKE_CHANNEL = "com.environ.quthon/wake"

        fun register(engine: FlutterEngine, activity: Activity) {
            val wakeClass = WakeClass(activity)

            MethodChannel(engine.dartExecutor.binaryMessenger, WAKE_CHANNEL)
                .setMethodCallHandler { call, result ->
                    when (call.method) {
                        "keepScreenOn" -> {
                            wakeClass.enableWakeLock()
                            result.success(null)
                        }
                        "allowSleep" -> {
                            wakeClass.disableWakeLock()
                            result.success(null)
                        }
                        else -> result.notImplemented()
                    }
                }
        }
    }

    fun enableWakeLock() {
        activity.window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
    }

    fun disableWakeLock() {
        activity.window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
    }
}
