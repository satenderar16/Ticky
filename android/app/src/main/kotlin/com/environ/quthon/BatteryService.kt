package com.environ.quthon

import android.content.*
import android.os.BatteryManager
import android.util.Log
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import org.json.JSONObject

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
        // Only listen if not already listening
        if (batteryReceiver != null) return

        eventSink = events

        batteryReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent) {
                // Only send events if Dart is still listening
                if (eventSink == null) return

                val level = intent.getIntExtra(BatteryManager.EXTRA_LEVEL, -1)
                val status = intent.getIntExtra(BatteryManager.EXTRA_STATUS, -1)
                val health = intent.getIntExtra(BatteryManager.EXTRA_HEALTH, -1)

                val isCharging = status == BatteryManager.BATTERY_STATUS_CHARGING ||
                                 status == BatteryManager.BATTERY_STATUS_FULL

                val healthStr = when (health) {
                    BatteryManager.BATTERY_HEALTH_GOOD -> "Good"
                    BatteryManager.BATTERY_HEALTH_OVERHEAT -> "Overheat"
                    BatteryManager.BATTERY_HEALTH_DEAD -> "Dead"
                    BatteryManager.BATTERY_HEALTH_OVER_VOLTAGE -> "Over Voltage"
                    BatteryManager.BATTERY_HEALTH_UNKNOWN -> "Unknown"
                    else -> "Other"
                }

                val json = JSONObject()
                json.put("level", level)
                json.put("charging", isCharging)
                json.put("health", healthStr)

                try {
                    if(eventSink !=null){
                          eventSink?.success(json.toString())
                    }
                  
                } catch (e: IllegalStateException) {
                    // Flutter detached — stop listening
                    Log.w("BatteryService", "Flutter detached, stopping updates.")
                    unregisterReceiverSafe()
                }
            }
        }

        // Register receiver only when Dart subscribes
        val filter = IntentFilter(Intent.ACTION_BATTERY_CHANGED)
        context.registerReceiver(batteryReceiver, filter)
    }

    override fun onCancel(arguments: Any?) {
        unregisterReceiverSafe()
        eventSink = null
    }

    private fun unregisterReceiverSafe() {
        try {
            batteryReceiver?.let { context.unregisterReceiver(it) }
        } catch (e: Exception) {
            Log.w("BatteryService", "Receiver already unregistered: $e")
        }
        batteryReceiver = null
    }
}
