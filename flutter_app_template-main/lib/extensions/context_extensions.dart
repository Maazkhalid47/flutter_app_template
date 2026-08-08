import 'package:flutter/material.dart';

import '../generated/l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../utils/responsive.dart';

/// Shorthands for the things every widget reaches for.
///
/// These exist to keep build methods readable: `context.colors.primary` instead
/// of `Theme.of(context).colorScheme.primary`, `context.l10n.homeTitle`
/// instead of `AppLocalizations.of(context).homeTitle`.
extension BuildContextX on BuildContext {
  // --- Theme ---
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => Theme.of(this).textTheme;
  ColorScheme get colors => Theme.of(this).colorScheme;

  /// Semantic colours that Material's [ColorScheme] has no slot for
  /// (success, warning, info).
  AppSemanticColors get semanticColors =>
      Theme.of(this).extension<AppSemanticColors>() ?? AppSemanticColors.light;

  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  // --- Localization ---
  AppLocalizations get l10n => AppLocalizations.of(this);
  Locale get locale => Localizations.localeOf(this);
  bool get isRtl => Directionality.of(this) == TextDirection.rtl;

  // --- Media ---
  Size get screenDimensions => MediaQuery.sizeOf(this);
  double get screenWidth => MediaQuery.sizeOf(this).width;
  double get screenHeight => MediaQuery.sizeOf(this).height;
  EdgeInsets get viewPadding => MediaQuery.viewPaddingOf(this);
  EdgeInsets get viewInsets => MediaQuery.viewInsetsOf(this);

  /// True when the on-screen keyboard is covering part of the layout.
  bool get isKeyboardOpen => MediaQuery.viewInsetsOf(this).bottom > 0;

  // --- Responsive ---
  ScreenSize get screenSize => Responsive.of(this);
  bool get isMobile => screenSize.isMobile;
  bool get isTablet => screenSize.isTablet;
  bool get isDesktop => screenSize.isDesktop;

  /// Picks a value for the current size class. See [Responsive.value].
  T responsive<T>({required T mobile, T? tablet, T? desktop}) =>
      Responsive.value(this, mobile: mobile, tablet: tablet, desktop: desktop);

  // --- Navigation helpers that do not depend on the router package ---
  void unfocus() => FocusScope.of(this).unfocus();
}
