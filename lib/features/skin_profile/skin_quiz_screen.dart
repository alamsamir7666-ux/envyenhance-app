import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/skin_profile.dart';
import '../../core/providers.dart';
import '../../core/theme/app_brand_colors.dart';
import '../../core/widgets/async_states.dart';
import 'skin_profile_providers.dart';

class SkinQuizScreen extends ConsumerWidget {
  const SkinQuizScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(skinProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Skin Profile')),
      body: profileAsync.when(
        loading: () => const LoadingView(),
        error: (err, _) => ErrorView(
          message: err.toString(),
          onRetry: () => ref.invalidate(skinProfileProvider),
        ),
        data: (profile) {
          if (profile != null) {
            return _ExistingProfileView(profile: profile);
          }
          return const _QuizFlow();
        },
      ),
    );
  }
}

class _ExistingProfileView extends ConsumerWidget {
  const _ExistingProfileView({required this.profile});
  final SkinProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final brand = context.brand;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: brand.roseSurface.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Your Skin Profile', style: theme.textTheme.headlineMedium),
              const SizedBox(height: 12),
              _ProfileRow(label: 'Skin type', value: profile.skinType),
              _ProfileRow(label: 'Sensitivity', value: profile.sensitivity),
              _ProfileRow(label: 'Main concern', value: profile.concern),
              _ProfileRow(label: 'Routine preference', value: profile.routinePreference),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text('Recommended for you', style: theme.textTheme.titleLarge),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final tag in profile.recommendedTags) Chip(label: Text(tag)),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => context.push(
              '/products?search=${Uri.encodeComponent(profile.recommendedTags.take(1).join())}',
            ),
            child: const Text('Shop recommended products'),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () async {
              await ref.read(skinProfileRepositoryProvider).reset();
              ref.invalidate(skinProfileProvider);
            },
            child: const Text('Retake quiz'),
          ),
        ),
      ],
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyMedium)),
          Text(
            value[0].toUpperCase() + value.substring(1),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _QuizFlow extends ConsumerStatefulWidget {
  const _QuizFlow();

  @override
  ConsumerState<_QuizFlow> createState() => _QuizFlowState();
}

class _QuizFlowState extends ConsumerState<_QuizFlow> {
  int _step = 0;
  String? _feel;
  String? _sensitivity;
  String? _concern;
  String? _routine;
  bool _isSubmitting = false;

  static const _steps = ['How does your skin usually feel?', 'How sensitive is your skin?',
      'What\'s your main skin concern?', 'What kind of routine do you prefer?'];

  List<SkinQuizOption> get _currentOptions => switch (_step) {
        0 => SkinQuizQuestions.feel,
        1 => SkinQuizQuestions.sensitivity,
        2 => SkinQuizQuestions.concern,
        _ => SkinQuizQuestions.routine,
      };

  String? get _currentValue => switch (_step) {
        0 => _feel,
        1 => _sensitivity,
        2 => _concern,
        _ => _routine,
      };

  void _select(String value) {
    setState(() {
      switch (_step) {
        case 0:
          _feel = value;
        case 1:
          _sensitivity = value;
        case 2:
          _concern = value;
        default:
          _routine = value;
      }
    });
  }

  Future<void> _next() async {
    if (_step < 3) {
      setState(() => _step++);
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final repo = ref.read(skinProfileRepositoryProvider);
      await repo.save(
        feel: _feel!,
        sensitivity: _sensitivity!,
        concern: _concern!,
        routine: _routine!,
      );
      ref.invalidate(skinProfileProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LinearProgressIndicator(
            value: (_step + 1) / 4,
            color: brand.gold,
            backgroundColor: theme.dividerColor,
            minHeight: 4,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 24),
          Text('Question ${_step + 1} of 4', style: theme.textTheme.bodyMedium),
          const SizedBox(height: 8),
          Text(_steps[_step], style: theme.textTheme.headlineMedium),
          const SizedBox(height: 24),
          Expanded(
            child: ListView(
              children: [
                for (final option in _currentOptions)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _OptionCard(
                      label: option.label,
                      selected: _currentValue == option.value,
                      onTap: () => _select(option.value),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _currentValue == null || _isSubmitting ? null : _next,
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(_step < 3 ? 'Next' : 'See my results'),
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brand = context.brand;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? brand.gold.withValues(alpha: 0.12) : theme.cardTheme.color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? brand.gold : theme.dividerColor, width: selected ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Expanded(child: Text(label, style: theme.textTheme.bodyLarge)),
            if (selected) Icon(Icons.check_circle, color: brand.gold),
          ],
        ),
      ),
    );
  }
}
