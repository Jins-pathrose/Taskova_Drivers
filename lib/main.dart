import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taskova_drivers/View/BottomNavigation/bottomnavigation.dart';
import 'package:taskova_drivers/View/Language/language_provider.dart';
import 'package:taskova_drivers/View/splashscreen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await runZonedGuarded(() async {
    try {
      // 1. Load environment variables first
      await dotenv.load(fileName: ".env").catchError((error) {
        debugPrint("Error loading .env file: $error");
        // Provide fallback values if needed
        dotenv.env['BASE_URL'] ??= 'https://default-fallback-url.com';
      });

      // 2. Initialize shared preferences
      final prefs = await SharedPreferences.getInstance();
      
      // 3. Verify .env loaded correctly (debug only)
      debugPrint("BASE_URL: ${dotenv.env['BASE_URL']}");

      runApp(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AppLanguage()),
          ],
          child: const MyApp(),
        ),
      );
    } catch (e, stack) {
      debugPrint("App initialization failed: $e\n$stack");
      // Fallback UI if initialization fails
      runApp(const MaterialApp(home: Scaffold(body: Center(child: Text('Initialization Error')))));
    }
  }, (error, stack) => debugPrint("Zone error: $error\n$stack"));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Builder(
        builder: (context) {
          // Verify providers are available
          final languageProvider = Provider.of<AppLanguage>(context, listen: false);
          return SplashScreen();
        },
      ),
    );
  }
}