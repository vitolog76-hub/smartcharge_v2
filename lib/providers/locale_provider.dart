import 'package:flutter/material.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('it', 'IT'); // Default italiano
  
  Locale get locale => _locale;
  
  void setLocale(Locale locale) {
    if (!_localeIsSupported(locale)) return;
    _locale = locale;
    notifyListeners();
  }
  
  bool _localeIsSupported(Locale locale) {
    return [
      const Locale('it', 'IT'),
      const Locale('en', 'US'),
      const Locale('fr', 'FR'),
      const Locale('es', 'ES'),
      const Locale('de', 'DE'),
    ].contains(locale);
  }
  
  void clearLocale() {
    _locale = const Locale('it', 'IT');
    notifyListeners();
  }
}