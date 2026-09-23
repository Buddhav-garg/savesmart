import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../state/session_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool obscurePin = true;
  final phoneController = TextEditingController();
  final pinController = TextEditingController();
  String? errorMessage;
  bool isSubmitting = false;

  @override
  void dispose() {
    phoneController.dispose();
    pinController.dispose();
    super.dispose();
  }

  Future<void> login() async {
    final phone = phoneController.text.trim();
    final pin = pinController.text.trim();
    if (phone.isEmpty || pin.isEmpty) {
      setState(() => errorMessage = 'Enter your phone number and PIN.');
      return;
    }

    setState(() {
      errorMessage = null;
      isSubmitting = true;
    });
    try {
      await AppSession.instance.login(phone: phone, pin: pin);
      if (mounted) context.go('/home');
    } catch (error) {
      if (mounted) setState(() => errorMessage = error.toString());
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

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
                controller: phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone number',
                  prefixText: '+91  ',
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: pinController,
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
              if (errorMessage != null) ...[
                Text(
                  errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                const SizedBox(height: 12),
              ],
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  onPressed: isSubmitting ? null : login,
                  child: isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Sign in'),
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
