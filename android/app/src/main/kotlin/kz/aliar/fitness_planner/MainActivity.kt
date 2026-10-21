package kz.aliar.fitness_planner

import android.os.BatteryManager
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Свой канал: имя совпадает с DeviceChannel.name в lib/core/device_channel.dart.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "kz.aliar.fitness_planner/device")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "batteryLevel" -> {
                        val battery = getSystemService(BATTERY_SERVICE) as BatteryManager
                        result.success(battery.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY))
                    }
                    "keepScreenOn" -> {
                        val flag = WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON
                        if (call.arguments == true) window.addFlags(flag) else window.clearFlags(flag)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
