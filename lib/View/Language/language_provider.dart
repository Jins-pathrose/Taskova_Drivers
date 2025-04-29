import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:translator/translator.dart';

class AppLanguage extends ChangeNotifier {
  // Instance of translator
  final GoogleTranslator _translator = GoogleTranslator();
  
  // Map to store translations for current language
  Map<String, String> _translations = {};
  
  // Current language code
  String _currentLanguage = 'en';
  
  // Get current language
  String get currentLanguage => _currentLanguage;
  
  // List of supported languages
  final List<Map<String, String>> supportedLanguages = [
    {'code': 'en', 'name': 'English', 'nativeName': 'English'},
    {'code': 'hi', 'name': 'Hindi', 'nativeName': 'हिन्दी'},
    {'code': 'pl', 'name': 'Polish', 'nativeName': 'Polski'},
    {'code': 'bn', 'name': 'Bengali', 'nativeName': 'বাংলা'},
    {'code': 'ro', 'name': 'Romanian', 'nativeName': 'Română'},
    {'code': 'de', 'name': 'German', 'nativeName': 'Deutsch'},
  ];
  
  // Default strings (English)
  final Map<String, String> _defaultStrings = {
    'app_name': 'Taskova',
    'tagline': 'Organize your delivery efficiently',
    'email_hint': 'Email address',
    'password_hint': 'Password',
    'forgot_password': 'Forgot password?',
    'login': 'Log In',
    'or_continue_with': 'Or continue with',
    'google': 'Google',
    'apple': 'Apple',
    'dont_have_account': "Don't have an account?",
    'sign_up': 'Sign Up',
    'select_language': 'Select your preferred language',
    'continue_text': 'Continue',
    'change_language': 'Change Language',
    'connection_error': 'Connection error. Please check your internet connection.',
    'login_failed': 'Login failed. Please check your credentials.'
  };
  
  // Constructor
  AppLanguage() {
    _translations = Map.from(_defaultStrings);
  }
  
  // Initialize app language from shared preferences
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _currentLanguage = prefs.getString('language_code') ?? 'en';
    
    // If not English, load translations
    if (_currentLanguage != 'en') {
      await translateStrings(_currentLanguage);
    }
    
    notifyListeners();
  }
  
  // Translate a single text
  Future<String> translate(String text, String targetLanguage) async {
    if (targetLanguage == 'en') return text;
    
    try {
      final translation = await _translator.translate(text, to: targetLanguage);
      return translation.text;
    } catch (e) {
      print('Translation error: $e');
      return text;
    }
  }
  
  // Translate all strings to target language
  Future<void> translateStrings(String targetLanguage) async {
    if (targetLanguage == 'en') {
      _translations = Map.from(_defaultStrings);
      return;
    }
    
    try {
      Map<String, String> newTranslations = {};
      
      // Translate each string
      for (var entry in _defaultStrings.entries) {
        final translation = await _translator.translate(
          entry.value,
          to: targetLanguage,
        );
        newTranslations[entry.key] = translation.text;
      }
      
      _translations = newTranslations;
    } catch (e) {
      print('Translation error: $e');
      // Fallback to English if translation fails
      _translations = Map.from(_defaultStrings);
    }
  }
  
  // Change app language
  Future<void> changeLanguage(String languageCode) async {
    if (_currentLanguage == languageCode) return;
    
    _currentLanguage = languageCode;
    
    // Save to shared preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', languageCode);
    
    // Update translations
    await translateStrings(languageCode);
    
    notifyListeners();
  }
  
  // Get a translated string
  String get(String key) {
    return _translations[key] ?? _defaultStrings[key] ?? key;
  }
}