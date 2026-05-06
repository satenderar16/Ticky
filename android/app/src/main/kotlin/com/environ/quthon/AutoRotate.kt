package com.environ.quthon

import android.app.Activity
import android.content.pm.ActivityInfo
import android.util.Log
import android.view.Surface
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class AutoRotate(private val activity: Activity) {

    companion object {
        private const val CHANNEL = "com.environ.quthon/autorotate"
        private const val TAG = "AutoRotate"

        fun register(engine: FlutterEngine, activity: Activity) {
            val controller = AutoRotate(activity)

            MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL)
                .setMethodCallHandler { call, result ->
                    when (call.method) {
                        "enableSensor" -> {
                            controller.enableSensor()
                            result.success(true)
                        }

                        "unlock" -> {
                            controller.unlock()
                            result.success(true)
                        }

                       "lockCurrent" -> {
                             val value = controller.lockCurrentOrientation()
                            result.success(value)
                        }

                        else -> result.notImplemented()
                    }
                }
        }
    }

    fun enableSensor() {
        Log.d(TAG, "Enable full sensor orientation")
        activity.requestedOrientation =
            ActivityInfo.SCREEN_ORIENTATION_FULL_SENSOR
    }

    fun unlock() {
        Log.d(TAG, "Unlock orientation (follow user auto-rotate)")
        activity.requestedOrientation =
            ActivityInfo.SCREEN_ORIENTATION_SENSOR
    }

   fun lockCurrentOrientation(): Int {
    val rotation = activity.windowManager.defaultDisplay.rotation
    val orientation = when (rotation) {
        Surface.ROTATION_0 -> ActivityInfo.SCREEN_ORIENTATION_PORTRAIT
        Surface.ROTATION_90 -> ActivityInfo.SCREEN_ORIENTATION_LANDSCAPE
        Surface.ROTATION_180 -> ActivityInfo.SCREEN_ORIENTATION_REVERSE_PORTRAIT
        Surface.ROTATION_270 -> ActivityInfo.SCREEN_ORIENTATION_REVERSE_LANDSCAPE
        else -> ActivityInfo.SCREEN_ORIENTATION_PORTRAIT
    }

    Log.d(TAG, "Lock current orientation: $orientation")
    activity.requestedOrientation = orientation

    return orientation 
}
}