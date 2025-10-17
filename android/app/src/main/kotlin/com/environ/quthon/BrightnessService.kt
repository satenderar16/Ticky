package com.environ.quthon

import android.app.Activity
import android.provider.Settings
import android.view.WindowManager
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class BrightnessService(private val activity: Activity) {

    companion object {
        private const val CHANNEL = "com.environ.quthon/brightness"

        fun registerWith(flutterEngine: FlutterEngine, activity: Activity) {
            val service = BrightnessService(activity)

            MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
                .setMethodCallHandler { call, result ->
                    when (call.method) {
                        // Get system brightness (0-255)
                        "getSystemBrightness" -> {
                            try {
                                val brightness = Settings.System.getInt(
                                    activity.contentResolver,
                                    Settings.System.SCREEN_BRIGHTNESS
                                )
                                result.success(brightness)
                            } catch (e: Settings.SettingNotFoundException) {
                                result.success(127) // fallback mid brightness
                            }
                        }

                        // Set app window brightness only
                        "setBrightness" -> {
                            val value = call.argument<Double>("value")

                            val layoutParams = activity.window.attributes

                            layoutParams.screenBrightness = if (value == null) {
                                WindowManager.LayoutParams.BRIGHTNESS_OVERRIDE_NONE // Give control back to system
                            } else {
                                value.toFloat().coerceIn(0f, 1f)
                            }

                            activity.window.attributes = layoutParams
                            result.success(null)
                        }


                        else -> result.notImplemented()
                    }
                }
        }
    }
}
