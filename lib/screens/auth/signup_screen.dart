import 'package:flutter/material.dart';
import 'package:pharmacy_marketplace_app/screens/home/home_screen.dart';
import 'package:pharmacy_marketplace_app/widgets/custom_text_field.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  static const routeName = '/signup';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Sign up', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 6),
              Text(
                'Create your pharmacy account to start ordering medicines.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              const CustomTextField(
                hintText: 'Full name',
                prefixIcon: Icons.person_outline,
              ),
              const SizedBox(height: 14),
              const CustomTextField(
                hintText: 'Email address',
                prefixIcon: Icons.email_outlined,
              ),
              const SizedBox(height: 14),
              const CustomTextField(
                hintText: 'Phone number',
                prefixIcon: Icons.phone_outlined,
              ),
              const SizedBox(height: 14),
              const CustomTextField(
                hintText: 'Password',
                prefixIcon: Icons.lock_outline,
                obscureText: true,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pushReplacementNamed(
                    context,
                    HomeScreen.routeName,
                  ),
                  child: const Text('Create account'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
