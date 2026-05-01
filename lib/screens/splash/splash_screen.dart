import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:pharmacy_marketplace_app/core/constants/app_colors.dart';
import 'package:pharmacy_marketplace_app/screens/auth/login_screen.dart';
import 'package:pharmacy_marketplace_app/screens/home/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  static const routeName = '/';

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _routeTimer;

  @override
  void initState() {
    super.initState();
    _routeTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      final isSignedIn =
          Firebase.apps.isNotEmpty && FirebaseAuth.instance.currentUser != null;
      final routeName = isSignedIn
          ? HomeScreen.routeName
          : LoginScreen.routeName;
      Navigator.of(context).pushReplacementNamed(routeName);
    });
  }

  @override
  void dispose() {
    _routeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE8F6FF), Colors.white],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(
                Icons.local_pharmacy_rounded,
                color: AppColors.primary,
                size: 92,
              ),
              SizedBox(height: 12),
              Text(
                'MEDONE',
                style: TextStyle(
                  letterSpacing: 1.2,
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w800,
                  fontSize: 34,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Your trusted medicine marketplace',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
