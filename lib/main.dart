import 'package:flutter/foundation.dart';
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

  String _resolveInitialRoute() {
    if (!kIsWeb) {
      return SplashScreen.routeName;
    }

    final fragment = Uri.base.fragment;
    if (fragment.isEmpty) {
      return SplashScreen.routeName;
    }

    final routeUri = Uri.parse(
      fragment.startsWith('/') ? fragment : '/$fragment',
    );
    if (routeUri.path == HomeScreen.routeName) {
      return HomeScreen.routeName;
    }

    return SplashScreen.routeName;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pharmacy Marketplace',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: _resolveInitialRoute(),
      routes: {
        SplashScreen.routeName: (context) => const SplashScreen(),
        LoginScreen.routeName: (context) => const LoginScreen(),
        SignupScreen.routeName: (context) => const SignupScreen(),
        HomeScreen.routeName: (context) => const HomeScreen(),
      },
    );
  }
}
