import 'package:flutter/material.dart';

/// App Spacing System - Consistent spacing and sizing scale
class AppSpacing {
  // Base spacing unit (4px)
  static const double _unit = 4.0;
  
  // Spacing scale (based on 4px unit)
  static const double xs = _unit; // 4px
  static const double sm = _unit * 2; // 8px
  static const double md = _unit * 3; // 12px
  static const double lg = _unit * 4; // 16px
  static const double xl = _unit * 5; // 20px
  static const double xxl = _unit * 6; // 24px
  static const double xxxl = _unit * 8; // 32px
  static const double xxxxl = _unit * 10; // 40px
  static const double xxxxxl = _unit * 12; // 48px
  static const double xxxxxxl = _unit * 16; // 64px
  
  // Semantic spacing
  static const double none = 0;
  static const double tiny = xs; // 4px
  static const double small = sm; // 8px
  static const double medium = lg; // 16px
  static const double large = xxl; // 24px
  static const double extraLarge = xxxl; // 32px
  static const double huge = xxxxl; // 40px
  static const double massive = xxxxxl; // 48px
  static const double giant = xxxxxxl; // 64px
  
  // Component-specific spacing
  
  // Padding
  static const double paddingXS = xs; // 4px
  static const double paddingSM = sm; // 8px
  static const double paddingMD = md; // 12px
  static const double paddingLG = lg; // 16px
  static const double paddingXL = xl; // 20px
  static const double paddingXXL = xxl; // 24px
  static const double paddingXXXL = xxxl; // 32px
  
  // Margin
  static const double marginXS = xs; // 4px
  static const double marginSM = sm; // 8px
  static const double marginMD = md; // 12px
  static const double marginLG = lg; // 16px
  static const double marginXL = xl; // 20px
  static const double marginXXL = xxl; // 24px
  static const double marginXXXL = xxxl; // 32px
  
  // Gap (for Flex widgets)
  static const double gapXS = xs; // 4px
  static const double gapSM = sm; // 8px
  static const double gapMD = md; // 12px
  static const double gapLG = lg; // 16px
  static const double gapXL = xl; // 20px
  static const double gapXXL = xxl; // 24px
  static const double gapXXXL = xxxl; // 32px
  
  // Card spacing
  static const double cardPadding = lg; // 16px
  static const double cardMargin = sm; // 8px
  static const double cardGap = md; // 12px
  
  // Button spacing
  static const double buttonPaddingHorizontal = lg; // 16px
  static const double buttonPaddingVertical = md; // 12px
  static const double buttonPaddingSmallHorizontal = md; // 12px
  static const double buttonPaddingSmallVertical = sm; // 8px
  static const double buttonPaddingLargeHorizontal = xl; // 20px
  static const double buttonPaddingLargeVertical = lg; // 16px
  static const double buttonGap = sm; // 8px
  
  // Input field spacing
  static const double inputPaddingHorizontal = lg; // 16px
  static const double inputPaddingVertical = md; // 12px
  static const double inputMargin = sm; // 8px
  static const double inputGap = xs; // 4px
  
  // List item spacing
  static const double listItemPadding = lg; // 16px
  static const double listItemGap = sm; // 8px
  static const double listItemMargin = xs; // 4px
  
  // Dialog spacing
  static const double dialogPadding = xxl; // 24px
  static const double dialogMargin = lg; // 16px
  static const double dialogGap = lg; // 16px
  
  // App bar spacing
  static const double appBarPadding = lg; // 16px
  static const double appBarHeight = 56.0;
  static const double appBarElevation = 0.0;
  
  // Navigation spacing
  static const double navigationPadding = sm; // 8px
  static const double navigationItemPadding = md; // 12px
  static const double navigationGap = xs; // 4px
  
  // Tab spacing
  static const double tabPadding = lg; // 16px
  static const double tabHeight = 48.0;
  static const double tabGap = sm; // 8px
  
  // Drawer spacing
  static const double drawerPadding = lg; // 16px
  static const double drawerItemPadding = md; // 12px
  static const double drawerGap = xs; // 4px
  static const double drawerWidth = 280.0;
  
  // Bottom sheet spacing
  static const double bottomSheetPadding = xxl; // 24px
  static const double bottomSheetMargin = lg; // 16px
  static const double bottomSheetGap = lg; // 16px
  
  // Snackbar spacing
  static const double snackbarPadding = lg; // 16px
  static const double snackbarMargin = lg; // 16px
  
  // Tooltip spacing
  static const double tooltipPadding = sm; // 8px
  static const double tooltipMargin = xs; // 4px
  
  // Server card specific spacing
  static const double serverCardPadding = lg; // 16px
  static const double serverCardMargin = sm; // 8px
  static const double serverCardGap = md; // 12px
  static const double serverCardHeaderGap = xs; // 4px
  static const double serverCardMetricGap = xs; // 4px
  
  // Terminal spacing
  static const double terminalPadding = md; // 12px
  static const double terminalMargin = sm; // 8px
  static const double terminalLineHeight = 20.0;
  
  // File transfer spacing
  static const double transferItemPadding = md; // 12px
  static const double transferItemGap = sm; // 8px
  static const double transferProgressHeight = 4.0;
  
  // AI chat spacing
  static const double chatMessagePadding = md; // 12px
  static const double chatMessageMargin = sm; // 8px
  static const double chatMessageGap = xs; // 4px
  static const double chatInputPadding = lg; // 16px
  
  // Widget dashboard spacing
  static const double widgetPadding = md; // 12px
  static const double widgetMargin = sm; // 8px
  static const double widgetGap = lg; // 16px
  static const double widgetHeaderHeight = 40.0;
  static const double widgetMinHeight = 120.0;
  static const double widgetMinWidth = 200.0;
  
  // Grid spacing
  static const double gridSpacing = lg; // 16px
  static const double gridPadding = lg; // 16px
  static const double gridItemMinWidth = 280.0;
  static const double gridItemMaxWidth = 400.0;
  
  // Icon sizes
  static const double iconXS = 12.0;
  static const double iconSM = 16.0;
  static const double iconMD = 20.0;
  static const double iconLG = 24.0;
  static const double iconXL = 28.0;
  static const double iconXXL = 32.0;
  static const double iconXXXL = 40.0;
  static const double iconXXXXL = 48.0;
  
  // Avatar sizes
  static const double avatarXS = 24.0;
  static const double avatarSM = 32.0;
  static const double avatarMD = 40.0;
  static const double avatarLG = 48.0;
  static const double avatarXL = 56.0;
  static const double avatarXXL = 64.0;
  
  // Badge sizes
  static const double badgeSize = 16.0;
  static const double badgeLargeSize = 20.0;
  static const double badgePadding = xs; // 4px
  
  // Divider sizes
  static const double dividerThickness = 1.0;
  static const double dividerIndent = lg; // 16px
  
  // Border radius (moved from app_borders.dart for consistency)
  static const double radiusXS = 2.0;
  static const double radiusSM = 4.0;
  static const double radiusMD = 6.0;
  static const double radiusLG = 8.0;
  static const double radiusXL = 12.0;
  static const double radiusXXL = 16.0;
  static const double radiusXXXL = 20.0;
  static const double radiusXXXXL = 24.0;
  static const double radiusRound = 999.0;
  
  // Breakpoints for responsive design
  static const double breakpointXS = 480.0;
  static const double breakpointSM = 768.0;
  static const double breakpointMD = 1024.0;
  static const double breakpointLG = 1280.0;
  static const double breakpointXL = 1536.0;
  
  // Z-index values
  static const double zIndexDropdown = 1000.0;
  static const double zIndexSticky = 1020.0;
  static const double zIndexFixed = 1030.0;
  static const double zIndexModalBackdrop = 1040.0;
  static const double zIndexOffcanvas = 1050.0;
  static const double zIndexModal = 1060.0;
  static const double zIndexPopover = 1070.0;
  static const double zIndexTooltip = 1080.0;
  
  // Animation durations
  static const Duration durationFast = Duration(milliseconds: 150);
  static const Duration durationNormal = Duration(milliseconds: 250);
  static const Duration durationSlow = Duration(milliseconds: 350);
  static const Duration durationSlower = Duration(milliseconds: 500);
  
  // Utility methods
  static EdgeInsets all(double value) => EdgeInsets.all(value);
  static EdgeInsets symmetric({double vertical = 0, double horizontal = 0}) =>
      EdgeInsets.symmetric(vertical: vertical, horizontal: horizontal);
  static EdgeInsets only({
    double left = 0,
    double top = 0,
    double right = 0,
    double bottom = 0,
  }) =>
      EdgeInsets.only(left: left, top: top, right: right, bottom: bottom);
  
  static EdgeInsets get paddingXSAll => all(paddingXS);
  static EdgeInsets get paddingSMAll => all(paddingSM);
  static EdgeInsets get paddingMDAll => all(paddingMD);
  static EdgeInsets get paddingLGAll => all(paddingLG);
  static EdgeInsets get paddingXLAll => all(paddingXL);
  static EdgeInsets get paddingXXLAll => all(paddingXXL);
  
  static EdgeInsets get paddingHorizontalSM => symmetric(horizontal: paddingSM);
  static EdgeInsets get paddingHorizontalMD => symmetric(horizontal: paddingMD);
  static EdgeInsets get paddingHorizontalLG => symmetric(horizontal: paddingLG);
  static EdgeInsets get paddingHorizontalXL => symmetric(horizontal: paddingXL);
  
  static EdgeInsets get paddingVerticalSM => symmetric(vertical: paddingSM);
  static EdgeInsets get paddingVerticalMD => symmetric(vertical: paddingMD);
  static EdgeInsets get paddingVerticalLG => symmetric(vertical: paddingLG);
  static EdgeInsets get paddingVerticalXL => symmetric(vertical: paddingXL);
  
  static EdgeInsets get marginXSAll => all(marginXS);
  static EdgeInsets get marginSMAll => all(marginSM);
  static EdgeInsets get marginMDAll => all(marginMD);
  static EdgeInsets get marginLGAll => all(marginLG);
  static EdgeInsets get marginXLAll => all(marginXL);
  static EdgeInsets get marginXXLAll => all(marginXXL);
  
  static EdgeInsets get marginHorizontalSM => symmetric(horizontal: marginSM);
  static EdgeInsets get marginHorizontalMD => symmetric(horizontal: marginMD);
  static EdgeInsets get marginHorizontalLG => symmetric(horizontal: marginLG);
  static EdgeInsets get marginHorizontalXL => symmetric(horizontal: marginXL);
  
  static EdgeInsets get marginVerticalSM => symmetric(vertical: marginSM);
  static EdgeInsets get marginVerticalMD => symmetric(vertical: marginMD);
  static EdgeInsets get marginVerticalLG => symmetric(vertical: marginLG);
  static EdgeInsets get marginVerticalXL => symmetric(vertical: marginXL);
  
  // SizedBox helpers
  static Widget get gapXSBox => SizedBox(width: gapXS, height: gapXS);
  static Widget get gapSMBox => SizedBox(width: gapSM, height: gapSM);
  static Widget get gapMDBox => SizedBox(width: gapMD, height: gapMD);
  static Widget get gapLGBox => SizedBox(width: gapLG, height: gapLG);
  static Widget get gapXLBox => SizedBox(width: gapXL, height: gapXL);
  static Widget get gapXXLBox => SizedBox(width: gapXXL, height: gapXXL);
  
  static Widget gapWidth(double width) => SizedBox(width: width);
  static Widget gapHeight(double height) => SizedBox(height: height);
  
  // Responsive helpers
  static bool isXS(double width) => width < breakpointXS;
  static bool isSM(double width) => width >= breakpointXS && width < breakpointSM;
  static bool isMD(double width) => width >= breakpointSM && width < breakpointMD;
  static bool isLG(double width) => width >= breakpointMD && width < breakpointLG;
  static bool isXL(double width) => width >= breakpointLG;
  
  static int getGridColumns(double width) {
    if (isXS(width)) return 1;
    if (isSM(width)) return 2;
    if (isMD(width)) return 3;
    if (isLG(width)) return 4;
    return 6;
  }
  
  static double getGridItemWidth(double screenWidth, int columns) {
    final availableWidth = screenWidth - (gridPadding * 2) - (gridSpacing * (columns - 1));
    return availableWidth / columns;
  }
}