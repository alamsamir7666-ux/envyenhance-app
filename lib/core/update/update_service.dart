import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:convert/convert.dart' show AccumulatorSink;
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

import 'update_manifest.dart';

/// URL of the `version.json` manifest. This must point at the *raw* file
/// on the default branch (not the GitHub web UI page), so it's plain JSON
/// with no auth required.
///
/// Points at the alamsamir7666-ux/envyenhance-app repo's version.json on main.
const String kVersionManifestUrl =
    'https://raw.githubusercontent.com/alamsamir7666-ux/envyenhance-app/main/version.json';

/// One-shot outcomes plus in-progress states surfaced to the UI. Modeled
/// as a sealed-ish class hierarchy (rather than a bare enum) because the
/// "downloading" and "error" states need to carry data.
sealed class UpdateStatus {
  const UpdateStatus();
}

class UpdateIdle extends UpdateStatus {
  const UpdateIdle();
}

class UpdateChecking extends UpdateStatus {
  const UpdateChecking();
}

class UpdateUpToDate extends UpdateStatus {
  const UpdateUpToDate();
}

class UpdateAvailable extends UpdateStatus {
  const UpdateAvailable(this.manifest, {required this.isRequired});
  final UpdateManifest manifest;
  final bool isRequired;
}

class UpdateDownloading extends UpdateStatus {
  const UpdateDownloading(this.progress);
  final double progress; // 0.0–1.0
}

class UpdateReadyToInstall extends UpdateStatus {
  const UpdateReadyToInstall(this.apkPath);
  final String apkPath;
}

class UpdateError extends UpdateStatus {
  const UpdateError(this.message);
  final String message;
}

/// Checks for, downloads, verifies, and installs app updates distributed
/// as APKs via GitHub Releases.
///
/// Deliberately has no Riverpod/Flutter dependency in its core logic (only
/// pure Dart + platform plugins) so it's easy to test in isolation; the
/// Riverpod wiring lives in `update_providers.dart`.
class UpdateService {
  UpdateService({http.Client? httpClient})
      : _http = httpClient ?? http.Client();

  final http.Client _http;
  final Logger _logger = Logger();

  final _statusController = StreamController<UpdateStatus>.broadcast();
  UpdateStatus _lastStatus = const UpdateIdle();
  Stream<UpdateStatus> get statusStream => _statusController.stream;

  UpdateStatus _status = const UpdateIdle();
  UpdateStatus get status => _status;

  void _emit(UpdateStatus status) {
    _status = status;
    _lastStatus = status;
    _statusController.add(status);
  }

  /// Fetches version.json and compares it against the installed build.
  /// Never throws — network/parse failures are surfaced as [UpdateError]
  /// so a background check can't crash the app or interrupt the user.
  Future<void> checkForUpdate() async {
    _emit(const UpdateChecking());
    try {
      final response = await _http
          .get(Uri.parse(kVersionManifestUrl))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception('Manifest fetch failed (${response.statusCode})');
      }

      final manifest =
          UpdateManifest.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
      final installed = await PackageInfo.fromPlatform();
      final installedCode = int.tryParse(installed.buildNumber) ?? 0;

      if (manifest.versionCode <= installedCode) {
        _emit(const UpdateUpToDate());
        return;
      }

      _emit(
        UpdateAvailable(
          manifest,
          isRequired: installedCode < manifest.minSupportedVersionCode,
        ),
      );
    } catch (e, st) {
      _logger.w('Update check failed', error: e, stackTrace: st);
      _emit(UpdateError('Couldn\'t check for updates: ${e.toString()}'));
    }
  }

  /// Downloads the APK from [manifest.apkUrl] into the app's private cache
  /// dir, verifying its SHA-256 against [manifest.apkSha256] before
  /// returning. Emits progress via the status stream.
  ///
  /// Throws on checksum mismatch — an update is never handed to the
  /// installer unverified.
  Future<void> downloadUpdate(UpdateManifest manifest) async {
    try {
      final cacheDir = await getTemporaryDirectory();
      final updatesDir = Directory('${cacheDir.path}/app_updates');
      if (!await updatesDir.exists()) {
        await updatesDir.create(recursive: true);
      }

      // Clean up any stale partial/previous downloads before starting.
      await for (final entity in updatesDir.list()) {
        if (entity is File) {
          await entity.delete();
        }
      }

      final apkFile = File('${updatesDir.path}/envyenhance-${manifest.versionCode}.apk');
      final request = http.Request('GET', Uri.parse(manifest.apkUrl));
      final response = await _http.send(request);

      if (response.statusCode != 200) {
        throw Exception('Download failed (${response.statusCode})');
      }

      final total = response.contentLength ?? 0;
      var received = 0;
      final sink = apkFile.openWrite();
      final digestSink = AccumulatorSink<Digest>();
      final hashInput = sha256.startChunkedConversion(digestSink);

      await response.stream.listen((chunk) {
        sink.add(chunk);
        hashInput.add(chunk);
        received += chunk.length;
        if (total > 0) {
          _emit(UpdateDownloading(received / total));
        }
      }).asFuture<void>();

      await sink.close();
      hashInput.close();
      final actualHash = digestSink.events.single.toString();

      if (actualHash != manifest.apkSha256) {
        await apkFile.delete();
        throw Exception(
          'Downloaded file failed verification. Please try again.',
        );
      }

      _emit(UpdateReadyToInstall(apkFile.path));
    } catch (e, st) {
      _logger.e('Update download failed', error: e, stackTrace: st);
      _emit(UpdateError('Download failed: ${e.toString()}'));
    }
  }

  /// Hands the verified APK to Android's package installer. This always
  /// requires one user tap on the system "Install" dialog — Android does
  /// not allow silent installs from a regular app, by design.
  Future<void> installUpdate(String apkPath) async {
    final result = await OpenFilex.open(apkPath, type: 'application/vnd.android.package-archive');
    if (result.type != ResultType.done) {
      _emit(UpdateError('Couldn\'t open installer: ${result.message}'));
    }
  }

  void dispose() {
    _statusController.close();
    _http.close();
  }
}
