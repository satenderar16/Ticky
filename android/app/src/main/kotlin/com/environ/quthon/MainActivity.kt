package com.environ.quthon

import android.os.Build
import android.os.Bundle
import android.view.View
import android.view.WindowManager 
import android.graphics.Color
import android.graphics.drawable.ColorDrawable

import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel


class MainActivity : FlutterActivity() {

    private val SDK_CHANNEL = "com.environ.quthon/sdk"
  private val CHANNEL = "window_flags"


 
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

         val window = window

        // Apply edge-to-edge and cutout only for Android < 15 (API 35)
        if (Build.VERSION.SDK_INT < 35) {

            // Enable camera cutout support for devices with notches (API 28+) android 9+
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                val params = window.attributes
                params.layoutInDisplayCutoutMode =
                    WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES
                window.attributes = params
            }

            // Enable edge-to-edge system UI layout
            window.decorView.systemUiVisibility = (
                View.SYSTEM_UI_FLAG_LAYOUT_STABLE or
                View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN or
                View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
            )
            window.statusBarColor = Color.TRANSPARENT
            window.navigationBarColor = Color.TRANSPARENT
        }

        
    
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SDK_CHANNEL).setMethodCallHandler {
                call, result ->
            if (call.method == "getSdkVersion") {
                result.success(Build.VERSION.SDK_INT)
            } else {
                result.notImplemented()
            }
        }


        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "window_flags")
    .setMethodCallHandler { call, result ->
        try {
            if (call.method == "setFlags") {
                val flags = call.argument<List<Int>>("flags") ?: emptyList()
                val enable = call.argument<Boolean>("enable") ?: false

                val statusBarColor = (call.argument<Number?>("statusBarColor"))?.toInt()
                val navigationBarColor = (call.argument<Number?>("navigationBarColor"))?.toInt()
                val transparentBars = call.argument<Boolean>("transparentBars") ?: false
                val windowBackgroundColor = (call.argument<Number?>("windowBackgroundColor"))?.toInt()

                // Debug log
                Log.d("WindowFlags", "flags=$flags, enable=$enable")
                Log.d("WindowFlags", "statusBarColor=$statusBarColor, navigationBarColor=$navigationBarColor")
                Log.d("WindowFlags", "transparentBars=$transparentBars, windowBgColor=$windowBackgroundColor")

                // Apply flags
                flags.forEach { flag ->
                    if (enable) window.addFlags(flag) else window.clearFlags(flag)
                }

                // Apply window background color
                windowBackgroundColor?.let {
                    window.setBackgroundDrawable(ColorDrawable(it))
                }

                // Transparent bars handling
                if (transparentBars) {
                    window.decorView.systemUiVisibility = (
                        View.SYSTEM_UI_FLAG_LAYOUT_STABLE or
                        View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN or
                        View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                    )
                    window.statusBarColor = Color.TRANSPARENT
                    window.navigationBarColor = Color.TRANSPARENT
                } else {
                    statusBarColor?.let { window.statusBarColor = it }
                    navigationBarColor?.let { window.navigationBarColor = it }
                }

                result.success(null)
            } else {
                result.notImplemented()
            }
        } catch (e: Exception) {
            result.error("WINDOW_FLAGS_ERROR", e.localizedMessage, null)
        }
    }
        WakeClass.register(flutterEngine, this)
        BrightnessService.registerWith(flutterEngine, this)
        DndService.register(flutterEngine, applicationContext)
       // BatteryService.registerWith(flutterEngine, applicationContext)
        BatteryService.registerWith(flutterEngine, applicationContext)
        PinService.register(this, flutterEngine)
    }




    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        PinService.onWindowFocusChanged(this, hasFocus)

    }

}
