package com.example.optimistic_browser

import android.content.Context
import android.view.View
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

class MainActivity : FlutterActivity() {

    companion object {
        private const val CHANNEL = "optimistic_browser/gecko"
        private const val VIEW_TYPE = "optimistic_browser/gecko_view"
    }

    private var geckoEngine: GeckoEngine? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        geckoEngine = GeckoEngine(this)

        flutterEngine
            .platformViewsController
            .registry
            .registerViewFactory(
                VIEW_TYPE,
                GeckoViewFactory(this, geckoEngine!!)
            )

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call: MethodCall, result: MethodChannel.Result ->

            when (call.method) {

                "loadUrl" -> {
                    val url = call.argument<String>("url")

                    if (url.isNullOrBlank()) {
                        result.error(
                            "INVALID_URL",
                            "URL cannot be empty.",
                            null
                        )
                    } else {
                        geckoEngine?.loadUrl(url)
                        result.success(true)
                    }
                }

                "goBack" -> {
                    result.success(
                        geckoEngine?.goBack() ?: false
                    )
                }

                "goForward" -> {
                    result.success(
                        geckoEngine?.goForward() ?: false
                    )
                }

                "reload" -> {
                    geckoEngine?.reload()
                    result.success(true)
                }

                "stop" -> {
                    geckoEngine?.stop()
                    result.success(true)
                }

                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    override fun onDestroy() {
        geckoEngine?.dispose()
        geckoEngine = null
        super.onDestroy()
    }
}

/**
 * Flutter PlatformView factory for GeckoView.
 */
private class GeckoViewFactory(
    private val context: Context,
    private val engine: GeckoEngine
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {

    override fun create(
        context: Context,
        viewId: Int,
        args: Any?
    ): PlatformView {
        return GeckoPlatformView(engine)
    }
}

/**
 * PlatformView wrapper around the GeckoEngine view.
 */
private class GeckoPlatformView(
    private val engine: GeckoEngine
) : PlatformView {

    private val view: View = engine.createView()

    override fun getView(): View {
        return view
    }

    override fun dispose() {
        // GeckoEngine lifecycle is handled by MainActivity.
    }
}