// lib/services/biometric_service.dart
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class BiometricService {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  static const String _pinKey = 'wallet_pin';
  static const String _biometricEnabled = 'biometric_enabled';
  static const String _pinEnabled = 'pin_enabled';

  // Kontrollo nëse pajisja mbështet biometrinë
  Future<bool> isBiometricAvailable() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return isAvailable && isDeviceSupported;
    } catch (e) {
      return false;
    }
  }

  // Kontrollo nëse ka biometri të konfiguruar
  Future<bool> isBiometricEnrolled() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } catch (e) {
      return false;
    }
  }

  // Autentikimi me Face ID / Touch ID
  Future<bool> authenticateWithBiometrics() async {
    try {
      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        return false;
      }
      
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Authenticate to access Warthog Wallet',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
      
      return authenticated;
    } catch (e) {
      print('Biometric authentication error: $e');
      return false;
    }
  }

  // Ruaj PIN-in e koduar
  Future<void> savePin(String pin) async {
    // Për siguri, PIN-i ruhet në secure storage
    await _storage.write(key: _pinKey, value: pin);
  }

  // Verifiko PIN-in
  Future<bool> verifyPin(String pin) async {
    final savedPin = await _storage.read(key: _pinKey);
    if (savedPin == null) return false;
    return savedPin == pin;
  }

  // Kontrollo nëse ka PIN të ruajtur
  Future<bool> hasPin() async {
    final pin = await _storage.read(key: _pinKey);
    return pin != null && pin.isNotEmpty;
  }

  // Aktivizo/deaktivizo biometrinë
  Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.write(key: _biometricEnabled, value: enabled.toString());
  }

  // Kontrollo nëse biometria është aktive
  Future<bool> isBiometricEnabled() async {
    final value = await _storage.read(key: _biometricEnabled);
    return value == 'true';
  }

  // Aktivizo/deaktivizo PIN-in
  Future<void> setPinEnabled(bool enabled) async {
    await _storage.write(key: _pinEnabled, value: enabled.toString());
  }

  // Kontrollo nëse PIN-i është aktiv
  Future<bool> isPinEnabled() async {
    final value = await _storage.read(key: _pinEnabled);
    return value == 'true';
  }

  // Fshi PIN-in
  Future<void> deletePin() async {
    await _storage.delete(key: _pinKey);
    await _storage.delete(key: _pinEnabled);
  }

  // Metoda kryesore e autentikimit (biometri ose PIN)
  Future<bool> authenticate() async {
    // Provo biometrinë nëse është e aktivizuar
    final biometricEnabled = await isBiometricEnabled();
    if (biometricEnabled) {
      final biometricAuth = await authenticateWithBiometrics();
      if (biometricAuth) return true;
    }
    
    // Nëse biometria nuk funksionon, kërko PIN
    final pinEnabled = await isPinEnabled();
    if (pinEnabled) {
      return false; // Kthen false - do të thotë se duhet PIN
    }
    
    return true; // Asgjë nuk është e aktivizuar
  }
}