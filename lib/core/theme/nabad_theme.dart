import 'package:flutter/material.dart';
import 'package:nabad/core/theme/nabad_colors.dart';

class NabadTheme {
  const NabadTheme._();

  static ThemeData get light => _theme(
    brightness: Brightness.light,
    background: NabadColors.background,
    surface: Colors.white,
    text: NabadColors.darkText,
    muted: NabadColors.mutedText,
  );

  static ThemeData get dark => _theme(
    brightness: Brightness.dark,
    background: const Color(0xFF07191D),
    surface: const Color(0xFF10272C),
    text: const Color(0xFFE8F6F7),
    muted: const Color(0xFF9CB4B8),
  );

  static ThemeData _theme({
    required Brightness brightness,
    required Color background,
    required Color surface,
    required Color text,
    required Color muted,
  }) {
    final scheme = ColorScheme.fromSeed(
      seedColor: NabadColors.primary,
      brightness: brightness,
      surface: surface,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      cardColor: surface,
      dividerColor: brightness == Brightness.dark
          ? const Color(0xFF294147)
          : NabadColors.divider,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: text,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      cardTheme: CardThemeData(color: surface, surfaceTintColor: surface),
      dialogTheme: DialogThemeData(backgroundColor: surface),
      bottomSheetTheme: BottomSheetThemeData(backgroundColor: surface),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        labelStyle: TextStyle(color: muted),
      ),
      textTheme: ThemeData(
        brightness: brightness,
      ).textTheme.apply(bodyColor: text, displayColor: text),
    );
  }
}
