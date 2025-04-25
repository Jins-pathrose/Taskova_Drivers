import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  final String email;
  final String name;

  const HomePage({super.key, required this.email, required this.name});

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
            Text("Name: $name", style: TextStyle(fontSize: 18)),
            Text("Email: $email", style: TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}
