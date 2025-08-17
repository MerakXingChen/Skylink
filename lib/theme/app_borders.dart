import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_spacing.dart';

/// App Border System - Modern border styles and radius
class AppBorders {
  // Border widths
  static const double thin = 1.0;
  static const double normal = 1.5;
  static const double thick = 2.0;
  static const double extraThick = 3.0;
  
  // Border radius (using values from AppSpacing for consistency)
  static const double radiusXS = AppSpacing.radiusXS; // 2.0
  static const double radiusSM = AppSpacing.radiusSM; // 4.0
  static const double radiusMD = AppSpacing.radiusMD; // 6.0
  static const double radiusLG = AppSpacing.radiusLG; // 8.0
  static const double radiusXL = AppSpacing.radiusXL; // 12.0
  static const double radiusXXL = AppSpacing.radiusXXL; // 16.0
  static const double radiusXXXL = AppSpacing.radiusXXXL; // 20.0
  static const double radiusXXXXL = AppSpacing.radiusXXXXL; // 24.0
  static const double radiusRound = AppSpacing.radiusRound; // 999.0
  
  // Border colors
  static const Color light = AppColors.border;
  static const Color normal = AppColors.borderDark;
  static const Color dark = AppColors.gray400;
  static const Color primary = AppColors.primary;
  static const Color secondary = AppColors.secondary;
  static const Color success = AppColors.success;
  static const Color warning = AppColors.warning;
  static const Color error = AppColors.error;
  static const Color info = AppColors.info;
  
  // Dark theme border colors
  static const Color lightDark = AppColors.borderDark;
  static const Color normalDark = AppColors.borderLightDark;
  static const Color darkDark = AppColors.borderDarkDark;
  
  // Border radius helpers
  static BorderRadius get radiusXSAll => BorderRadius.circular(radiusXS);
  static BorderRadius get radiusSMAll => BorderRadius.circular(radiusSM);
  static BorderRadius get radiusMDAll => BorderRadius.circular(radiusMD);
  static BorderRadius get radiusLGAll => BorderRadius.circular(radiusLG);
  static BorderRadius get radiusXLAll => BorderRadius.circular(radiusXL);
  static BorderRadius get radiusXXLAll => BorderRadius.circular(radiusXXL);
  static BorderRadius get radiusXXXLAll => BorderRadius.circular(radiusXXXL);
  static BorderRadius get radiusXXXXLAll => BorderRadius.circular(radiusXXXXL);
  static BorderRadius get radiusRoundAll => BorderRadius.circular(radiusRound);
  
  // Directional border radius
  static BorderRadius radiusTop(double radius) => BorderRadius.only(
    topLeft: Radius.circular(radius),
    topRight: Radius.circular(radius),
  );
  
  static BorderRadius radiusBottom(double radius) => BorderRadius.only(
    bottomLeft: Radius.circular(radius),
    bottomRight: Radius.circular(radius),
  );
  
  static BorderRadius radiusLeft(double radius) => BorderRadius.only(
    topLeft: Radius.circular(radius),
    bottomLeft: Radius.circular(radius),
  );
  
  static BorderRadius radiusRight(double radius) => BorderRadius.only(
    topRight: Radius.circular(radius),
    bottomRight: Radius.circular(radius),
  );
  
  static BorderRadius radiusTopLeft(double radius) => BorderRadius.only(
    topLeft: Radius.circular(radius),
  );
  
  static BorderRadius radiusTopRight(double radius) => BorderRadius.only(
    topRight: Radius.circular(radius),
  );
  
  static BorderRadius radiusBottomLeft(double radius) => BorderRadius.only(
    bottomLeft: Radius.circular(radius),
  );
  
  static BorderRadius radiusBottomRight(double radius) => BorderRadius.only(
    bottomRight: Radius.circular(radius),
  );
  
  // Basic border styles
  static Border get thinLight => Border.all(color: light, width: thin);
  static Border get normalLight => Border.all(color: light, width: normal);
  static Border get thickLight => Border.all(color: light, width: thick);
  
  static Border get thinNormal => Border.all(color: normal, width: thin);
  static Border get normalNormal => Border.all(color: normal, width: normal);
  static Border get thickNormal => Border.all(color: normal, width: thick);
  
  static Border get thinDark => Border.all(color: dark, width: thin);
  static Border get normalDark => Border.all(color: dark, width: normal);
  static Border get thickDark => Border.all(color: dark, width: thick);
  
  // Colored borders
  static Border get thinPrimary => Border.all(color: primary, width: thin);
  static Border get normalPrimary => Border.all(color: primary, width: normal);
  static Border get thickPrimary => Border.all(color: primary, width: thick);
  
  static Border get thinSecondary => Border.all(color: secondary, width: thin);
  static Border get normalSecondary => Border.all(color: secondary, width: normal);
  static Border get thickSecondary => Border.all(color: secondary, width: thick);
  
  static Border get thinSuccess => Border.all(color: success, width: thin);
  static Border get normalSuccess => Border.all(color: success, width: normal);
  static Border get thickSuccess => Border.all(color: success, width: thick);
  
  static Border get thinWarning => Border.all(color: warning, width: thin);
  static Border get normalWarning => Border.all(color: warning, width: normal);
  static Border get thickWarning => Border.all(color: warning, width: thick);
  
  static Border get thinError => Border.all(color: error, width: thin);
  static Border get normalError => Border.all(color: error, width: normal);
  static Border get thickError => Border.all(color: error, width: thick);
  
  static Border get thinInfo => Border.all(color: info, width: thin);
  static Border get normalInfo => Border.all(color: info, width: normal);
  static Border get thickInfo => Border.all(color: info, width: thick);
  
  // Dark theme borders
  static Border get thinLightDark => Border.all(color: lightDark, width: thin);
  static Border get normalLightDark => Border.all(color: lightDark, width: normal);
  static Border get thickLightDark => Border.all(color: lightDark, width: thick);
  
  static Border get thinNormalDark => Border.all(color: normalDark, width: thin);
  static Border get normalNormalDark => Border.all(color: normalDark, width: normal);
  static Border get thickNormalDark => Border.all(color: normalDark, width: thick);
  
  static Border get thinDarkDark => Border.all(color: darkDark, width: thin);
  static Border get normalDarkDark => Border.all(color: darkDark, width: normal);
  static Border get thickDarkDark => Border.all(color: darkDark, width: thick);
  
  // Directional borders
  static Border borderTop(Color color, [double width = thin]) => Border(
    top: BorderSide(color: color, width: width),
  );
  
  static Border borderBottom(Color color, [double width = thin]) => Border(
    bottom: BorderSide(color: color, width: width),
  );
  
  static Border borderLeft(Color color, [double width = thin]) => Border(
    left: BorderSide(color: color, width: width),
  );
  
  static Border borderRight(Color color, [double width = thin]) => Border(
    right: BorderSide(color: color, width: width),
  );
  
  static Border borderHorizontal(Color color, [double width = thin]) => Border(
    top: BorderSide(color: color, width: width),
    bottom: BorderSide(color: color, width: width),
  );
  
  static Border borderVertical(Color color, [double width = thin]) => Border(
    left: BorderSide(color: color, width: width),
    right: BorderSide(color: color, width: width),
  );
  
  // Component-specific borders
  
  // Card borders
  static Border get card => thinLight;
  static Border get cardHover => normalPrimary;
  static Border get cardSelected => thickPrimary;
  static Border get cardDark => thinLightDark;
  static Border get cardHoverDark => normalPrimary;
  static Border get cardSelectedDark => thickPrimary;
  
  // Button borders
  static Border get button => thinNormal;
  static Border get buttonPrimary => thinPrimary;
  static Border get buttonSecondary => thinSecondary;
  static Border get buttonSuccess => thinSuccess;
  static Border get buttonWarning => thinWarning;
  static Border get buttonError => thinError;
  static Border get buttonDark => thinNormalDark;
  
  // Input borders
  static Border get input => thinNormal;
  static Border get inputFocus => normalPrimary;
  static Border get inputError => normalError;
  static Border get inputSuccess => normalSuccess;
  static Border get inputDark => thinNormalDark;
  static Border get inputFocusDark => normalPrimary;
  static Border get inputErrorDark => normalError;
  static Border get inputSuccessDark => normalSuccess;
  
  // Server card borders
  static Border get serverCard => thinLight;
  static Border get serverCardOnline => thinSuccess;
  static Border get serverCardOffline => thinNormal;
  static Border get serverCardError => thinError;
  static Border get serverCardConnecting => thinWarning;
  static Border get serverCardSelected => thickPrimary;
  static Border get serverCardDark => thinLightDark;
  static Border get serverCardOnlineDark => thinSuccess;
  static Border get serverCardOfflineDark => thinNormalDark;
  static Border get serverCardErrorDark => thinError;
  static Border get serverCardConnectingDark => thinWarning;
  static Border get serverCardSelectedDark => thickPrimary;
  
  // Terminal borders
  static Border get terminal => thinDark;
  static Border get terminalFocus => normalPrimary;
  static Border get terminalDark => thinDarkDark;
  static Border get terminalFocusDark => normalPrimary;
  
  // Widget borders
  static Border get widget => thinLight;
  static Border get widgetHover => normalPrimary;
  static Border get widgetSelected => thickPrimary;
  static Border get widgetDragging => thickSecondary;
  static Border get widgetDark => thinLightDark;
  static Border get widgetHoverDark => normalPrimary;
  static Border get widgetSelectedDark => thickPrimary;
  static Border get widgetDraggingDark => thickSecondary;
  
  // Modal borders
  static Border get modal => thinLight;
  static Border get modalDark => thinLightDark;
  
  // Drawer borders
  static Border get drawer => borderRight(light);
  static Border get drawerDark => borderRight(lightDark);
  
  // Tab borders
  static Border get tab => borderBottom(light);
  static Border get tabActive => borderBottom(primary, thick);
  static Border get tabDark => borderBottom(lightDark);
  static Border get tabActiveDark => borderBottom(primary, thick);
  
  // Divider borders
  static Border get divider => borderBottom(light);
  static Border get dividerDark => borderBottom(lightDark);
  
  // OutlineInputBorder helpers
  static OutlineInputBorder outlineInput({
    Color? color,
    double? width,
    double? radius,
  }) => OutlineInputBorder(
    borderSide: BorderSide(
      color: color ?? normal,
      width: width ?? thin,
    ),
    borderRadius: BorderRadius.circular(radius ?? radiusLG),
  );
  
  static OutlineInputBorder outlineInputFocus({
    Color? color,
    double? width,
    double? radius,
  }) => OutlineInputBorder(
    borderSide: BorderSide(
      color: color ?? primary,
      width: width ?? normal,
    ),
    borderRadius: BorderRadius.circular(radius ?? radiusLG),
  );
  
  static OutlineInputBorder outlineInputError({
    Color? color,
    double? width,
    double? radius,
  }) => OutlineInputBorder(
    borderSide: BorderSide(
      color: color ?? error,
      width: width ?? normal,
    ),
    borderRadius: BorderRadius.circular(radius ?? radiusLG),
  );
  
  // UnderlineInputBorder helpers
  static UnderlineInputBorder underlineInput({
    Color? color,
    double? width,
  }) => UnderlineInputBorder(
    borderSide: BorderSide(
      color: color ?? normal,
      width: width ?? thin,
    ),
  );
  
  static UnderlineInputBorder underlineInputFocus({
    Color? color,
    double? width,
  }) => UnderlineInputBorder(
    borderSide: BorderSide(
      color: color ?? primary,
      width: width ?? normal,
    ),
  );
  
  static UnderlineInputBorder underlineInputError({
    Color? color,
    double? width,
  }) => UnderlineInputBorder(
    borderSide: BorderSide(
      color: color ?? error,
      width: width ?? normal,
    ),
  );
  
  // Utility methods
  static Border createBorder({
    Color? color,
    double? width,
    BorderStyle? style,
  }) => Border.all(
    color: color ?? normal,
    width: width ?? thin,
    style: style ?? BorderStyle.solid,
  );
  
  static BorderSide createBorderSide({
    Color? color,
    double? width,
    BorderStyle? style,
  }) => BorderSide(
    color: color ?? normal,
    width: width ?? thin,
    style: style ?? BorderStyle.solid,
  );
  
  static BorderRadius createRadius({
    double? topLeft,
    double? topRight,
    double? bottomLeft,
    double? bottomRight,
  }) => BorderRadius.only(
    topLeft: Radius.circular(topLeft ?? 0),
    topRight: Radius.circular(topRight ?? 0),
    bottomLeft: Radius.circular(bottomLeft ?? 0),
    bottomRight: Radius.circular(bottomRight ?? 0),
  );
  
  static RoundedRectangleBorder roundedRectangleBorder({
    Color? color,
    double? width,
    double? radius,
  }) => RoundedRectangleBorder(
    side: BorderSide(
      color: color ?? normal,
      width: width ?? thin,
    ),
    borderRadius: BorderRadius.circular(radius ?? radiusLG),
  );
  
  static CircleBorder circleBorder({
    Color? color,
    double? width,
  }) => CircleBorder(
    side: BorderSide(
      color: color ?? normal,
      width: width ?? thin,
    ),
  );
  
  static StadiumBorder stadiumBorder({
    Color? color,
    double? width,
  }) => StadiumBorder(
    side: BorderSide(
      color: color ?? normal,
      width: width ?? thin,
    ),
  );
  
  // Border animation helpers
  static Border lerpBorder(Border a, Border b, double t) {
    return Border.lerp(a, b, t) ?? a;
  }
  
  static BorderRadius lerpBorderRadius(BorderRadius a, BorderRadius b, double t) {
    return BorderRadius.lerp(a, b, t) ?? a;
  }
  
  // Theme-aware border getters
  static Border getBorder(String type, {bool isDark = false, String? state}) {
    switch (type) {
      case 'card':
        if (state == 'hover') return isDark ? cardHoverDark : cardHover;
        if (state == 'selected') return isDark ? cardSelectedDark : cardSelected;
        return isDark ? cardDark : card;
      case 'button':
        return isDark ? buttonDark : button;
      case 'input':
        if (state == 'focus') return isDark ? inputFocusDark : inputFocus;
        if (state == 'error') return isDark ? inputErrorDark : inputError;
        if (state == 'success') return isDark ? inputSuccessDark : inputSuccess;
        return isDark ? inputDark : input;
      case 'serverCard':
        if (state == 'online') return isDark ? serverCardOnlineDark : serverCardOnline;
        if (state == 'offline') return isDark ? serverCardOfflineDark : serverCardOffline;
        if (state == 'error') return isDark ? serverCardErrorDark : serverCardError;
        if (state == 'connecting') return isDark ? serverCardConnectingDark : serverCardConnecting;
        if (state == 'selected') return isDark ? serverCardSelectedDark : serverCardSelected;
        return isDark ? serverCardDark : serverCard;
      case 'terminal':
        if (state == 'focus') return isDark ? terminalFocusDark : terminalFocus;
        return isDark ? terminalDark : terminal;
      case 'widget':
        if (state == 'hover') return isDark ? widgetHoverDark : widgetHover;
        if (state == 'selected') return isDark ? widgetSelectedDark : widgetSelected;
        if (state == 'dragging') return isDark ? widgetDraggingDark : widgetDragging;
        return isDark ? widgetDark : widget;
      case 'modal':
        return isDark ? modalDark : modal;
      case 'drawer':
        return isDark ? drawerDark : drawer;
      case 'tab':
        if (state == 'active') return isDark ? tabActiveDark : tabActive;
        return isDark ? tabDark : tab;
      case 'divider':
        return isDark ? dividerDark : divider;
      default:
        return isDark ? thinLightDark : thinLight;
    }
  }
  
  static BorderRadius getRadius(String size) {
    switch (size) {
      case 'xs':
        return radiusXSAll;
      case 'sm':
        return radiusSMAll;
      case 'md':
        return radiusMDAll;
      case 'lg':
        return radiusLGAll;
      case 'xl':
        return radiusXLAll;
      case 'xxl':
        return radiusXXLAll;
      case 'xxxl':
        return radiusXXXLAll;
      case 'xxxxl':
        return radiusXXXXLAll;
      case 'round':
        return radiusRoundAll;
      default:
        return radiusLGAll;
    }
  }
}