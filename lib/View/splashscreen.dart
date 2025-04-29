import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taskova_drivers/View/Homepage/homepage.dart';
import 'package:taskova_drivers/View/Language/language_provider.dart';
import 'package:taskova_drivers/View/Language/language_selection.dart';
import 'package:taskova_drivers/View/Authentication/login.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    
    // Set up animation for logo
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    
    _animationController.forward();
    
    // Check authentication state after animation
    Future.delayed(const Duration(seconds: 4), () {
      checkAuthState();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Check if user is already logged in and if language is selected
  Future<void> checkAuthState() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('access_token');
    final languageSelected = prefs.getString('language_code');

    if (languageSelected == null) {
      // Language not selected yet, go to language selection first
      navigateToLanguageSelection();
    } else if (accessToken != null && accessToken.isNotEmpty) {
      // User is logged in and language is selected, navigate to home screen
      navigateToHome();
    } else {
      // Language is selected but user is not logged in, navigate to login screen
      navigateToLogin();
    }
  }

  // Navigate to home screen
  void navigateToHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const HomePage()),
    );
  }

  // Navigate to login screen
  void navigateToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  // Navigate to language selection
  void navigateToLanguageSelection() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LanguageSelectionScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get AppLanguage instance safely within build method
    final appLanguage = Provider.of<AppLanguage>(context, listen: false);
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue[100]!, Colors.blue[400]!],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App logo with animation
              ScaleTransition(
                scale: _animation,
                child: Container(
                  height: 120,
                  width: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Image.asset(
                    'assets/app_logo.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => 
                      Icon(Icons.local_taxi, size: 80, color: Colors.blue[900]),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // App name with fade-in effect
              FadeTransition(
                opacity: _animation,
                child: Text(
                  appLanguage.get('app_name'),
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[900],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Tagline with fade-in effect
              FadeTransition(
                opacity: _animation,
                child: Text(
                  appLanguage.get('tagline'),
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.blue[900]?.withOpacity(0.8),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}