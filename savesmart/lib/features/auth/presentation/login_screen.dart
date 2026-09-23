import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool obscurePin = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 44, 28, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.savings_outlined,
                size: 38,
                color: Color(0xFF277A57),
              ),
              const Spacer(),
              const SizedBox(height: 12),
              const Text(
                'Save Smart',
                style: TextStyle(fontSize: 30, color: Color(0xFF17221D)),
              ),
              const SizedBox(height: 36),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Phone number',
                  prefixText: '+91  ',
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                decoration: InputDecoration(
                  labelText: '4-digit PIN',
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => obscurePin = !obscurePin),
                    icon: Icon(
                      obscurePin
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
                obscureText: obscurePin,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  onPressed: () => context.go('/home'),
                  child: const Text('Continue'),
                ),
              ),
              const SizedBox(height: 18),
              const Center(
                child: Text(
                  'Demo mode · any details will work',
                  style: TextStyle(color: Color(0xFF7C877F)),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
