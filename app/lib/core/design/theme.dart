import 'package:flutter/material.dart';
import 'package:mazad/core/design/tokens.dart';
import 'package:mazad/core/design/typography.dart';

ThemeData buildMazadTheme({required String lang, required Brightness brightness}) {
  final isDark = brightness == Brightness.dark;

  final colorScheme = isDark
      ? const ColorScheme.dark(
          primary: MazadTokens.primary,
          onPrimary: MazadTokens.onPrimary,
          secondary: MazadTokens.info,
          onSecondary: MazadTokens.onPrimary,
          surface: MazadTokens.surface,
          onSurface: MazadTokens.onSurface,
          error: MazadTokens.error,
          onError: MazadTokens.onPrimary,
          outline: MazadTokens.outline,
        )
      : const ColorScheme.light(
          primary: MazadTokens.primaryLight,
          onPrimary: MazadTokens.onPrimaryLight,
          secondary: MazadTokens.info,
          onSecondary: MazadTokens.onPrimaryLight,
          surface: MazadTokens.surfaceLight,
          onSurface: MazadTokens.onSurfaceLight,
          error: MazadTokens.error,
          onError: MazadTokens.onPrimaryLight,
          outline: MazadTokens.outlineLight,
        );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: colorScheme,
    scaffoldBackgroundColor:
        isDark ? MazadTokens.background : MazadTokens.backgroundLight,
    textTheme: buildTextTheme(lang: lang, onSurface: colorScheme.onSurface),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MazadTokens.radiusMd),
        ),
        textStyle: baseStyleForLocale(lang).copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}
