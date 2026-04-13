import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/localization/app_strings.dart';

/// Supported languages enum
enum AppLanguage {
  arabic('ar', 'العربية', TextDirection.rtl),
  english('en', 'English', TextDirection.ltr);

  final String code;
  final String displayName;
  final TextDirection direction;

  const AppLanguage(this.code, this.displayName, this.direction);
}

/// Provider for managing app language
class LanguageProvider extends ChangeNotifier {
  static const String _languageKey = 'app_language';

  AppLanguage _currentLanguage = AppLanguage.arabic;
  bool _isInitialized = false;

  AppLanguage get currentLanguage => _currentLanguage;
  bool get isArabic => _currentLanguage == AppLanguage.arabic;
  bool get isEnglish => _currentLanguage == AppLanguage.english;
  Locale get locale => Locale(_currentLanguage.code);
  TextDirection get textDirection => _currentLanguage.direction;
  bool get isInitialized => _isInitialized;

  /// Initialize and load saved language
  Future<void> initialize() async {
    if (_isInitialized) return;

    final prefs = await SharedPreferences.getInstance();
    final savedCode = prefs.getString(_languageKey);

    if (savedCode != null) {
      _currentLanguage = AppLanguage.values.firstWhere(
        (lang) => lang.code == savedCode,
        orElse: () => AppLanguage.arabic,
      );
    }

    AppStrings.setLanguage(_currentLanguage == AppLanguage.arabic);
    _isInitialized = true;
    notifyListeners();
  }

  /// Change the app language
  Future<void> setLanguage(AppLanguage language) async {
    if (_currentLanguage == language) return;

    _currentLanguage = language;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, language.code);

    AppStrings.setLanguage(_currentLanguage == AppLanguage.arabic);
    notifyListeners();
  }

  /// Toggle between Arabic and English
  Future<void> toggleLanguage() async {
    final newLanguage = isArabic ? AppLanguage.english : AppLanguage.arabic;
    await setLanguage(newLanguage);
  }
}
