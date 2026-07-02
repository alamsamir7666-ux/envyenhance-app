/// App-wide configuration.
///
/// These are compiled in at build time. For a real production app you'd
/// normally pass secrets via --dart-define in the GitHub Actions workflow
/// rather than hardcoding them, but the Clerk *publishable* key and API
/// base URL are both safe to ship inside the app (they're public-facing
/// by design — the publishable key only works client-side and the API
/// enforces auth server-side).
class AppConfig {
  AppConfig._();

  /// Base URL of the Render-hosted API. All requests are made to
  /// `$apiBaseUrl/api/...`
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://envyenhance-api-9j77.onrender.com',
  );

  /// Clerk publishable key — safe to embed client-side.
  static const String clerkPublishableKey = String.fromEnvironment(
    'CLERK_PUBLISHABLE_KEY',
    defaultValue: 'pk_test_aGFyZHktYXJhY2huaWQtNTMuY2xlcmsuYWNjb3VudHMuZGV2JA',
  );

  static const String appName = 'EnvyEnhance';
}
