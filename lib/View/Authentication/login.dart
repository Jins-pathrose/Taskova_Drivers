import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:lottie/lottie.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taskova_drivers/Model/api_config.dart';
import 'package:taskova_drivers/Model/apple_sign_in.dart';
import 'package:taskova_drivers/View/Authentication/forgot_password.dart';
import 'package:taskova_drivers/View/Authentication/signup.dart';
import 'package:taskova_drivers/View/BottomNavigation/bottomnavigation.dart';
import 'package:taskova_drivers/View/Homepage/homepage.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:taskova_drivers/View/Language/language_provider.dart';
import 'package:taskova_drivers/View/profile.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formkey = GlobalKey<FormState>();
  GoogleSignIn _googleSignIn = GoogleSignIn();
  bool _obscurePassword = true;
  late AnimationController _animationController;
  bool _isLoading = false;
  late AppLanguage appLanguage;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 0),
    );
    appLanguage = Provider.of<AppLanguage>(context, listen: false);
    _animationController.forward();
    checkTokenAndNavigate();
  }

  // Check if user is already logged in
  Future<void> checkTokenAndNavigate() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    
    if (token != null) {
      // If token exists, navigate to homepage
      // You may want to validate the token with your API first
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomePage(
          
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Save tokens to SharedPreferences
  Future<void> saveTokens(String accessToken, String refreshToken, String email, String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', accessToken);
    await prefs.setString('refresh_token', refreshToken);
    await prefs.setString('user_email', email);
    await prefs.setString('user_name', name);
  }

  void googleLogin() async {
    try {
      var user = await _googleSignIn.signIn();
      if (user != null) {
        print('User logged in successfully');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HomePage(
             
            ),
          ),
        );
      }
    } catch (e) {
      print("Google login failed: $e");
      showErrorSnackbar("Google login failed. Please try again.");
    }
  }

  void showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

 Future<void> loginUser() async {
  if (_formkey.currentState!.validate()) {
    setState(() {
      _isLoading = true;
    });

    try {
      // 1. First make the login request
      final response = await http.post(
        Uri.parse(ApiConfig.loginUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': _emailController.text,
          'password': _passwordController.text,
        }),
      );

      if (response.statusCode == 200) {
        // Login successful
        Map<String, dynamic> responseData = jsonDecode(response.body);
        print('Login successful: $responseData');
        
        // Store tokens in SharedPreferences
        String accessToken = responseData['access'] ?? "";
        String refreshToken = responseData['refresh'] ?? "";
        String name = responseData['name'] ?? "User";
        
        await saveTokens(accessToken, refreshToken, _emailController.text, name);
        
        // 2. Now check profile status
        final profileResponse = await http.get(
          Uri.parse(ApiConfig.profileStatusUrl),
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          },
        );

        if (profileResponse.statusCode == 200) {
          final profileData = jsonDecode(profileResponse.body);
          bool isProfileComplete = profileData['is_profile_complete'] ?? false;
          
          showSuccessSnackbar("Login successful!");
          
          // 3. Navigate based on profile completion status
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => isProfileComplete 
                  ? MainWrapper()
                  : ProfileRegistrationPage(), // Replace with your actual profile registration page
            ),
          );
        } else {
          // Handle profile status check error
          showErrorSnackbar("Could not verify profile status");
        }
      } else {
        // Login failed
        Map<String, dynamic> errorData = jsonDecode(response.body);
        String errorMessage = errorData['detail'] ?? "Login failed. Please check your credentials.";
        showErrorSnackbar(errorMessage);
      }
    } catch (e) {
      print("Login error: $e");
      showErrorSnackbar("Connection error. Please check your internet connection.");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formkey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
                  // Logo and Animation
                  Center(
                    child: Column(
                      children: [
                        SizedBox(
                          height: 180,
                          width: 180,
                          child: Lottie.asset(
                            'assets/Animation - 1745389935983.json',
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          appLanguage.get('app_name'),
                          style: GoogleFonts.poppins(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: Colors.blue.shade800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          appLanguage.get('tagline'),
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Email Field
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.email_outlined,
                          color: Colors.blue.shade700),
                      labelText: appLanguage.get('email'),
                      hintText: appLanguage.get('email_hint'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.blue.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: Colors.blue.shade700, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.blue.shade50,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return appLanguage.get('enter_email');
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                          .hasMatch(value)) {
                        return appLanguage.get('email_required');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Password Field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      prefixIcon:
                          Icon(Icons.lock_outline, color: Colors.blue.shade700),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.blue.shade700,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      labelText: appLanguage.get('password'),
                      hintText: appLanguage.get('password_hint'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.blue.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: Colors.blue.shade700, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.blue.shade50,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return appLanguage.get('enter_password');
                      }
                      if (value.length < 6) {
                        return appLanguage.get('password_required');
                      }
                      return null;
                    },
                  ),

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ForgotPasswordScreen(),
                          ),
                        );
                      },
                      child: Text(
                        appLanguage.get('forgot_password'),
                        style: TextStyle(
                          color: Colors.blue.shade800,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Login Button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    onPressed: _isLoading ? null : loginUser,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        :  Text(
                            appLanguage.get('login'),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                  ),

                  const SizedBox(height: 20),

                  // Divider
                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: Colors.grey.shade400,
                          thickness: 1,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          appLanguage.get('Or'),
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: Colors.grey.shade400,
                          thickness: 1,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Google Sign In Button
                  ElevatedButton(
                    onPressed: googleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      elevation: 3,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/th.jpeg',
                          height: 24,
                          width: 24,
                        ),
                        const SizedBox(width: 12),
                         Text(
                          appLanguage.get('continue_with_google'),
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Apple Sign In Button
                  ElevatedButton.icon(
                    icon: const FaIcon(
                      FontAwesomeIcons.apple,
                      color: Colors.white,
                      size: 22,
                    ),
                    label:  Text(
                      appLanguage.get('continue_with_apple'),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    onPressed: () => handleAppleSignIn(context),
                  ),

                  const SizedBox(height: 24),

                  // Sign Up Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        appLanguage.get('dont_have_account'),
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 16,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const Registration()),
                          );
                        },
                        child: Text(
                          appLanguage.get('sign_up'),
                          style: TextStyle(
                            color: Colors.blue.shade800,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}