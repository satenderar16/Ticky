package com.environ.quthon

import android.content.*
import android.os.BatteryManager
import android.os.Build
import android.util.Log
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel

class BatteryService(private val context: Context) : EventChannel.StreamHandler {

    companion object {
        private const val CHANNEL = "com.environ.quthon/battery"

        fun registerWith(engine: FlutterEngine, context: Context) {
            EventChannel(engine.dartExecutor.binaryMessenger, CHANNEL)
                .setStreamHandler(BatteryService(context))
        }
    }

    private var eventSink: EventChannel.EventSink? = null
    private var batteryReceiver: BroadcastReceiver? = null

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
        batteryReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent) {
                val level = intent.getIntExtra(BatteryManager.EXTRA_LEVEL, -1)
                val status = intent.getIntExtra(BatteryManager.EXTRA_STATUS, -1)
                val isCharging = status == BatteryManager.BATTERY_STATUS_CHARGING ||
                        status == BatteryManager.BATTERY_STATUS_FULL

                val result = if (isCharging) "charging $level" else "$level"
                eventSink?.success(result)
            }
        }

        val filter = IntentFilter(Intent.ACTION_BATTERY_CHANGED)
        context.registerReceiver(batteryReceiver, filter)
    }

    override fun onCancel(arguments: Any?) {
        batteryReceiver?.let {
            context.unregisterReceiver(it)
        }
        batteryReceiver = null
        eventSink = null
    }
}
