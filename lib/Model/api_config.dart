import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  static String get baseUrl {
    return dotenv.env['BASE_URL'] ?? 'http://default-fallback-url.com';
  }
  
  static String get forgotPasswordUrl {
    return '$baseUrl/api/forgot-password/';
  }
  
  static String get loginUrl {
    return '$baseUrl/api/login/';
  }

  static String get registerUrl {
    return '$baseUrl/api/register/';
  }
  static String get verifyOtpUrl {
    return '$baseUrl/api/verify-otp/';
  }
  static String get resetPasswordUrl {
    return '$baseUrl/api/reset-password/';
  }
  static String get driverProfileUrl {
    return '$baseUrl/api/driver-profile/';
  }
  static String get driverDocumentUrl {
    return '$baseUrl/api/driver-documents/';
  }
  static String get logoutUrl {
    return '$baseUrl/api/logout/';
  }
  static String get resendOtpUrl {
    return '$baseUrl/api/resend-otp/';
  }
  static String get profileStatusUrl {
    return '$baseUrl/api/profile-status/';
  }
  
}