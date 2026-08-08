import 'package:flutter/widgets.dart';

import '../constants/asset_paths.dart';
import '../generated/l10n/app_localizations.dart';

/// The content of one onboarding slide.
///
/// Titles are resolved from [AppLocalizations] at build time rather than stored
/// as literals, so onboarding is translated like the rest of the app. Add a
/// slide by adding an entry to [pagesFor] and two ARB keys.
@immutable
class OnboardingPageData {
  const OnboardingPageData({
    required this.title,
    required this.description,
    required this.imageAsset,
    this.icon,
  });

  final String title;
  final String description;
  final String imageAsset;

  /// Shown when [imageAsset] is missing — keeps the flow presentable before
  /// the illustrations are designed.
  final IconData? icon;

  static List<OnboardingPageData> pagesFor(AppLocalizations l10n) => [
    OnboardingPageData(
      title: l10n.appName,
      description: l10n.onboardingStart,
      imageAsset: AssetPaths.onboardingOne,
    ),
    OnboardingPageData(
      title: l10n.homeTitle,
      description: l10n.commonEmpty,
      imageAsset: AssetPaths.onboardingTwo,
    ),
    OnboardingPageData(
      title: l10n.settingsTitle,
      description: l10n.settingsTheme,
      imageAsset: AssetPaths.onboardingThree,
    ),
  ];
}
