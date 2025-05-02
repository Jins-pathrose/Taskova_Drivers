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
    'tagline': 'Delivery Drivers Portal',
    'email': 'Email',
    'email_hint': 'Enter your email',
    'password': 'Password',
    'new_password': 'New Password',
    'confirm_password': 'Confirm Password',
    'please_enter_email': 'Please enter your email address',
    'please_enter_valid_email': 'Please enter a valid email address',
    'password_hint': 'Enter your Password',
    'password_hint_new': 'Enter your new password',
    'new_password_validation': 'Password must be at least 8 characters long',
    'forgot_password': 'Forgot password?',
    'reset_Password': 'Reset Password',
    'passwords_do_not_match': 'Passwords do not match',
    'login': 'Log In',
    'please_confrm_password': 'Please confirm your password',
    'or': 'or',
    'continue_with_google': 'Continue with Google',
    'continue_with_apple': 'Continue with Apple',
    'google': 'Google',
    'apple': 'Apple',
    'forgot_password_instruction': 'Please enter your email address to receive a password reset link.',
    'dont_have_account': "Don't have an account?",
    'sign_up': 'Sign Up',
    'continue_text': 'Continue',
    'email_verification_suc': 'Email verified successfully!',
    'email_verification_fail': 'Verification failed. Please try again.',
    'connection_error': 'Connection error. Please check your internet connection.',
    'otp_sent': 'New verification code has been sent',
    'otp_sent_fail': 'Failed to resend code. Please try again.',
    'login_failed': 'Login failed. Please check your credentials.',
    'tagline_signup': 'Create an account to get started',
    'create_account': 'Create Account',
    'already_have_account': 'Already have an account? ',
    'OTP sent to your email': 'OTP sent to your email',
    'verify_otp': 'Verify OTP',
    'home': 'Home',
    'chat': 'Chat',
    'community': 'Community',
    'profile': 'Profile',
    'verification_code': 'Verification Code',
    'verfy_code': 'Verify Code',
    'resend_code': 'Resend',
    'confirm': 'Confirm',
    'signup_confrm_password': 'Confirm password is required',
    'resent_in' : 'Resend in',
    'didnt_receive_code': "Didn't receive the code?",
    'otp_snackbar': 'We\'ve sent a 6-digit code to\n',
    'Back to Login': 'Back to Login',
    'send_otp': 'Send OTP',
    'enter_email': 'Enter your email address',
    'email_required': 'Please enter valid email address',
    'enter_password': 'Enter your password',
    'password_required': 'Please enter valid password',
    'password_notmatch': 'Passwords do not match',
    'password_reset_fail': 'Password reset failed',
    'reset_password': 'Reset Password',
    'enter_code': 'Enter the 6-digit code sent to',
    'create_new_password': 'Create New Password',
    'password_reset_done': 'Password reset successful! You can now login with your new password.',
    'otp_required': 'Please enter all 6 digits',
    'Failed to send OTP. Please try again.': 'Failed to send OTP. Please try again.',
    'Enter your email address and we will send you an OTP to reset your password.': 'Enter your email address and we will send you an OTP to reset your password.',

    'select_profile_picture': 'Please select a profile picture',
    'select_working_area': 'Please select a preferred working area',
    'profile_registration': 'Profile Registration',
    'submitting_profile_information': 'Submitting profile information...',
    'registration_failed': 'Registration Failed',
    'full_name': 'Full Name',
    'please_enter_name': 'Please enter your name',
    'phone_number': 'Phone Number',
    'please_enter_phone_number': 'Please enter your phone number',
    'address': 'Address',
    'please_enter_address': 'Please enter your address',
    'are_u_british': 'Are you a British citizen?',
    'criminal_record': 'Do you have a criminal record?',
    'working_area': 'Preferred Working Area',
    'postcode': 'Search by Postcode',
    'search': 'Search',
    'selected_working_area': 'Selected Working Area:',
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