package com.optimistic.browser

import android.app.Activity
import android.os.Build
import android.webkit.ServiceWorkerClient
import android.webkit.WebResourceRequest
import android.webkit.WebResourceResponse
import android.webkit.WebSettings
import android.webkit.WebView
import android.webkit.WebViewClient
import androidx.webkit.ProfileStore
import androidx.webkit.WebViewCompat
import androidx.webkit.WebViewFeature
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayInputStream
import java.util.Locale

/**
 * V10 Android native browser backend.
 *
 * Primary Android engine: Android System WebView (Chromium runtime).
 * Storage isolation: AndroidX WebKit MULTI_PROFILE when supported.
 *
 * IMPORTANT: CEF is not an Android runtime. The Chromium Embedded Framework
 * is a desktop embedding framework and cannot truthfully be advertised as a
 * bundled Android CEF engine. V10 therefore exposes an explicit engine
 * capability/adapter boundary instead of shipping a fake binary.
 */
class OptimisticNativeEnginePlugin(
    messenger: BinaryMessenger,
    private val activity: Activity
) : MethodChannel.MethodCallHandler {

    private val channel = MethodChannel(messenger, "optimistic_browser/native_engine")
    private val profiles = mutableMapOf<String, WebView>()
    private val blockedHosts = mutableMapOf<String, MutableSet<String>>()
    private val profileNames = mutableMapOf<String, String>()
    private val privateProfiles = mutableSetOf<String>()
    private var initialized = false

    init { channel.setMethodCallHandler(this) }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "initialize" -> { ensureInitialized(); result.success(null) }

                "getEngineInfo" -> {
                    ensureInitialized()
                    val packageInfo = WebView.getCurrentWebViewPackage(activity)
                    val multiProfile = WebViewFeature.isFeatureSupported(WebViewFeature.MULTI_PROFILE)
                    result.success(mapOf(
                        "platform" to "android",
                        "engine" to "chromium-webview",
                        "engineKind" to "android-system-webview",
                        "version" to (packageInfo?.versionName ?: Build.VERSION.RELEASE),
                        "webViewPackage" to (packageInfo?.packageName ?: "unknown"),
                        "profileBackend" to if (multiProfile) "androidx-webkit-1.15-multi-profile" else "unsupported",
                        "bundledChromiumBinary" to false,
                        "cefAndroid" to false,
                        "nativeEngineAdapter" to "explicit-capability-boundary"
                    ))
                }

                "getCapabilities" -> {
                    val multiProfile = WebViewFeature.isFeatureSupported(WebViewFeature.MULTI_PROFILE)
                    result.success(mapOf(
                        "perProfileCookies" to multiProfile,
                        "perProfileCache" to multiProfile,
                        "perProfileLocalStorage" to multiProfile,
                        "perProfileServiceWorkers" to multiProfile,
                        "networkInterception" to true,
                        "contentBlocking" to true,
                        "downloads" to true,
                        "fileUpload" to true,
                        "cefAndroid" to false,
                        "bundledChromiumBinary" to false,
                        "engine" to "Chromium Android System WebView"
                    ))
                }

                "createProfile" -> {
                    val id = call.argument<String>("profileId")
                    if (id.isNullOrBlank()) {
                        result.error("INVALID_PROFILE", "profileId is required", null); return
                    }
                    createProfile(id, call.argument<Boolean>("privateProfile") ?: false)
                    result.success(null)
                }

                "navigate" -> {
                    val id = call.argument<String>("profileId")
                    val url = call.argument<String>("url")
                    val view = id?.let(profiles::get)
                    if (view == null || url.isNullOrBlank()) {
                        result.error("INVALID_NAVIGATION", "profile and url are required", null); return
                    }
                    view.loadUrl(url)
                    result.success(null)
                }

                "reload" -> {
                    val id = call.argument<String>("profileId")
                    id?.let { profiles[it] }?.reload()
                    result.success(null)
                }

                "goBack" -> {
                    val id = call.argument<String>("profileId")
                    id?.let { profiles[it] }?.goBack()
                    result.success(null)
                }

                "goForward" -> {
                    val id = call.argument<String>("profileId")
                    id?.let { profiles[it] }?.goForward()
                    result.success(null)
                }

                "setUserAgent" -> {
                    val id = call.argument<String>("profileId")
                    val value = call.argument<String>("value")
                    val view = id?.let(profiles::get)
                    if (view == null || value.isNullOrBlank()) {
                        result.error("INVALID_PROFILE", "profile and user-agent are required", null); return
                    }
                    view.settings.userAgentString = value
                    result.success(null)
                }

                "setBlockedHosts" -> {
                    val id = call.argument<String>("profileId")
                    if (id.isNullOrBlank()) {
                        result.error("INVALID_PROFILE", "profileId is required", null); return
                    }
                    blockedHosts[id] = (call.argument<List<String>>("hosts") ?: emptyList())
                        .map(::normalizeHost).filter(String::isNotEmpty).toMutableSet()
                    result.success(null)
                }

                "clearProfile" -> {
                    val id = call.argument<String>("profileId")
                    if (id.isNullOrBlank() || !profiles.containsKey(id)) {
                        result.error("INVALID_PROFILE", "profile does not exist", null); return
                    }
                    profiles[id]?.clearHistory()
                    clearProfileData(id)
                    result.success(null)
                }

                "disposeProfile" -> {
                    disposeProfile(call.argument<String>("profileId"))
                    result.success(null)
                }

                else -> result.notImplemented()
            }
        } catch (error: Throwable) {
            result.error("NATIVE_ENGINE_ERROR", error.message, error.javaClass.name)
        }
    }

    private fun ensureInitialized() {
        if (initialized) return
        WebView.setWebContentsDebuggingEnabled(false)
        initialized = true
    }

    private fun createProfile(id: String, privateProfile: Boolean) {
        ensureInitialized()
        if (!WebViewFeature.isFeatureSupported(WebViewFeature.MULTI_PROFILE)) {
            throw IllegalStateException(
                "MULTI_PROFILE is unavailable in the installed Android System WebView; " +
                    "V10 refuses to fake storage isolation."
            )
        }

        profiles.remove(id)?.destroy()
        profileNames.remove(id)
        privateProfiles.remove(id)

        val safeId = id.replace(Regex("[^A-Za-z0-9._-]"), "_")
        val profileName = if (privateProfile) "private_$safeId" else "normal_$safeId"
        val view = WebView(activity)
        WebViewCompat.setProfile(view, profileName)

        view.webViewClient = object : WebViewClient() {
            override fun shouldInterceptRequest(
                view: WebView,
                request: WebResourceRequest
            ): WebResourceResponse? {
                val host = normalizeHost(request.url.host ?: "")
                return if (isBlocked(id, host)) blockedResponse() else super.shouldInterceptRequest(view, request)
            }
        }

        val settings = view.settings
        settings.javaScriptEnabled = true
        settings.domStorageEnabled = true
        settings.databaseEnabled = true
        settings.cacheMode = WebSettings.LOAD_DEFAULT
        settings.allowFileAccess = false
        settings.allowContentAccess = false
        settings.mediaPlaybackRequiresUserGesture = true

        val profile = WebViewCompat.getProfile(view)
        profile.getServiceWorkerController().setServiceWorkerClient(object : ServiceWorkerClient() {
            override fun shouldInterceptRequest(request: WebResourceRequest): WebResourceResponse? {
                val host = normalizeHost(request.url.host ?: "")
                return if (isBlocked(id, host)) blockedResponse() else null
            }
        })

        profiles[id] = view
        profileNames[id] = profileName
        blockedHosts.putIfAbsent(id, mutableSetOf())
        if (privateProfile) privateProfiles.add(id)
    }

    private fun clearProfileData(id: String) {
        val view = profiles[id] ?: return
        val profile = WebViewCompat.getProfile(view)
        view.clearCache(true)
        profile.getCookieManager().removeAllCookies(null)
        profile.getWebStorage().deleteAllData()
        profile.getServiceWorkerController().clearServiceWorkerData()
    }

    private fun disposeProfile(id: String?) {
        if (id.isNullOrBlank()) return
        val view = profiles.remove(id)
        val profileName = profileNames.remove(id)
        val wasPrivate = privateProfiles.remove(id) || (profileName?.startsWith("private_") == true)

        view?.stopLoading()
        view?.destroy()
        blockedHosts.remove(id)

        if (wasPrivate && profileName != null &&
            WebViewFeature.isFeatureSupported(WebViewFeature.MULTI_PROFILE)
        ) {
            runCatching { ProfileStore.getInstance().deleteProfile(profileName) }
        }
    }

    private fun blockedResponse() = WebResourceResponse(
        "text/plain", "utf-8", 403,
        "Blocked by Optimistic Browser content policy",
        mapOf("Cache-Control" to "no-store"),
        ByteArrayInputStream(ByteArray(0))
    )

    private fun isBlocked(profileId: String, host: String): Boolean {
        if (host.isEmpty()) return false
        return blockedHosts[profileId]?.any { host == it || host.endsWith(".$it") } == true
    }

    private fun normalizeHost(value: String): String = value.trim()
        .lowercase(Locale.US)
        .removePrefix("https://").removePrefix("http://")
        .substringBefore('/').substringBefore(':')
}
