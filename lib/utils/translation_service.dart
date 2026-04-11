import 'translations_data.dart';

class TranslationService {
  static const List<String> supportedLanguages = [
    'English', 'Assamese', 'Bengali', 'Bodo', 'Dogri', 'Gujarati', 'Hindi',
    'Kannada', 'Kashmiri', 'Konkani', 'Maithili', 'Malayalam', 'Manipuri',
    'Marathi', 'Nepali', 'Odia', 'Punjabi', 'Sanskrit', 'Santali', 'Sindhi',
    'Tamil', 'Telugu', 'Urdu'
  ];

  static String _currentLanguage = 'English';

  static void setLanguage(String lang) {
    if (supportedLanguages.contains(lang)) {
      _currentLanguage = lang;
    }
  }

  static String tr(String text) {
    if (_currentLanguage == 'English') {
      return text;
    }
    
    final langDict = appTranslations[_currentLanguage];
    if (langDict != null) {
      final translated = langDict[text];
      if (translated != null && translated.isNotEmpty) {
        return translated;
      }
    }
    return text;
  }
}

extension LocalizationExt on String {
  String get tr => TranslationService.tr(this);
}
