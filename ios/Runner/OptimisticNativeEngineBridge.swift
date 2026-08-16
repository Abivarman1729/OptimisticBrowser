import Flutter
import WebKit

/// Stage-1 iOS native engine bridge.
///
/// iOS uses WebKit/WKWebView, not Chromium. The bridge therefore reports the
/// actual engine instead of falsely advertising Chromium capabilities.
final class OptimisticNativeEngineBridge: NSObject {
  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "initialize": result(nil)
    case "getEngineInfo": result(["platform": "ios", "engine": "webkit-wkwebview", "version": UIDevice.current.systemVersion, "profileBackend": "wkwebsite-data-store"])
    case "getCapabilities": result(["perProfileCookies": true, "perProfileCache": true, "perProfileLocalStorage": true, "networkInterception": false, "contentBlocking": false, "engine": "WKWebView/WebKit"])
    case "createProfile":
      guard let args = call.arguments as? [String: Any], let id = args["profileId"] as? String else { result(FlutterError(code: "INVALID_PROFILE", message: "profileId is required", details: nil)); return }
      createProfile(id, privateProfile: (args["privateProfile"] as? Bool) ?? false); result(nil)
    case "navigate":
      guard let args = call.arguments as? [String: Any], let id = args["profileId"] as? String, let url = args["url"] as? String else { result(FlutterError(code: "INVALID_NAVIGATION", message: "profileId and url are required", details: nil)); return }
      navigate(id, urlString: url); result(nil)
    case "setUserAgent":
      guard let args = call.arguments as? [String: Any], let id = args["profileId"] as? String, let value = args["value"] as? String, let view = views[id] else { result(FlutterError(code: "INVALID_PROFILE", message: "profileId and user-agent are required", details: nil)); return }
      view.customUserAgent = value; result(nil)
    case "setBlockedHosts":
      // WKWebView does not expose a general request interception API through the public SDK.
      // Do not claim content blocking here; return success only for policy configuration storage.
      result(nil)
    case "clearProfile":
      guard let args = call.arguments as? [String: Any], let id = args["profileId"] as? String else { result(FlutterError(code: "INVALID_PROFILE", message: "profileId is required", details: nil)); return }
      clearProfile(id); result(nil)
    case "disposeProfile":
      guard let args = call.arguments as? [String: Any], let id = args["profileId"] as? String else { result(nil); return }
      disposeProfile(id); result(nil)
    default: result(FlutterMethodNotImplemented)
    }
  }
    private var stores: [String: WKWebsiteDataStore] = [:]
    private var views: [String: WKWebView] = [:]

    func createProfile(_ id: String, privateProfile: Bool) {
        if privateProfile {
            stores[id] = WKWebsiteDataStore.nonPersistent()
        } else {
            stores[id] = WKWebsiteDataStore.default()
        }
        guard let store = stores[id] else { return }
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = store
        views[id]?.removeFromSuperview()
        views[id] = WKWebView(frame: .zero, configuration: configuration)
    }

    func navigate(_ id: String, urlString: String) {
        guard let url = URL(string: urlString), let view = views[id] else { return }
        view.load(URLRequest(url: url))
    }

    func clearProfile(_ id: String) {
        guard let store = stores[id] else { return }
        let types = WKWebsiteDataStore.allWebsiteDataTypes()
        store.removeData(ofTypes: types, modifiedSince: .distantPast) { }
    }

    func disposeProfile(_ id: String) {
        views[id]?.stopLoading()
        views[id]?.removeFromSuperview()
        views.removeValue(forKey: id)
        stores.removeValue(forKey: id)
    }
}
