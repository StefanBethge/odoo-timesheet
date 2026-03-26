import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

abstract class AppUnlockService {
  Future<bool> isBiometricAvailable();
  Future<bool> authenticateWithBiometrics();
}

class LocalAuthUnlockService implements AppUnlockService {
  LocalAuthUnlockService({LocalAuthentication? localAuthentication})
      : _localAuthentication = localAuthentication ?? LocalAuthentication();

  final LocalAuthentication _localAuthentication;

  @override
  Future<bool> isBiometricAvailable() async {
    try {
      final supported = await _localAuthentication.isDeviceSupported();
      final biometrics = await _localAuthentication.getAvailableBiometrics();
      return supported && biometrics.isNotEmpty;
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<bool> authenticateWithBiometrics() async {
    try {
      return await _localAuthentication.authenticate(
        localizedReason: 'Odoo Timesheet entsperren',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } on PlatformException {
      return false;
    }
  }
}
