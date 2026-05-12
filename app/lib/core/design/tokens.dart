import 'package:flutter/material.dart';

/// "Tigris" design tokens. See ADR-0005.
///
/// Never inline colors, spacing, or font sizes elsewhere — always reference
/// these tokens. Two refactors per token is a sign to extract a new one here.
class MazadTokens {
  MazadTokens._();

  // ─── Color (dark — primary surface) ────────────────────────────────────
  static const Color primary = Color(0xFFD4A04C);
  static const Color onPrimary = Color(0xFF0E1116);
  static const Color background = Color(0xFF0E1116);
  static const Color surface = Color(0xFF171B22);
  static const Color onSurface = Color(0xFFEDE6D6);
  static const Color onSurfaceMuted = Color(0xFF9B9382);
  static const Color outline = Color(0xFF2A2F38);
  static const Color success = Color(0xFF5BA98F); // bid-up
  static const Color error = Color(0xFFE04E3D);   // outbid
  static const Color info = Color(0xFF7DA9D8);

  // ─── Color (light) ─────────────────────────────────────────────────────
  static const Color primaryLight = Color(0xFFA87A2C);
  static const Color onPrimaryLight = Color(0xFFFFFBF2);
  static const Color backgroundLight = Color(0xFFFBF8F2);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color onSurfaceLight = Color(0xFF1A1614);
  static const Color outlineLight = Color(0xFFD9D4C7);

  // ─── Spacing scale (8pt baseline + 4pt half-step) ──────────────────────
  static const double sp1 = 4;
  static const double sp2 = 8;
  static const double sp3 = 12;
  static const double sp4 = 16;
  static const double sp5 = 24;
  static const double sp6 = 32;
  static const double sp7 = 48;
  static const double sp8 = 64;

  // ─── Radius ────────────────────────────────────────────────────────────
  static const double radiusSm = 6;
  static const double radiusMd = 12;
  static const double radiusLg = 20;
  static const double radiusPill = 999;

  // ─── Motion ────────────────────────────────────────────────────────────
  static const Duration motionFast = Duration(milliseconds: 120);
  static const Duration motionMed = Duration(milliseconds: 240);
  static const Duration motionSlow = Duration(milliseconds: 400);
}
