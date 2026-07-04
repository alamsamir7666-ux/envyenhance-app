import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_brand_colors.dart';
import 'app_colors.dart';

/// Central theme builder for both light and dark modes.
///
/// Typography: DM Sans for body/UI, DM Serif Display for the "one serif
/// moment" — product names, section headers, prices — per the design
/// plan. Fetched at runtime via google_fonts (cached to disk after first
/// launch) rather than bundled, to keep the APK smaller without a real
/// UX cost after the first successful fetch.
class AppTheme {
  AppTheme._();

  static ThemeData light() => _build(brightness: Brightness.light);
  static ThemeData dark() => _build(brightness: Brightness.dark);

  static ThemeData _build({required Brightness brightness}) {
    final isDark = brightness == Brightness.dark;

    final backgroundColor = isDark ? AppColors.ink : AppColors.ivory;
    final surfaceColor = isDark ? AppColors.darkSurface : Colors.white;
    final primaryColor = isDark ? AppColors.parchment : AppColors.charcoal;
    final onPrimaryColor = isDark ? AppColors.ink : Colors.white;
    final textColor = isDark ? AppColors.parchment : AppColors.charcoal;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final brand = isDark ? AppBrandColors.dark : AppBrandColors.light;

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: primaryColor,
      onPrimary: onPrimaryColor,
      secondary: brand.gold,
      onSecondary: onPrimaryColor,
      error: AppColors.errorRed,
      onError: Colors.white,
      surface: surfaceColor,
      onSurface: textColor,
    );

    final base = ThemeData(useMaterial3: true, colorScheme: colorScheme, brightness: brightness);

    final serif = GoogleFonts.dmSerifDisplay();
    final sansTextTheme = GoogleFonts.dmSansTextTheme(base.textTheme).copyWith(
      // The one serif moment: display/headline roles only. Everything
      // else — titles, body, labels — stays DM Sans so the serif reads
      // as a deliberate accent, not the default voice of the app.
      displayLarge: serif.copyWith(fontSize: 34, color: textColor, height: 1.15),
      displayMedium: serif.copyWith(fontSize: 28, color: textColor, height: 1.2),
      displaySmall: serif.copyWith(fontSize: 24, color: textColor, height: 1.2),
      headlineMedium: serif.copyWith(fontSize: 22, color: textColor, height: 1.25),
      titleLarge: GoogleFonts.dmSans(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      titleMedium: GoogleFonts.dmSans(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      bodyLarge: GoogleFonts.dmSans(fontSize: 15, color: textColor),
      bodyMedium: GoogleFonts.dmSans(fontSize: 13.5, color: brand.textSecondary),
      labelLarge: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600),
    );

    return base.copyWith(
      scaffoldBackgroundColor: backgroundColor,
      textTheme: sansTextTheme,
      extensions: [brand],
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: sansTextTheme.titleLarge,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: onPrimaryColor,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.dmSans(fontWeight: FontWeight.w600, fontSize: 15),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: BorderSide(color: primaryColor),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          textStyle: GoogleFonts.dmSans(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: primaryColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.errorRed),
        ),
        hintStyle: GoogleFonts.dmSans(color: brand.textSecondary),
      ),
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: borderColor),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: brand.roseSurface,
        labelStyle: GoogleFonts.dmSans(
          fontSize: 12.5,
          fontWeight: FontWeight.w500,
          color: brand.roseText,
        ),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      dividerTheme: DividerThemeData(color: borderColor, thickness: 1),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surfaceColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: brand.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.dmSans(fontSize: 11),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: primaryColor,
        contentTextStyle: GoogleFonts.dmSans(color: onPrimaryColor, fontSize: 14),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: brand.gold),
    );
  }
}
