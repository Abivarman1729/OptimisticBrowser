# Android platform layer

This bundle includes the Android manifest and Flutter embedding activity so the Android tree is no longer represented only as a comment inside a test file. If your installed Flutter SDK reports template/plugin-version differences, run `flutter create .` once from the project root; it will refresh Gradle wrapper/plugin files while preserving `lib/`, `assets/`, and this manifest/activity.


## Stage 2 dependency

Add:

    implementation("androidx.webkit:webkit:1.15.0")

Stage 2 requires the AndroidX WebKit `MULTI_PROFILE` feature. The bridge fails closed if the installed System WebView does not support it.
