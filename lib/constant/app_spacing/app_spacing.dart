class AppSpacing {
  AppSpacing._();

  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 40;
  static const double xxxl = 48;
  static const double huge = 64;
}

class AppPadding {
  AppPadding._();

  // Screen-level horizontal padding (most screens use this)
  static const double screenHorizontal = AppSpacing.md;
  static const double screenVertical = AppSpacing.md;

  // Card / container internal padding
  static const double cardSmall = AppSpacing.sm;
  static const double cardMedium = AppSpacing.md;
  static const double cardLarge = AppSpacing.lg;

  // Button padding
  static const double buttonHorizontal = AppSpacing.lg;
  static const double buttonVertical = AppSpacing.sm;

  // Input field padding
  static const double inputHorizontal = AppSpacing.md;
  static const double inputVertical = AppSpacing.sm;
}