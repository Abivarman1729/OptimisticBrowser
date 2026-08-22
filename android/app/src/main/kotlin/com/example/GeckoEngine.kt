package com.example.optimistic_browser

import android.content.Context
import android.view.View
import android.widget.FrameLayout
import org.mozilla.geckoview.GeckoRuntime
import org.mozilla.geckoview.GeckoSession
import org.mozilla.geckoview.GeckoView

class GeckoEngine(context: Context) {

    private val appContext = context.applicationContext

    private val runtime: GeckoRuntime by lazy {
        GeckoRuntime.create(appContext)
    }

    private var session: GeckoSession? = null
    private var geckoView: GeckoView? = null

    fun createView(): View {
        val view = GeckoView(appContext)

        val newSession = GeckoSession()

        newSession.open(runtime)

        view.setSession(newSession)

        session = newSession
        geckoView = view

        return FrameLayout(appContext).apply {
            layoutParams = FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT
            )

            addView(
                view,
                FrameLayout.LayoutParams(
                    FrameLayout.LayoutParams.MATCH_PARENT,
                    FrameLayout.LayoutParams.MATCH_PARENT
                )
            )
        }
    }

    fun loadUrl(url: String) {
        session?.loadUri(url)
    }

    fun goBack(): Boolean {
        return if (session?.canGoBack == true) {
            session?.goBack()
            true
        } else {
            false
        }
    }

    fun goForward(): Boolean {
        return if (session?.canGoForward == true) {
            session?.goForward()
            true
        } else {
            false
        }
    }

    fun reload() {
        session?.reload()
    }

    fun stop() {
        session?.stop()
    }

    fun dispose() {
        session?.close()
        session = null
        geckoView = null
    }
}