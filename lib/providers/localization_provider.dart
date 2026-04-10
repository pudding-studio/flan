import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalizationProvider extends ChangeNotifier {
  static const String _appLocaleKey = 'app_locale';
  static const String _aiResponseLocaleKey = 'ai_response_locale';

  static const List<Locale> supportedLocales = [
    Locale('ko'),
    Locale('en'),
    Locale('ja'),
  ];

  static const Locale _fallbackLocale = Locale('en');

  Locale? _appLocale;
  String? _aiResponseLocale;

  LocalizationProvider() {
    _loadSettings();
  }

  /// User-selected app locale. `null` means follow system.
  Locale? get appLocale => _appLocale;

  /// User-selected AI response language code (`ko`/`en`/`ja`).
  /// `null` means auto = use [effectiveLocale].
  String? get aiResponseLocale => _aiResponseLocale;

  /// Locale that should drive the UI. Resolves system locale when not set.
  Locale get effectiveLocale {
    if (_appLocale != null) return _appLocale!;
    return _resolveSystemLocale();
  }

  /// Language code that AI responses should use.
  String get effectiveAiLanguage {
    return _aiResponseLocale ?? effectiveLocale.languageCode;
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    final localeCode = prefs.getString(_appLocaleKey);
    if (localeCode != null && _isSupportedCode(localeCode)) {
      _appLocale = Locale(localeCode);
    }

    final aiCode = prefs.getString(_aiResponseLocaleKey);
    if (aiCode != null && _isSupportedCode(aiCode)) {
      _aiResponseLocale = aiCode;
    }

    notifyListeners();
  }

  Future<void> setAppLocale(Locale? locale) async {
    _appLocale = locale;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    if (locale == null) {
      await prefs.remove(_appLocaleKey);
    } else {
      await prefs.setString(_appLocaleKey, locale.languageCode);
    }
  }

  Future<void> setAiResponseLocale(String? code) async {
    _aiResponseLocale = code;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    if (code == null) {
      await prefs.remove(_aiResponseLocaleKey);
    } else {
      await prefs.setString(_aiResponseLocaleKey, code);
    }
  }

  static Locale _resolveSystemLocale() {
    final systemLocales =
        WidgetsBinding.instance.platformDispatcher.locales;
    for (final sysLocale in systemLocales) {
      for (final supported in supportedLocales) {
        if (supported.languageCode == sysLocale.languageCode) {
          return supported;
        }
      }
    }
    return _fallbackLocale;
  }

  static bool _isSupportedCode(String code) {
    return supportedLocales.any((l) => l.languageCode == code);
  }
}
