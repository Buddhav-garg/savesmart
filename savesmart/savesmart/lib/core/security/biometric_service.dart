import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

class BiometricService {
  BiometricService([LocalAuthentication? auth])
    : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  Future<bool> confirmWithdrawal() async {
    try {
      final available =
          await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
      if (!available) return false;
      return await _auth.authenticate(
        localizedReason: 'Confirm premature withdrawal',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }
}
