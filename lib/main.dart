import 'package:flutter/material.dart';
import 'package:pharmacy_marketplace_app/core/theme/app_theme.dart';
import 'package:pharmacy_marketplace_app/screens/auth/login_screen.dart';
import 'package:pharmacy_marketplace_app/screens/auth/signup_screen.dart';
import 'package:pharmacy_marketplace_app/screens/home/home_screen.dart';
import 'package:pharmacy_marketplace_app/screens/splash/splash_screen.dart';

void main() {
  runApp(const PharmacyApp());
}

class PharmacyApp extends StatelessWidget {
  const PharmacyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pharmacy Marketplace',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: SplashScreen.routeName,
      routes: {
        SplashScreen.routeName: (context) => const SplashScreen(),
        LoginScreen.routeName: (context) => const LoginScreen(),
        SignupScreen.routeName: (context) => const SignupScreen(),
        HomeScreen.routeName: (context) => const HomeScreen(),
      },
    );
  }
}
