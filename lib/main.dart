import 'package:flutter/material.dart';
import 'package:hrm/screens/splash_screen.dart';
import 'package:hrm/theme/theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'HRM App',
      theme: lightMode,
      home: const SplashScreen(), // SplashScreen sebagai layar pertama
    );
  }
}
