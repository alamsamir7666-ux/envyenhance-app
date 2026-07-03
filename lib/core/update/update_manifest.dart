/// Parsed shape of the `version.json` published alongside each GitHub
/// Release. This is the single source of truth the app polls to decide
/// whether an update exists and, if so, where to get it.
class UpdateManifest {
  const UpdateManifest({
    required this.versionName,
    required this.versionCode,
    required this.releaseNotes,
    required this.minSupportedVersionCode,
    required this.apkUrl,
    required this.apkSha256,
  });

  factory UpdateManifest.fromJson(Map<String, dynamic> json) {
    return UpdateManifest(
      versionName: json['versionName'] as String,
      versionCode: json['versionCode'] as int,
      releaseNotes: (json['releaseNotes'] as String?) ?? '',
      minSupportedVersionCode:
          (json['minSupportedVersionCode'] as int?) ?? 1,
      apkUrl: json['apkUrl'] as String,
      apkSha256: (json['apkSha256'] as String).toLowerCase().trim(),
    );
  }

  final String versionName;
  final int versionCode;
  final String releaseNotes;
  final int minSupportedVersionCode;
  final String apkUrl;
  final String apkSha256;
}
