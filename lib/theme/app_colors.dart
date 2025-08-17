import 'package:flutter/material.dart';

/// App Color System - Modern flat design color palette
class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF2563EB); // Blue-600
  static const Color primaryLight = Color(0xFF3B82F6); // Blue-500
  static const Color primaryDark = Color(0xFF1D4ED8); // Blue-700
  static const Color primaryLighter = Color(0xFF60A5FA); // Blue-400
  static const Color primaryDarker = Color(0xFF1E40AF); // Blue-800
  
  // Secondary Colors
  static const Color secondary = Color(0xFF7C3AED); // Violet-600
  static const Color secondaryLight = Color(0xFF8B5CF6); // Violet-500
  static const Color secondaryDark = Color(0xFF6D28D9); // Violet-700
  static const Color secondaryLighter = Color(0xFFA78BFA); // Violet-400
  static const Color secondaryDarker = Color(0xFF5B21B6); // Violet-800
  
  // Accent Colors
  static const Color accent = Color(0xFF10B981); // Emerald-500
  static const Color accentLight = Color(0xFF34D399); // Emerald-400
  static const Color accentDark = Color(0xFF059669); // Emerald-600
  
  // Status Colors
  static const Color success = Color(0xFF10B981); // Emerald-500
  static const Color successLight = Color(0xFF6EE7B7); // Emerald-300
  static const Color successDark = Color(0xFF047857); // Emerald-700
  
  static const Color warning = Color(0xFFF59E0B); // Amber-500
  static const Color warningLight = Color(0xFFFBBF24); // Amber-400
  static const Color warningDark = Color(0xFFD97706); // Amber-600
  
  static const Color error = Color(0xFFEF4444); // Red-500
  static const Color errorLight = Color(0xFFF87171); // Red-400
  static const Color errorDark = Color(0xFFDC2626); // Red-600
  
  static const Color info = Color(0xFF3B82F6); // Blue-500
  static const Color infoLight = Color(0xFF60A5FA); // Blue-400
  static const Color infoDark = Color(0xFF2563EB); // Blue-600
  
  // Neutral Colors - Light Theme
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  
  static const Color gray50 = Color(0xFFF9FAFB);
  static const Color gray100 = Color(0xFFF3F4F6);
  static const Color gray200 = Color(0xFFE5E7EB);
  static const Color gray300 = Color(0xFFD1D5DB);
  static const Color gray400 = Color(0xFF9CA3AF);
  static const Color gray500 = Color(0xFF6B7280);
  static const Color gray600 = Color(0xFF4B5563);
  static const Color gray700 = Color(0xFF374151);
  static const Color gray800 = Color(0xFF1F2937);
  static const Color gray900 = Color(0xFF111827);
  
  // Light Theme Colors
  static const Color backgroundLight = Color(0xFFFAFAFA); // gray-50
  static const Color surfaceLight = Color(0xFFFFFFFF); // white
  static const Color surfaceSecondaryLight = Color(0xFFF9FAFB); // gray-50
  
  static const Color textPrimary = Color(0xFF111827); // gray-900
  static const Color textSecondary = Color(0xFF4B5563); // gray-600
  static const Color textTertiary = Color(0xFF9CA3AF); // gray-400
  static const Color textDisabled = Color(0xFFD1D5DB); // gray-300
  
  static const Color border = Color(0xFFE5E7EB); // gray-200
  static const Color borderLight = Color(0xFFF3F4F6); // gray-100
  static const Color borderDark = Color(0xFFD1D5DB); // gray-300
  
  static const Color shadow = Color(0x1A000000); // black with 10% opacity
  static const Color shadowLight = Color(0x0D000000); // black with 5% opacity
  static const Color shadowDark = Color(0x26000000); // black with 15% opacity
  
  // Dark Theme Colors
  static const Color backgroundDark = Color(0xFF0F172A); // slate-900
  static const Color surfaceDark = Color(0xFF1E293B); // slate-800
  static const Color surfaceSecondaryDark = Color(0xFF334155); // slate-700
  
  static const Color textPrimaryDark = Color(0xFFF8FAFC); // slate-50
  static const Color textSecondaryDark = Color(0xFFCBD5E1); // slate-300
  static const Color textTertiaryDark = Color(0xFF64748B); // slate-500
  static const Color textDisabledDark = Color(0xFF475569); // slate-600
  
  static const Color borderDark = Color(0xFF334155); // slate-700
  static const Color borderLightDark = Color(0xFF475569); // slate-600
  static const Color borderDarkDark = Color(0xFF1E293B); // slate-800
  
  static const Color shadowDark = Color(0x33000000); // black with 20% opacity
  static const Color shadowLightDark = Color(0x1A000000); // black with 10% opacity
  static const Color shadowDarkDark = Color(0x4D000000); // black with 30% opacity
  
  // Server Status Colors
  static const Color serverOnline = Color(0xFF10B981); // emerald-500
  static const Color serverOffline = Color(0xFF6B7280); // gray-500
  static const Color serverError = Color(0xFFEF4444); // red-500
  static const Color serverConnecting = Color(0xFFF59E0B); // amber-500
  
  // Performance Indicator Colors
  static const Color performanceGood = Color(0xFF10B981); // emerald-500
  static const Color performanceWarning = Color(0xFFF59E0B); // amber-500
  static const Color performanceCritical = Color(0xFFEF4444); // red-500
  
  // Chart Colors
  static const List<Color> chartColors = [
    Color(0xFF3B82F6), // blue-500
    Color(0xFF10B981), // emerald-500
    Color(0xFFF59E0B), // amber-500
    Color(0xFFEF4444), // red-500
    Color(0xFF8B5CF6), // violet-500
    Color(0xFF06B6D4), // cyan-500
    Color(0xFFEC4899), // pink-500
    Color(0xFF84CC16), // lime-500
  ];
  
  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryLight, primary],
  );
  
  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [secondaryLight, secondary],
  );
  
  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentLight, accent],
  );
  
  static const LinearGradient surfaceGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFFFFF), Color(0xFFF9FAFB)],
  );
  
  static const LinearGradient surfaceGradientDark = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
  );
  
  // Overlay Colors
  static const Color overlay = Color(0x80000000); // black with 50% opacity
  static const Color overlayLight = Color(0x40000000); // black with 25% opacity
  static const Color overlayDark = Color(0xB3000000); // black with 70% opacity
  
  // Backdrop Colors
  static const Color backdrop = Color(0x4D000000); // black with 30% opacity
  static const Color backdropLight = Color(0x26000000); // black with 15% opacity
  static const Color backdropDark = Color(0x66000000); // black with 40% opacity
  
  // Terminal Colors
  static const Color terminalBackground = Color(0xFF0F172A); // slate-900
  static const Color terminalForeground = Color(0xFFF8FAFC); // slate-50
  static const Color terminalCursor = Color(0xFF3B82F6); // blue-500
  static const Color terminalSelection = Color(0x4D3B82F6); // blue-500 with 30% opacity
  
  // SSH Connection Status Colors
  static const Color sshConnected = Color(0xFF10B981); // emerald-500
  static const Color sshDisconnected = Color(0xFF6B7280); // gray-500
  static const Color sshConnecting = Color(0xFFF59E0B); // amber-500
  static const Color sshError = Color(0xFFEF4444); // red-500
  static const Color sshAuthentication = Color(0xFF8B5CF6); // violet-500
  
  // File Transfer Colors
  static const Color transferProgress = Color(0xFF3B82F6); // blue-500
  static const Color transferComplete = Color(0xFF10B981); // emerald-500
  static const Color transferError = Color(0xFFEF4444); // red-500
  static const Color transferPaused = Color(0xFFF59E0B); // amber-500
  
  // AI Assistant Colors
  static const Color aiUser = Color(0xFF3B82F6); // blue-500
  static const Color aiAssistant = Color(0xFF8B5CF6); // violet-500
  static const Color aiSystem = Color(0xFF6B7280); // gray-500
  static const Color aiError = Color(0xFFEF4444); // red-500
  
  // Widget Dashboard Colors
  static const Color widgetBackground = Color(0xFFFFFFFF); // white
  static const Color widgetBackgroundDark = Color(0xFF1E293B); // slate-800
  static const Color widgetBorder = Color(0xFFE5E7EB); // gray-200
  static const Color widgetBorderDark = Color(0xFF334155); // slate-700
  static const Color widgetHandle = Color(0xFF9CA3AF); // gray-400
  static const Color widgetHandleDark = Color(0xFF64748B); // slate-500
  
  // Utility Methods
  static Color withOpacity(Color color, double opacity) {
    return color.withOpacity(opacity);
  }
  
  static Color lighten(Color color, [double amount = 0.1]) {
    final hsl = HSLColor.fromColor(color);
    final lightness = (hsl.lightness + amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }
  
  static Color darken(Color color, [double amount = 0.1]) {
    final hsl = HSLColor.fromColor(color);
    final lightness = (hsl.lightness - amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }
  
  static Color adjustSaturation(Color color, double saturation) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withSaturation(saturation.clamp(0.0, 1.0)).toColor();
  }
  
  static Color adjustHue(Color color, double hue) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withHue((hsl.hue + hue) % 360).toColor();
  }
  
  // Color Scheme Helpers
  static ColorScheme get lightColorScheme => ColorScheme.light(
    primary: primary,
    primaryContainer: primaryLight,
    secondary: secondary,
    secondaryContainer: secondaryLight,
    surface: surfaceLight,
    background: backgroundLight,
    error: error,
    onPrimary: white,
    onSecondary: white,
    onSurface: textPrimary,
    onBackground: textPrimary,
    onError: white,
    outline: border,
    shadow: shadow,
  );
  
  static ColorScheme get darkColorScheme => ColorScheme.dark(
    primary: primary,
    primaryContainer: primaryDark,
    secondary: secondary,
    secondaryContainer: secondaryDark,
    surface: surfaceDark,
    background: backgroundDark,
    error: error,
    onPrimary: white,
    onSecondary: white,
    onSurface: textPrimaryDark,
    onBackground: textPrimaryDark,
    onError: white,
    outline: borderDark,
    shadow: shadowDark,
  );
}