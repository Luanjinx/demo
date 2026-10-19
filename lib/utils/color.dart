import 'package:flutter/material.dart';

// ============================================================================
// Nexstream Color System (Synced 1-to-1 with dtlive-app)
// ============================================================================
const colorPrimary = Color(0xffBAFA34); // Signature Nexstream Neon Lime
const colorPrimaryDark = Color(0xff6EBE6B);
const colorAccent = Color(0xffBAFA34);

const appBgColor = Color(0xFF000000); // True OLED Pitch Black
const secondaryBgColor = Color(0xFF1F2229); // Dark Charcoal Container
const authPanelBgColor = Color(0xFF0E0E16); // Deep Indigo/Black Panel
const complimentryColor = Color(0xff792bec); // Electric Purple
const titleTextColor = Color(0xffffffff);
const descTextColor = Color(0xffa9aaac);
const defaultIconColor = Color(0xff676767);

const edtShadowColor = Color(0xff707070);
const secProgressColor = Color(0x80a9aaac);

const transparent = Color.fromRGBO(0, 0, 0, 0);
const white = Color(0xffffffff);
const black = Color(0xff000000);
const lightBlack = Color(0xff171A1B);
const gray = Color(0xff777D73);
const grayDark = Color(0xff454545);
const shimmerColor = Color(0xff454545);
const shimmerItemColor = Color(0xff0c0c0d);

const successBG = Color(0xff007c60);
const warningBG = Color(0xffFFA500);
const infoBG = Color(0xff0096FF);
const failureBG = Color(0xffde323e);
const redColor = Color(0xffd6181b);
const greenColor = Color(0xff008000);

/// Semantic Colors for Android TV Experience
class TVColors {
  // Base backgrounds (Synced with dtlive-app)
  static const Color appBg = appBgColor; // 0xFF000000
  static const Color surfaceBg = secondaryBgColor; // 0xFF1F2229
  static const Color cardBg = lightBlack; // 0xFF171A1B
  static const Color sidebarBg = authPanelBgColor; // 0xFF0E0E16

  // Accents (Synced with dtlive-app Lime Green #BAFA34 & Purple #792BEC)
  static const Color primary = colorPrimary; // Color(0xffBAFA34)
  static const Color primaryDark = colorPrimaryDark; // Color(0xff6EBE6B)
  static const Color primaryLight = Color(0xffD6FC68);
  static const Color accent = colorAccent; // Color(0xffBAFA34)
  static const Color purpleAccent = complimentryColor; // Color(0xff792bec)

  // Focus & Highlights (Optimized for Android TV remote control D-Pad)
  static const Color focusBorder = colorPrimary; // Neon Lime border when focused
  static const Color focusGlow = Color(0x55BAFA34); // Glowing Lime halo
  static const Color focusPrimaryGlow = Color(0x80BAFA34);

  // Typography (Synced with dtlive-app)
  static const Color textPrimary = titleTextColor; // 0xffffffff
  static const Color textSecondary = descTextColor; // 0xffa9aaac
  static const Color textMuted = defaultIconColor; // 0xff676767

  // Badges & States
  static const Color vipGold = Color(0xFFFFB800);
  static const Color ratingStar = Color(0xFFFFC107);
  static const Color liveRed = redColor; // 0xffd6181b
  static const Color hdBadge = colorPrimary; // 0xffBAFA34

  // Overlays
  static const Color backdropGradientStart = Color(0x00000000);
  static const Color backdropGradientEnd = Color(0xFF000000);
}
