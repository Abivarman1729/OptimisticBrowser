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

    private var canNavigateBack = false
    private var canNavigateForward = false

    fun createView(): View {
        val view = GeckoView(appContext)

        val newSession = GeckoSession()

        newSession.navigationDelegate = object : GeckoSession.NavigationDelegate {

            override fun onCanGoBack(
                session: GeckoSession,
                canGoBack: Boolean
            ) {
                canNavigateBack = canGoBack
            }

            override fun onCanGoForward(
                session: GeckoSession,
                canGoForward: Boolean
            ) {
                canNavigateForward = canGoForward
            }
        }

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
        val currentSession = session ?: return false

        if (!canNavigateBack) {
            return false
        }

        currentSession.goBack()
        return true
    }

    fun goForward(): Boolean {
        val currentSession = session ?: return false

        if (!canNavigateForward) {
            return false
        }

        currentSession.goForward()
        return true
    }

    fun canGoBack(): Boolean {
        return canNavigateBack
    }

    fun canGoForward(): Boolean {
        return canNavigateForward
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

        canNavigateBack = false
        canNavigateForward = false
    }
}