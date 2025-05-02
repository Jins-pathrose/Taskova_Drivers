import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taskova_drivers/Model/api_config.dart';
import 'package:taskova_drivers/View/Authentication/login.dart';
import 'package:taskova_drivers/View/driver_document.dart';
import 'package:taskova_drivers/View/profile.dart'; // Adjust the import path as needed

class HomePage extends StatelessWidget {
  

  const HomePage({super.key});

  // Show success snackbar
  void showSuccessSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // Show error snackbar
  void showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // Logout function that calls the API
  Future<void> logout(BuildContext context) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text("Logging out..."),
              ],
            ),
          );
        },
      );

      // Get tokens from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token') ?? "";
      final refreshToken = prefs.getString('refresh_token') ?? "";

      // Call logout API
      final response = await http.post(
        Uri.parse(ApiConfig.logoutUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          'refresh': refreshToken,
        }),
      );

      // Close the loading dialog
      Navigator.pop(context);

      if (response.statusCode == 200 || response.statusCode == 204 || response.statusCode == 205) {
        // Successfully logged out from server
        Map<String, dynamic> responseData = {};
        try {
          responseData = jsonDecode(response.body);
        } catch (e) {
          // If the response body isn't valid JSON, ignore the error
        }
        
        String successMessage = responseData['message'] ?? "Logged out successfully";
        print("Logged out successfully from server: $successMessage");
        
        // Show success snackbar
        showSuccessSnackbar(context, successMessage);
        
        // Clear stored tokens
        await prefs.remove('access_token');
        await prefs.remove('refresh_token');
        await prefs.remove('user_email');
        await prefs.remove('user_name');

        // Wait a moment to show the snackbar before navigating
        await Future.delayed(Duration(milliseconds: 500));
        
        // Navigate to login page
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => LoginPage()),
          (Route<dynamic> route) => false,
        );
      } else {
        print("Logout API error: ${response.statusCode} ${response.body}");
        
        // Show error message
        Map<String, dynamic> errorData = {};
        try {
          errorData = jsonDecode(response.body);
        } catch (e) {
          // If the response body isn't valid JSON, ignore the error
        }
        
        String errorMessage = errorData['detail'] ?? "Logout failed. Please try again.";
        showErrorSnackbar(context, errorMessage);
        
        // We'll still clear tokens and redirect to login page even if the API call fails
        await prefs.remove('access_token');
        await prefs.remove('refresh_token');
        await prefs.remove('user_email');
        await prefs.remove('user_name');
        
        // Wait a moment to show the snackbar before navigating
        await Future.delayed(Duration(milliseconds: 500));
        
        // Navigate to login page
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => LoginPage()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      // Close the loading dialog if it's showing
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      print("Error during logout: $e");
      
      // Show error message
      showErrorSnackbar(context, "Logout failed. Please try again.");
      
      // Try to clear tokens locally anyway
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('access_token');
        await prefs.remove('refresh_token');
        await prefs.remove('user_email');
        await prefs.remove('user_name');
        
        // Wait a moment to show the snackbar before navigating
        await Future.delayed(Duration(milliseconds: 500));
        
        // Navigate to login page
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => LoginPage()),
          (Route<dynamic> route) => false,
        );
      } catch (e) {
        print("Error clearing SharedPreferences: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Home Page")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Welcome!", style: TextStyle(fontSize: 24)),
            SizedBox(height: 10),
          
            SizedBox(height: 100),
            ElevatedButton(
              onPressed: () => logout(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text("Logout"),
            ),
            ElevatedButton(onPressed: (){
              Navigator.push(context, MaterialPageRoute(builder: (context)=>
                DocumentRegistrationPage()
              ));
            }, child: Text('Document Registration')),
          ],
        ),
      ),
    );
  }
}