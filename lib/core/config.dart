/// App-wide configuration.
///
/// The API base URL is compiled in at build time. It's safe to ship
/// inside the app since it's just a public endpoint — the backend
/// enforces auth server-side regardless of who knows the URL.
class AppConfig {
  AppConfig._();

  /// Base URL of the Render-hosted API. All requests are made to
  /// `$apiBaseUrl/api/...`
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://envyenhance-api-9j77.onrender.com',
  );

  static const String appName = 'EnvyEnhance';
}
