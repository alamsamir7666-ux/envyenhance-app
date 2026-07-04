# ─────────────────────────────────────────────────────────────────────────
# EnvyEnhance release R8/ProGuard rules
# ─────────────────────────────────────────────────────────────────────────
# Flutter's own engine and plugin wrapper classes. Required for any
# Flutter app using minifyEnabled — without this the engine's own
# reflection-based plugin registration can be stripped.
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# ── Dio / OkHttp (networking) ──────────────────────────────────────────
# Dio's Android platform code sits on top of OkHttp/Conscrypt. OkHttp
# ships its own consumer ProGuard rules bundled in its AAR, but Conscrypt
# and a couple of OkHttp internals reference optional classes that don't
# exist on Android and would otherwise emit build-breaking warnings.
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn javax.annotation.**
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }

# ── flutter_secure_storage ─────────────────────────────────────────────
# Backed by AndroidX Security Crypto (EncryptedSharedPreferences) on
# Android. Keep its classes so the encryption/keystore path isn't
# stripped or renamed in a way that breaks native method lookups.
-keep class androidx.security.crypto.** { *; }
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# ── open_filex (update installer) ──────────────────────────────────────
# Uses a FileProvider + explicit Android intents to hand the downloaded
# APK to the system installer. Keep its plugin classes so the
# platform-channel method names survive obfuscation.
-keep class com.crazecoder.openfile.** { *; }
-keep class androidx.core.content.FileProvider { *; }

# ── path_provider ───────────────────────────────────────────────────────
-keep class io.flutter.plugins.pathprovider.** { *; }

# ── General safety net for MethodChannel-based plugins ─────────────────
# Any plugin invoked via Flutter's platform channels is called by
# reflection-free message passing (not Java reflection), so this project
# does not need broad "-keep class * { *; }" style rules — those exist
# mainly for Java/Kotlin reflection-based serializers (Gson/Moshi/kotlinx
# .serialization), none of which this app uses. Dart-side JSON parsing
# (lib/core/models/*.dart) is hand-written, ordinary Dart code compiled
# by the Dart AOT compiler, which is entirely unaffected by R8.

# Keep annotation metadata used by AndroidX / Play Core deferred
# components (referenced indirectly by the Android Gradle Plugin).
-keep class androidx.annotation.Keep
-keep @androidx.annotation.Keep class * { *; }
-keepclasseswithmembers class * {
    @androidx.annotation.Keep <methods>;
}

# ── Flutter Play Store deferred components (unused) ────────────────────
# Flutter's engine has optional support for Play Store dynamic feature
# delivery via com.google.android.play.core.*, which requires an extra
# dependency we don't include since this app doesn't use deferred
# components. R8 correctly detects these classes are missing; they're
# safe to ignore since that code path is never invoked at runtime.
-dontwarn com.google.android.play.core.**
-keep class io.flutter.embedding.engine.deferredcomponents.** { *; }
