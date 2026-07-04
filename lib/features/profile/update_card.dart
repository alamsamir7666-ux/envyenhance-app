import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/theme/app_brand_colors.dart';
import '../../core/update/update_providers.dart';
import '../../core/update/update_service.dart';

/// Card shown on the Profile screen surfacing app-update state and letting
/// the user manually check, download, and install updates.
///
/// This does not auto-download — downloading uses the user's data/battery,
/// so we always wait for an explicit tap, matching how the Play Store
/// itself behaves on mobile data.
class UpdateCard extends ConsumerWidget {
  const UpdateCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(updateStatusProvider);
    final service = ref.read(updateServiceProvider);
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      color: theme.cardTheme.color,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: statusAsync.when(
          loading: () => const _CurrentVersionRow(),
          error: (_, __) => _CheckButton(onPressed: service.checkForUpdate),
          data: (status) => _buildForStatus(context, status, service),
        ),
      ),
    );
  }

  Widget _buildForStatus(
    BuildContext context,
    UpdateStatus status,
    UpdateService service,
  ) {
    final theme = Theme.of(context);
    final brand = context.brand;

    switch (status) {
      case UpdateIdle():
        return _CheckButton(onPressed: service.checkForUpdate);

      case UpdateChecking():
        return const Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('Checking for updates…'),
          ],
        );

      case UpdateUpToDate():
        return Row(
          children: [
            Icon(Icons.check_circle, color: brand.sage, size: 20),
            const SizedBox(width: 10),
            const Expanded(child: Text('You\'re on the latest version')),
            TextButton(
              onPressed: service.checkForUpdate,
              child: const Text('Check again'),
            ),
          ],
        );

      case UpdateAvailable(:final manifest, :final isRequired):
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isRequired ? Icons.error_outline : Icons.new_releases_outlined,
                  color: isRequired ? theme.colorScheme.error : brand.gold,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isRequired
                        ? 'Update required (v${manifest.versionName})'
                        : 'Update available (v${manifest.versionName})',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            if (manifest.releaseNotes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                manifest.releaseNotes,
                style: TextStyle(color: brand.textSecondary, fontSize: 13),
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => service.downloadUpdate(manifest),
                icon: const Icon(Icons.download_outlined, size: 18),
                label: const Text('Download update'),
              ),
            ),
          ],
        );

      case UpdateDownloading(:final progress):
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Downloading update…'),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress > 0 ? progress : null,
                minHeight: 6,
                backgroundColor: theme.dividerColor,
                color: brand.gold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${(progress * 100).clamp(0, 100).toStringAsFixed(0)}%',
              style: TextStyle(color: brand.textSecondary, fontSize: 12),
            ),
          ],
        );

      case UpdateReadyToInstall(:final apkPath):
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle, color: brand.sage, size: 20),
                const SizedBox(width: 10),
                const Text('Update verified and ready'),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => service.installUpdate(apkPath),
                icon: const Icon(Icons.install_mobile_outlined, size: 18),
                label: const Text('Install'),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Android will ask you to confirm the install.',
              style: TextStyle(color: brand.textSecondary, fontSize: 12),
            ),
          ],
        );

      case UpdateError(:final message):
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.error_outline, color: theme.colorScheme.error, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(message, style: TextStyle(color: theme.colorScheme.error)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: service.checkForUpdate,
              child: const Text('Retry'),
            ),
          ],
        );
    }
  }
}

class _CheckButton extends StatelessWidget {
  const _CheckButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: _CurrentVersionRow()),
        TextButton(onPressed: onPressed, child: const Text('Check for updates')),
      ],
    );
  }
}

class _CurrentVersionRow extends StatelessWidget {
  const _CurrentVersionRow();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        final version = snapshot.data?.version ?? '…';
        return Text(
          'App version $version',
          style: TextStyle(color: context.brand.textSecondary, fontSize: 13),
        );
      },
    );
  }
}
