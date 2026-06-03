// ============================================================
// StudyLock — Dynamic Theme Provider (Dark/Light + Urdu/English)
// ============================================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Theme Mode ──────────────────────────────────────────────
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) => ThemeModeNotifier());

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.dark) { _load(); }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('theme_dark') ?? true;
    state = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> toggle() async {
    state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('theme_dark', state == ThemeMode.dark);
  }

  bool get isDark => state == ThemeMode.dark;
}

// ── Language ────────────────────────────────────────────────
final languageProvider = StateNotifierProvider<LanguageNotifier, Locale>((ref) => LanguageNotifier());

class LanguageNotifier extends StateNotifier<Locale> {
  LanguageNotifier() : super(const Locale('en')) { _load(); }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final lang = prefs.getString('language') ?? 'en';
    state = Locale(lang);
  }

  Future<void> setEnglish() async {
    state = const Locale('en');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', 'en');
  }

  Future<void> setUrdu() async {
    state = const Locale('ur');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', 'ur');
  }

  bool get isUrdu => state.languageCode == 'ur';
}

// ── Urdu Translations (key strings used in app) ──────────────
class AppStrings {
  static const Map<String, Map<String, String>> _t = {
    'home': {'en': 'Home', 'ur': 'گھر'},
    'courses': {'en': 'Courses', 'ur': 'کورسز'},
    'attendance': {'en': 'Attendance', 'ur': 'حاضری'},
    'gpa': {'en': 'GPA', 'ur': 'جی پی اے'},
    'profile': {'en': 'Profile', 'ur': 'پروفائل'},
    'settings': {'en': 'Settings', 'ur': 'ترتیبات'},
    'session': {'en': 'Study Session', 'ur': 'مطالعہ سیشن'},
    'assignments': {'en': 'Assignments', 'ur': 'اسائنمنٹس'},
    'quizzes': {'en': 'Quizzes', 'ur': 'کوئز'},
    'lectures': {'en': 'Lectures', 'ur': 'لیکچرز'},
    'logout': {'en': 'Logout', 'ur': 'لاگ آؤٹ'},
    'loading': {'en': 'Loading...', 'ur': 'لوڈ ہو رہا ہے...'},
    'leaderboard': {'en': 'Leaderboard', 'ur': 'لیڈر بورڈ'},
    'timetable': {'en': 'Timetable', 'ur': 'ٹائم ٹیبل'},
    'ai_tutor': {'en': 'AI Tutor', 'ur': 'اے آئی ٹیوٹر'},
    'dark_mode': {'en': 'Dark Mode', 'ur': 'ڈارک موڈ'},
    'language': {'en': 'Language', 'ur': 'زبان'},
    'english': {'en': 'English', 'ur': 'انگریزی'},
    'urdu': {'en': 'Urdu', 'ur': 'اردو'},
    'save': {'en': 'Save', 'ur': 'محفوظ کریں'},
    'cancel': {'en': 'Cancel', 'ur': 'منسوخ'},
    'submit': {'en': 'Submit', 'ur': 'جمع کریں'},
    'refresh': {'en': 'Refresh', 'ur': 'تازہ کریں'},
    'no_data': {'en': 'No data available', 'ur': 'کوئی ڈیٹا نہیں'},
    'error': {'en': 'Something went wrong', 'ur': 'کچھ غلط ہوگیا'},
  };

  static String get(String key, Locale locale) {
    return _t[key]?[locale.languageCode] ?? _t[key]?['en'] ?? key;
  }
}
