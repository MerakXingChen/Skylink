import 'package:flutter/material.dart';
import 'app_colors.dart';

/// App Shadow System - Modern shadow effects and elevation
class AppShadows {
  // Base shadow colors
  static const Color _shadowColor = AppColors.shadow;
  static const Color _shadowColorDark = AppColors.shadowDark;
  
  // Shadow elevation levels (Material Design inspired but customized)
  
  // Level 0 - No shadow
  static const List<BoxShadow> none = [];
  
  // Level 1 - Subtle shadow for cards and buttons
  static const List<BoxShadow> xs = [
    BoxShadow(
      color: Color(0x0D000000), // 5% opacity
      offset: Offset(0, 1),
      blurRadius: 2,
      spreadRadius: 0,
    ),
  ];
  
  // Level 2 - Small shadow for elevated elements
  static const List<BoxShadow> sm = [
    BoxShadow(
      color: Color(0x1A000000), // 10% opacity
      offset: Offset(0, 1),
      blurRadius: 3,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Color(0x0D000000), // 5% opacity
      offset: Offset(0, 1),
      blurRadius: 2,
      spreadRadius: 0,
    ),
  ];
  
  // Level 3 - Medium shadow for floating elements
  static const List<BoxShadow> md = [
    BoxShadow(
      color: Color(0x1A000000), // 10% opacity
      offset: Offset(0, 4),
      blurRadius: 6,
      spreadRadius: -1,
    ),
    BoxShadow(
      color: Color(0x0D000000), // 5% opacity
      offset: Offset(0, 2),
      blurRadius: 4,
      spreadRadius: -1,
    ),
  ];
  
  // Level 4 - Large shadow for modals and overlays
  static const List<BoxShadow> lg = [
    BoxShadow(
      color: Color(0x26000000), // 15% opacity
      offset: Offset(0, 10),
      blurRadius: 15,
      spreadRadius: -3,
    ),
    BoxShadow(
      color: Color(0x1A000000), // 10% opacity
      offset: Offset(0, 4),
      blurRadius: 6,
      spreadRadius: -2,
    ),
  ];
  
  // Level 5 - Extra large shadow for major overlays
  static const List<BoxShadow> xl = [
    BoxShadow(
      color: Color(0x33000000), // 20% opacity
      offset: Offset(0, 20),
      blurRadius: 25,
      spreadRadius: -5,
    ),
    BoxShadow(
      color: Color(0x1A000000), // 10% opacity
      offset: Offset(0, 8),
      blurRadius: 10,
      spreadRadius: -5,
    ),
  ];
  
  // Level 6 - Maximum shadow for major modals
  static const List<BoxShadow> xxl = [
    BoxShadow(
      color: Color(0x4D000000), // 30% opacity
      offset: Offset(0, 25),
      blurRadius: 50,
      spreadRadius: -12,
    ),
    BoxShadow(
      color: Color(0x26000000), // 15% opacity
      offset: Offset(0, 12),
      blurRadius: 16,
      spreadRadius: -4,
    ),
  ];
  
  // Dark theme shadows (more prominent)
  static const List<BoxShadow> xsDark = [
    BoxShadow(
      color: Color(0x1A000000), // 10% opacity
      offset: Offset(0, 1),
      blurRadius: 3,
      spreadRadius: 0,
    ),
  ];
  
  static const List<BoxShadow> smDark = [
    BoxShadow(
      color: Color(0x26000000), // 15% opacity
      offset: Offset(0, 2),
      blurRadius: 4,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Color(0x1A000000), // 10% opacity
      offset: Offset(0, 1),
      blurRadius: 2,
      spreadRadius: 0,
    ),
  ];
  
  static const List<BoxShadow> mdDark = [
    BoxShadow(
      color: Color(0x33000000), // 20% opacity
      offset: Offset(0, 4),
      blurRadius: 8,
      spreadRadius: -1,
    ),
    BoxShadow(
      color: Color(0x1A000000), // 10% opacity
      offset: Offset(0, 2),
      blurRadius: 4,
      spreadRadius: -1,
    ),
  ];
  
  static const List<BoxShadow> lgDark = [
    BoxShadow(
      color: Color(0x4D000000), // 30% opacity
      offset: Offset(0, 10),
      blurRadius: 20,
      spreadRadius: -3,
    ),
    BoxShadow(
      color: Color(0x26000000), // 15% opacity
      offset: Offset(0, 4),
      blurRadius: 8,
      spreadRadius: -2,
    ),
  ];
  
  static const List<BoxShadow> xlDark = [
    BoxShadow(
      color: Color(0x66000000), // 40% opacity
      offset: Offset(0, 20),
      blurRadius: 30,
      spreadRadius: -5,
    ),
    BoxShadow(
      color: Color(0x33000000), // 20% opacity
      offset: Offset(0, 8),
      blurRadius: 12,
      spreadRadius: -5,
    ),
  ];
  
  static const List<BoxShadow> xxlDark = [
    BoxShadow(
      color: Color(0x80000000), // 50% opacity
      offset: Offset(0, 25),
      blurRadius: 60,
      spreadRadius: -12,
    ),
    BoxShadow(
      color: Color(0x4D000000), // 30% opacity
      offset: Offset(0, 12),
      blurRadius: 20,
      spreadRadius: -4,
    ),
  ];
  
  // Semantic shadows for specific components
  
  // Card shadows
  static const List<BoxShadow> card = sm;
  static const List<BoxShadow> cardHover = md;
  static const List<BoxShadow> cardPressed = xs;
  static const List<BoxShadow> cardDark = smDark;
  static const List<BoxShadow> cardHoverDark = mdDark;
  static const List<BoxShadow> cardPressedDark = xsDark;
  
  // Button shadows
  static const List<BoxShadow> button = xs;
  static const List<BoxShadow> buttonHover = sm;
  static const List<BoxShadow> buttonPressed = none;
  static const List<BoxShadow> buttonDark = xsDark;
  static const List<BoxShadow> buttonHoverDark = smDark;
  static const List<BoxShadow> buttonPressedDark = none;
  
  // Floating Action Button shadows
  static const List<BoxShadow> fab = md;
  static const List<BoxShadow> fabHover = lg;
  static const List<BoxShadow> fabPressed = sm;
  static const List<BoxShadow> fabDark = mdDark;
  static const List<BoxShadow> fabHoverDark = lgDark;
  static const List<BoxShadow> fabPressedDark = smDark;
  
  // Modal shadows
  static const List<BoxShadow> modal = xl;
  static const List<BoxShadow> modalDark = xlDark;
  
  // Drawer shadows
  static const List<BoxShadow> drawer = lg;
  static const List<BoxShadow> drawerDark = lgDark;
  
  // App bar shadows
  static const List<BoxShadow> appBar = xs;
  static const List<BoxShadow> appBarDark = xsDark;
  
  // Bottom sheet shadows
  static const List<BoxShadow> bottomSheet = lg;
  static const List<BoxShadow> bottomSheetDark = lgDark;
  
  // Tooltip shadows
  static const List<BoxShadow> tooltip = sm;
  static const List<BoxShadow> tooltipDark = smDark;
  
  // Dropdown shadows
  static const List<BoxShadow> dropdown = md;
  static const List<BoxShadow> dropdownDark = mdDark;
  
  // Server card shadows
  static const List<BoxShadow> serverCard = sm;
  static const List<BoxShadow> serverCardHover = md;
  static const List<BoxShadow> serverCardSelected = lg;
  static const List<BoxShadow> serverCardDark = smDark;
  static const List<BoxShadow> serverCardHoverDark = mdDark;
  static const List<BoxShadow> serverCardSelectedDark = lgDark;
  
  // Terminal shadows
  static const List<BoxShadow> terminal = md;
  static const List<BoxShadow> terminalDark = mdDark;
  
  // Widget dashboard shadows
  static const List<BoxShadow> widget = sm;
  static const List<BoxShadow> widgetHover = md;
  static const List<BoxShadow> widgetDragging = lg;
  static const List<BoxShadow> widgetDark = smDark;
  static const List<BoxShadow> widgetHoverDark = mdDark;
  static const List<BoxShadow> widgetDraggingDark = lgDark;
  
  // Text shadows
  static const List<Shadow> textShadow = [
    Shadow(
      color: Color(0x26000000), // 15% opacity
      offset: Offset(0, 1),
      blurRadius: 2,
    ),
  ];
  
  static const List<Shadow> textShadowDark = [
    Shadow(
      color: Color(0x4D000000), // 30% opacity
      offset: Offset(0, 1),
      blurRadius: 3,
    ),
  ];
  
  static const List<Shadow> textShadowStrong = [
    Shadow(
      color: Color(0x4D000000), // 30% opacity
      offset: Offset(0, 2),
      blurRadius: 4,
    ),
  ];
  
  static const List<Shadow> textShadowStrongDark = [
    Shadow(
      color: Color(0x66000000), // 40% opacity
      offset: Offset(0, 2),
      blurRadius: 6,
    ),
  ];
  
  // Glow effects
  static const List<BoxShadow> glowPrimary = [
    BoxShadow(
      color: Color(0x4D3B82F6), // primary with 30% opacity
      offset: Offset(0, 0),
      blurRadius: 8,
      spreadRadius: 0,
    ),
  ];
  
  static const List<BoxShadow> glowSecondary = [
    BoxShadow(
      color: Color(0x4D8B5CF6), // secondary with 30% opacity
      offset: Offset(0, 0),
      blurRadius: 8,
      spreadRadius: 0,
    ),
  ];
  
  static const List<BoxShadow> glowSuccess = [
    BoxShadow(
      color: Color(0x4D10B981), // success with 30% opacity
      offset: Offset(0, 0),
      blurRadius: 8,
      spreadRadius: 0,
    ),
  ];
  
  static const List<BoxShadow> glowWarning = [
    BoxShadow(
      color: Color(0x4DF59E0B), // warning with 30% opacity
      offset: Offset(0, 0),
      blurRadius: 8,
      spreadRadius: 0,
    ),
  ];
  
  static const List<BoxShadow> glowError = [
    BoxShadow(
      color: Color(0x4DEF4444), // error with 30% opacity
      offset: Offset(0, 0),
      blurRadius: 8,
      spreadRadius: 0,
    ),
  ];
  
  // Inner shadows (using inset property when available)
  static const List<BoxShadow> innerShadow = [
    BoxShadow(
      color: Color(0x1A000000), // 10% opacity
      offset: Offset(0, 2),
      blurRadius: 4,
      spreadRadius: -2,
    ),
  ];
  
  static const List<BoxShadow> innerShadowDark = [
    BoxShadow(
      color: Color(0x33000000), // 20% opacity
      offset: Offset(0, 2),
      blurRadius: 6,
      spreadRadius: -2,
    ),
  ];
  
  // Utility methods
  static List<BoxShadow> getShadow(String level, {bool isDark = false}) {
    switch (level) {
      case 'xs':
        return isDark ? xsDark : xs;
      case 'sm':
        return isDark ? smDark : sm;
      case 'md':
        return isDark ? mdDark : md;
      case 'lg':
        return isDark ? lgDark : lg;
      case 'xl':
        return isDark ? xlDark : xl;
      case 'xxl':
        return isDark ? xxlDark : xxl;
      default:
        return isDark ? smDark : sm;
    }
  }
  
  static List<BoxShadow> getComponentShadow(String component, {bool isDark = false, String? state}) {
    switch (component) {
      case 'card':
        if (state == 'hover') return isDark ? cardHoverDark : cardHover;
        if (state == 'pressed') return isDark ? cardPressedDark : cardPressed;
        return isDark ? cardDark : card;
      case 'button':
        if (state == 'hover') return isDark ? buttonHoverDark : buttonHover;
        if (state == 'pressed') return isDark ? buttonPressedDark : buttonPressed;
        return isDark ? buttonDark : button;
      case 'fab':
        if (state == 'hover') return isDark ? fabHoverDark : fabHover;
        if (state == 'pressed') return isDark ? fabPressedDark : fabPressed;
        return isDark ? fabDark : fab;
      case 'modal':
        return isDark ? modalDark : modal;
      case 'drawer':
        return isDark ? drawerDark : drawer;
      case 'appBar':
        return isDark ? appBarDark : appBar;
      case 'bottomSheet':
        return isDark ? bottomSheetDark : bottomSheet;
      case 'tooltip':
        return isDark ? tooltipDark : tooltip;
      case 'dropdown':
        return isDark ? dropdownDark : dropdown;
      case 'serverCard':
        if (state == 'hover') return isDark ? serverCardHoverDark : serverCardHover;
        if (state == 'selected') return isDark ? serverCardSelectedDark : serverCardSelected;
        return isDark ? serverCardDark : serverCard;
      case 'terminal':
        return isDark ? terminalDark : terminal;
      case 'widget':
        if (state == 'hover') return isDark ? widgetHoverDark : widgetHover;
        if (state == 'dragging') return isDark ? widgetDraggingDark : widgetDragging;
        return isDark ? widgetDark : widget;
      default:
        return isDark ? smDark : sm;
    }
  }
  
  static List<BoxShadow> getGlowShadow(String color) {
    switch (color) {
      case 'primary':
        return glowPrimary;
      case 'secondary':
        return glowSecondary;
      case 'success':
        return glowSuccess;
      case 'warning':
        return glowWarning;
      case 'error':
        return glowError;
      default:
        return glowPrimary;
    }
  }
  
  static List<Shadow> getTextShadow({bool isDark = false, bool strong = false}) {
    if (strong) {
      return isDark ? textShadowStrongDark : textShadowStrong;
    }
    return isDark ? textShadowDark : textShadow;
  }
  
  static BoxShadow createCustomShadow({
    required Color color,
    required Offset offset,
    required double blurRadius,
    double spreadRadius = 0,
  }) {
    return BoxShadow(
      color: color,
      offset: offset,
      blurRadius: blurRadius,
      spreadRadius: spreadRadius,
    );
  }
  
  static Shadow createCustomTextShadow({
    required Color color,
    required Offset offset,
    required double blurRadius,
  }) {
    return Shadow(
      color: color,
      offset: offset,
      blurRadius: blurRadius,
    );
  }
}