import 'package:flutter/foundation.dart';

class AppLanguage {
  static final ValueNotifier<String> code = ValueNotifier<String>('en');

  static bool get isArabic => code.value == 'ar';

  static String text(String en, String ar) => isArabic ? ar : en;

  static void toggle() {
    code.value = isArabic ? 'en' : 'ar';
  }
}
