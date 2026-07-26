import 'package:flutter/material.dart';
import 'login_password_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  final Color _primaryColor = const Color(0xFFAC282C); // Suaja Red

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: Column(
            children: [
              const Spacer(),
              Image.asset(
                'assets/images/suaja_logo.png',
                height: 250,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 12),
              Text(
                'satu jepretan, sejuta kemenangan',
                style: TextStyle(
                  color: _primaryColor,
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.normal,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Navigate to the password screen with a smooth transition
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginPasswordScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Login',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
