package com.optimistic.browser

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private var nativeEnginePlugin: OptimisticNativeEnginePlugin? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        nativeEnginePlugin = OptimisticNativeEnginePlugin(
            flutterEngine.dartExecutor.binaryMessenger,
            this,
        )
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        nativeEnginePlugin = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
