import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// App Typography System - Modern typography scale
class AppTypography {
  // Base font family
  static String get fontFamily => GoogleFonts.inter().fontFamily ?? 'Inter';
  static String get monospaceFontFamily => GoogleFonts.jetBrainsMono().fontFamily ?? 'JetBrains Mono';
  
  // Font weights
  static const FontWeight thin = FontWeight.w100;
  static const FontWeight extraLight = FontWeight.w200;
  static const FontWeight light = FontWeight.w300;
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;
  static const FontWeight extraBold = FontWeight.w800;
  static const FontWeight black = FontWeight.w900;
  
  // Display styles (largest)
  static TextStyle get displayLarge => GoogleFonts.inter(
    fontSize: 57,
    fontWeight: bold,
    height: 1.12,
    letterSpacing: -0.25,
  );
  
  static TextStyle get displayMedium => GoogleFonts.inter(
    fontSize: 45,
    fontWeight: bold,
    height: 1.16,
    letterSpacing: 0,
  );
  
  static TextStyle get displaySmall => GoogleFonts.inter(
    fontSize: 36,
    fontWeight: semiBold,
    height: 1.22,
    letterSpacing: 0,
  );
  
  // Headline styles
  static TextStyle get headlineLarge => GoogleFonts.inter(
    fontSize: 32,
    fontWeight: semiBold,
    height: 1.25,
    letterSpacing: 0,
  );
  
  static TextStyle get headlineMedium => GoogleFonts.inter(
    fontSize: 28,
    fontWeight: semiBold,
    height: 1.29,
    letterSpacing: 0,
  );
  
  static TextStyle get headlineSmall => GoogleFonts.inter(
    fontSize: 24,
    fontWeight: semiBold,
    height: 1.33,
    letterSpacing: 0,
  );
  
  // Title styles
  static TextStyle get titleLarge => GoogleFonts.inter(
    fontSize: 22,
    fontWeight: medium,
    height: 1.27,
    letterSpacing: 0,
  );
  
  static TextStyle get titleMedium => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: medium,
    height: 1.5,
    letterSpacing: 0.15,
  );
  
  static TextStyle get titleSmall => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: medium,
    height: 1.43,
    letterSpacing: 0.1,
  );
  
  // Label styles
  static TextStyle get labelLarge => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: medium,
    height: 1.43,
    letterSpacing: 0.1,
  );
  
  static TextStyle get labelMedium => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: medium,
    height: 1.33,
    letterSpacing: 0.5,
  );
  
  static TextStyle get labelSmall => GoogleFonts.inter(
    fontSize: 11,
    fontWeight: medium,
    height: 1.45,
    letterSpacing: 0.5,
  );
  
  // Body styles
  static TextStyle get bodyLarge => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: regular,
    height: 1.5,
    letterSpacing: 0.5,
  );
  
  static TextStyle get bodyMedium => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: regular,
    height: 1.43,
    letterSpacing: 0.25,
  );
  
  static TextStyle get bodySmall => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: regular,
    height: 1.33,
    letterSpacing: 0.4,
  );
  
  // Custom app-specific styles
  
  // Server card styles
  static TextStyle get serverName => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: semiBold,
    height: 1.25,
    letterSpacing: 0,
  );
  
  static TextStyle get serverAddress => GoogleFonts.inter(
    fontSize: 13,
    fontWeight: regular,
    height: 1.38,
    letterSpacing: 0.25,
  );
  
  static TextStyle get serverStatus => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: medium,
    height: 1.33,
    letterSpacing: 0.4,
  );
  
  static TextStyle get serverMetric => GoogleFonts.inter(
    fontSize: 24,
    fontWeight: bold,
    height: 1.17,
    letterSpacing: 0,
  );
  
  static TextStyle get serverMetricLabel => GoogleFonts.inter(
    fontSize: 11,
    fontWeight: medium,
    height: 1.45,
    letterSpacing: 0.5,
  );
  
  // Terminal styles
  static TextStyle get terminal => GoogleFonts.jetBrainsMono(
    fontSize: 14,
    fontWeight: regular,
    height: 1.4,
    letterSpacing: 0,
  );
  
  static TextStyle get terminalSmall => GoogleFonts.jetBrainsMono(
    fontSize: 12,
    fontWeight: regular,
    height: 1.33,
    letterSpacing: 0,
  );
  
  static TextStyle get terminalLarge => GoogleFonts.jetBrainsMono(
    fontSize: 16,
    fontWeight: regular,
    height: 1.5,
    letterSpacing: 0,
  );
  
  // Code styles
  static TextStyle get code => GoogleFonts.jetBrainsMono(
    fontSize: 13,
    fontWeight: regular,
    height: 1.38,
    letterSpacing: 0,
  );
  
  static TextStyle get codeSmall => GoogleFonts.jetBrainsMono(
    fontSize: 11,
    fontWeight: regular,
    height: 1.45,
    letterSpacing: 0,
  );
  
  // Navigation styles
  static TextStyle get navigationLabel => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: medium,
    height: 1.33,
    letterSpacing: 0.5,
  );
  
  static TextStyle get navigationTitle => GoogleFonts.inter(
    fontSize: 20,
    fontWeight: semiBold,
    height: 1.2,
    letterSpacing: 0,
  );
  
  // Button styles
  static TextStyle get buttonLarge => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: medium,
    height: 1.25,
    letterSpacing: 0.1,
  );
  
  static TextStyle get buttonMedium => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: medium,
    height: 1.43,
    letterSpacing: 0.1,
  );
  
  static TextStyle get buttonSmall => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: medium,
    height: 1.33,
    letterSpacing: 0.5,
  );
  
  // Input styles
  static TextStyle get input => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: regular,
    height: 1.5,
    letterSpacing: 0.5,
  );
  
  static TextStyle get inputLabel => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: medium,
    height: 1.43,
    letterSpacing: 0.1,
  );
  
  static TextStyle get inputHint => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: regular,
    height: 1.5,
    letterSpacing: 0.5,
  );
  
  static TextStyle get inputError => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: regular,
    height: 1.33,
    letterSpacing: 0.4,
  );
  
  // Dialog styles
  static TextStyle get dialogTitle => GoogleFonts.inter(
    fontSize: 20,
    fontWeight: semiBold,
    height: 1.2,
    letterSpacing: 0,
  );
  
  static TextStyle get dialogContent => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: regular,
    height: 1.43,
    letterSpacing: 0.25,
  );
  
  // Tooltip styles
  static TextStyle get tooltip => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: medium,
    height: 1.33,
    letterSpacing: 0.4,
  );
  
  // Badge styles
  static TextStyle get badge => GoogleFonts.inter(
    fontSize: 11,
    fontWeight: semiBold,
    height: 1.45,
    letterSpacing: 0.5,
  );
  
  // Caption styles
  static TextStyle get caption => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: regular,
    height: 1.33,
    letterSpacing: 0.4,
  );
  
  static TextStyle get captionBold => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: semiBold,
    height: 1.33,
    letterSpacing: 0.4,
  );
  
  // Overline styles
  static TextStyle get overline => GoogleFonts.inter(
    fontSize: 10,
    fontWeight: medium,
    height: 1.6,
    letterSpacing: 1.5,
  );
  
  // AI Chat styles
  static TextStyle get chatMessage => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: regular,
    height: 1.43,
    letterSpacing: 0.25,
  );
  
  static TextStyle get chatTimestamp => GoogleFonts.inter(
    fontSize: 11,
    fontWeight: regular,
    height: 1.45,
    letterSpacing: 0.5,
  );
  
  static TextStyle get chatSender => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: semiBold,
    height: 1.33,
    letterSpacing: 0.4,
  );
  
  // File transfer styles
  static TextStyle get fileName => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: medium,
    height: 1.43,
    letterSpacing: 0.1,
  );
  
  static TextStyle get fileSize => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: regular,
    height: 1.33,
    letterSpacing: 0.4,
  );
  
  static TextStyle get transferProgress => GoogleFonts.inter(
    fontSize: 13,
    fontWeight: medium,
    height: 1.38,
    letterSpacing: 0.25,
  );
  
  // Utility methods
  static TextStyle withColor(TextStyle style, Color color) {
    return style.copyWith(color: color);
  }
  
  static TextStyle withWeight(TextStyle style, FontWeight weight) {
    return style.copyWith(fontWeight: weight);
  }
  
  static TextStyle withSize(TextStyle style, double size) {
    return style.copyWith(fontSize: size);
  }
  
  static TextStyle withHeight(TextStyle style, double height) {
    return style.copyWith(height: height);
  }
  
  static TextStyle withSpacing(TextStyle style, double spacing) {
    return style.copyWith(letterSpacing: spacing);
  }
  
  static TextStyle withDecoration(TextStyle style, TextDecoration decoration) {
    return style.copyWith(decoration: decoration);
  }
  
  static TextStyle withShadow(TextStyle style, List<Shadow> shadows) {
    return style.copyWith(shadows: shadows);
  }
  
  // Text theme for Material Design integration
  static TextTheme get textTheme => TextTheme(
    displayLarge: displayLarge,
    displayMedium: displayMedium,
    displaySmall: displaySmall,
    headlineLarge: headlineLarge,
    headlineMedium: headlineMedium,
    headlineSmall: headlineSmall,
    titleLarge: titleLarge,
    titleMedium: titleMedium,
    titleSmall: titleSmall,
    labelLarge: labelLarge,
    labelMedium: labelMedium,
    labelSmall: labelSmall,
    bodyLarge: bodyLarge,
    bodyMedium: bodyMedium,
    bodySmall: bodySmall,
  );
  
  // Dark theme text theme
  static TextTheme get darkTextTheme => textTheme;
}