import 'package:flutter/material.dart';

/// EnvyEnhance / Sakura Beauty brand palette.
///
/// Ported from the website's actual design tokens (warm ivory background,
/// deep charcoal ink, gold accent, rose secondary), not the generic
/// Material blush palette the app shipped with before. Named per the
/// design plan rather than semantic-only names, so it's obvious at a
/// glance which token maps to which brand color.
class AppColors {
  AppColors._();

  // ── Light palette ────────────────────────────────────────────────────
  static const Color ivory = Color(0xFFFAF6F1);
  static const Color charcoal = Color(0xFF2E2724);
  static const Color rose = Color(0xFFF3E1E3);
  static const Color roseDeep = Color(0xFF8C4B57);
  static const Color gold = Color(0xFFB08A3E);
  static const Color sage = Color(0xFF5B7A64);
  static const Color errorRed = Color(0xFFC1483F);
  static const Color lightBorder = Color(0xFFE8DDD3);
  static const Color lightTextSecondary = Color(0xFF7A6F68);

  // ── Dark palette ─────────────────────────────────────────────────────
  static const Color ink = Color(0xFF1C1815);
  static const Color parchment = Color(0xFFF0E8DF);
  static const Color roseDark = Color(0xFF3A2B2E);
  static const Color goldDark = Color(0xFFC89B4A);
  static const Color sageDark = Color(0xFF6E9078);
  static const Color darkBorder = Color(0xFF3A332E);
  static const Color darkSurface = Color(0xFF251F1C);
  static const Color darkTextSecondary = Color(0xFFA89C92);

  // ── Deprecated aliases (kept temporarily so old screens still compile
  //    while they're migrated screen-by-screen to AppTheme.of(context)) ──
  static const Color primary = charcoal;
  static const Color primaryLight = rose;
  static const Color accent = gold;
  static const Color background = ivory;
  static const Color surface = Colors.white;
  static const Color textPrimary = charcoal;
  static const Color textSecondary = lightTextSecondary;
  static const Color success = sage;
  static const Color error = errorRed;
  static const Color divider = lightBorder;
}
