package com.smlsoft.dedekiosk

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.GeneratedPluginRegistrant
import androidx.annotation.NonNull
import io.flutter.plugin.common.BinaryMessenger // Import BinaryMessenger

class MainActivity: FlutterActivity() {
    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        GeneratedPluginRegistrant.registerWith(flutterEngine)

        val customMethodChannelHandler = CustomMethodChannelHandler(this, flutterEngine.dartExecutor.binaryMessenger)
        customMethodChannelHandler.setupChannel()
    }
}
