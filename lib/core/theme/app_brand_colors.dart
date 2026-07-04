import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Brand tokens that don't map cleanly onto Flutter's built-in
/// [ColorScheme] (e.g. the gold accent used specifically for prices/
/// ratings, and the sage "in stock" signal). Exposed via
/// `Theme.of(context).extension<AppBrandColors>()!` so every screen reads
/// from one source instead of importing AppColors directly and hardcoding
/// light/dark branches everywhere.
@immutable
class AppBrandColors extends ThemeExtension<AppBrandColors> {
  const AppBrandColors({
    required this.gold,
    required this.sage,
    required this.roseSurface,
    required this.roseText,
    required this.textSecondary,
  });

  final Color gold;
  final Color sage;
  final Color roseSurface;
  final Color roseText;
  final Color textSecondary;

  static const light = AppBrandColors(
    gold: AppColors.gold,
    sage: AppColors.sage,
    roseSurface: AppColors.rose,
    roseText: AppColors.roseDeep,
    textSecondary: AppColors.lightTextSecondary,
  );

  static const dark = AppBrandColors(
    gold: AppColors.goldDark,
    sage: AppColors.sageDark,
    roseSurface: AppColors.roseDark,
    roseText: AppColors.parchment,
    textSecondary: AppColors.darkTextSecondary,
  );

  @override
  AppBrandColors copyWith({
    Color? gold,
    Color? sage,
    Color? roseSurface,
    Color? roseText,
    Color? textSecondary,
  }) {
    return AppBrandColors(
      gold: gold ?? this.gold,
      sage: sage ?? this.sage,
      roseSurface: roseSurface ?? this.roseSurface,
      roseText: roseText ?? this.roseText,
      textSecondary: textSecondary ?? this.textSecondary,
    );
  }

  @override
  AppBrandColors lerp(ThemeExtension<AppBrandColors>? other, double t) {
    if (other is! AppBrandColors) return this;
    return AppBrandColors(
      gold: Color.lerp(gold, other.gold, t)!,
      sage: Color.lerp(sage, other.sage, t)!,
      roseSurface: Color.lerp(roseSurface, other.roseSurface, t)!,
      roseText: Color.lerp(roseText, other.roseText, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
    );
  }
}

/// Convenience accessor: `context.brand.gold` instead of the verbose
/// `Theme.of(context).extension<AppBrandColors>()!` at every call site.
extension AppBrandColorsX on BuildContext {
  AppBrandColors get brand => Theme.of(this).extension<AppBrandColors>()!;
}
