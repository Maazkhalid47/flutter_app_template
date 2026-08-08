// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Urdu (`ur`).
class AppLocalizationsUr extends AppLocalizations {
  AppLocalizationsUr([String locale = 'ur']) : super(locale);

  @override
  String get appName => 'ایپ ٹیمپلیٹ';

  @override
  String get onboardingSkip => 'چھوڑیں';

  @override
  String get onboardingNext => 'اگلا';

  @override
  String get onboardingStart => 'شروع کریں';

  @override
  String get authLoginTitle => 'خوش آمدید';

  @override
  String get authSignUpTitle => 'اکاؤنٹ بنائیں';

  @override
  String get authEmailLabel => 'ای میل';

  @override
  String get authPasswordLabel => 'پاس ورڈ';

  @override
  String get authLoginButton => 'سائن اِن';

  @override
  String get authSignUpButton => 'سائن اپ';

  @override
  String get authNoAccount => 'اکاؤنٹ نہیں ہے؟';

  @override
  String get authHaveAccount => 'پہلے سے اکاؤنٹ ہے؟';

  @override
  String get authSignOut => 'سائن آؤٹ';

  @override
  String get homeTitle => 'ہوم';

  @override
  String get articlesTitle => 'مضامین';

  @override
  String get settingsTitle => 'ترتیبات';

  @override
  String get settingsTheme => 'تھیم';

  @override
  String get settingsLanguage => 'زبان';

  @override
  String get themeSystem => 'سسٹم';

  @override
  String get themeLight => 'لائٹ';

  @override
  String get themeDark => 'ڈارک';

  @override
  String get commonRetry => 'دوبارہ کوشش';

  @override
  String get commonEmpty => 'ابھی کچھ نہیں';

  @override
  String get commonCancel => 'منسوخ';

  @override
  String get commonOk => 'ٹھیک ہے';

  @override
  String get errorGeneric => 'کچھ غلط ہو گیا۔ دوبارہ کوشش کریں۔';

  @override
  String get errorNetwork => 'انٹرنیٹ دستیاب نہیں۔';

  @override
  String get errorTimeout => 'درخواست کا وقت ختم ہو گیا۔';

  @override
  String get errorUnauthorized => 'سیشن ختم ہو گیا۔ دوبارہ سائن اِن کریں۔';

  @override
  String get errorNotFound => 'مطلوبہ چیز نہیں ملی۔';

  @override
  String get errorServer => 'سرور میں مسئلہ ہے۔ بعد میں کوشش کریں۔';

  @override
  String get validationRequired => 'یہ خانہ ضروری ہے';

  @override
  String get validationEmail => 'درست ای میل درج کریں';

  @override
  String validationPasswordShort(int min) {
    return 'پاس ورڈ کم از کم $min حروف کا ہو';
  }

  @override
  String get routeNotFound => 'صفحہ نہیں ملا';
}
