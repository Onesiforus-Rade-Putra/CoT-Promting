import 'package:flutter/material.dart';

class ResetPasswordPage extends StatelessWidget {
  static const String routeName = '/reset-password';

  const ResetPasswordPage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
        backgroundColor: const Color(0xFFD71920),
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text(
          'Halaman Reset Password',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
