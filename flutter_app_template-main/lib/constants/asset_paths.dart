/// Typed references to bundled assets.
///
/// A misspelled asset string only fails at runtime; a misspelled constant fails
/// at compile time. Always add the asset here before using it, and make sure
/// the folder is declared in `pubspec.yaml`.
abstract final class AssetPaths {
  static const String _images = 'assets/images';
  static const String _icons = 'assets/icons';

  // Onboarding illustrations — drop the files in and they render.
  static const String onboardingOne = '$_images/onboarding_1.png';
  static const String onboardingTwo = '$_images/onboarding_2.png';
  static const String onboardingThree = '$_images/onboarding_3.png';

  static const String logo = '$_images/logo.png';
  static const String placeholder = '$_images/placeholder.png';
  static const String emptyState = '$_images/empty_state.png';

  static const String googleIcon = '$_icons/google.png';
  static const String appleIcon = '$_icons/apple.png';
}
