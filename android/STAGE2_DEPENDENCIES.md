# V10 Android dependencies

The native plugin is designed for AndroidX WebKit 1.15.x and uses the MULTI_PROFILE APIs.

Recommended Gradle dependency:

```gradle
implementation("androidx.webkit:webkit:1.15.0")
```

Do not claim multi-profile support if `WebViewFeature.MULTI_PROFILE` is false at runtime.
