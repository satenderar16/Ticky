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


 
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

         val window = window

        if (Build.VERSION.SDK_INT < 35) {

            // Enable camera cutout support for devices with notches (API 28+) android 9+
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                val params = window.attributes
                params.layoutInDisplayCutoutMode =
                    WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES
                window.attributes = params
            }

            // Enable edge-to-edge system UI layout
           // window.decorView.systemUiVisibility = (
             //   View.SYSTEM_UI_FLAG_LAYOUT_STABLE or
               // View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN or
               // View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
           // )
           // window.statusBarColor = Color.TRANSPARENT
           // window.navigationBarColor = Color.TRANSPARENT
        }
        AutoRotate.register(flutterEngine, this)
        WakeClass.register(flutterEngine, this)
        BrightnessService.registerWith(flutterEngine, this)
        DndService.register(flutterEngine, applicationContext)
        BatteryService.registerWith(flutterEngine, applicationContext)
        PinService.register(this, flutterEngine)
    }




    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        PinService.onWindowFocusChanged(this, hasFocus)

    }

}
