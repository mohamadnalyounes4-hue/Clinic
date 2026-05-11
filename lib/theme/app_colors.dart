import 'package:flutter/material.dart';

/// App color palette based on the design requirements:
/// Light blue/white primary with soft pastels (light blue, green, pink, yellow)
class AppColors {
  // Primary colors
  static const Color primary = Color(0xFF4A90E2); // Light blue
  static const Color primaryDark = Color(0xFF357ABD);
  static const Color primaryLight = Color(0xFF7BB3F0);

  // Secondary colors
  static const Color secondary = Color(0xFF50C878); // Soft green
  static const Color accent = Color(0xFFFF6B9D); // Soft pink
  static const Color warning = Color(0xFFFFD93D); // Soft yellow

  // Neutral colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color grey = Color(0xFF9E9E9E);
  static const Color greyLight = Color(0xFFF5F5F5);
  static const Color greyDark = Color(0xFF616161);

  // Background colors
  static const Color background = Color(0xFFF8FBFF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF0F4F8);

  // Text colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFF9E9E9E);

  // Status colors
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);

  // Gradient colors
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryLight, primary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient softBlueGradient = LinearGradient(
    colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
