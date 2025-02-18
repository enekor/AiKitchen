import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatelessWidget {
  final AuthService _authService = AuthService();

  LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            final user = await _authService.signInWithGoogle();
            if (user != null && context.mounted) {
              Navigator.pushReplacementNamed(context, '/home');
            }
          },
          child: const Padding(
            padding: EdgeInsets.all(12.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.login),
                SizedBox(width: 8),
                Text('Iniciar sesión con Google'),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 