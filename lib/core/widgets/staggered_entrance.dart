import 'package:flutter/material.dart';

/// Wraps a grid/list item so it fades and slides up into place, with a
/// small delay proportional to its index — gives lists/grids a soft,
/// cascading entrance instead of popping in all at once.
///
/// Pure Flutter (TweenAnimationBuilder), no extra package dependency.
/// Runs once per widget instance; safe to use inside GridView.builder /
/// ListView.builder item builders.
class StaggeredEntrance extends StatelessWidget {
  const StaggeredEntrance({
    required this.index,
    required this.child,
    this.baseDelay = const Duration(milliseconds: 30),
    this.maxDelay = const Duration(milliseconds: 300),
    this.duration = const Duration(milliseconds: 380),
    super.key,
  });

  /// Position of this item within its list/grid (0-based).
  final int index;
  final Widget child;

  /// Delay added per index step, capped at [maxDelay] so long lists
  /// don't take forever to finish entering.
  final Duration baseDelay;
  final Duration maxDelay;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final rawDelay = baseDelay * index;
    final delay = rawDelay > maxDelay ? maxDelay : rawDelay;

    final totalDuration = duration + delay;
    final delayFraction = delay.inMicroseconds / totalDuration.inMicroseconds;

    return TweenAnimationBuilder<double>(
      key: ValueKey('stagger-$index'),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: totalDuration,
      curve: Curves.linear,
      builder: (context, value, child) {
        // Hold at 0 during the delay window, then ease 0→1 for the
        // remaining time so items further down the list wait their turn.
        final progress = delayFraction >= 1
            ? 0.0
            : ((value - delayFraction) / (1 - delayFraction)).clamp(0.0, 1.0);
        final eased = Curves.easeOutCubic.transform(progress);

        return Opacity(
          opacity: eased,
          child: Transform.translate(
            offset: Offset(0, (1 - eased) * 18),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
