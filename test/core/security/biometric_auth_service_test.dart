import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';
import 'package:novva_app/core/security/biometric_auth_service.dart';
import 'package:novva_app/core/security/biometric_copy.dart';

void main() {
  group('BiometricAuthService.isSupportedBiometricSet', () {
    test('iOS aceita somente Face ID', () {
      expect(
        BiometricAuthService.isSupportedBiometricSet(
          [BiometricType.face],
          TargetPlatform.iOS,
        ),
        isTrue,
      );
      expect(
        BiometricAuthService.isSupportedBiometricSet(
          [BiometricType.fingerprint],
          TargetPlatform.iOS,
        ),
        isFalse,
      );
    });

    test('Android aceita qualquer biometria cadastrada', () {
      for (final type in BiometricType.values) {
        expect(
          BiometricAuthService.isSupportedBiometricSet(
            [type],
            TargetPlatform.android,
          ),
          isTrue,
          reason: '$type deveria ser aceito no Android',
        );
      }
    });

    test('Android sem biometria cadastrada não habilita o recurso', () {
      expect(
        BiometricAuthService.isSupportedBiometricSet(
          const [],
          TargetPlatform.android,
        ),
        isFalse,
      );
    });
  });

  group('BiometricCopy.current', () {
    tearDown(() => debugDefaultTargetPlatformOverride = null);

    test('usa Face ID no iOS', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      expect(BiometricCopy.current.settingsTitle, 'Entrar com Face ID');
    });

    test('usa biometria no Android', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      expect(BiometricCopy.current.settingsTitle, 'Entrar com biometria');
      expect(BiometricCopy.current.authReason, isNot(contains('Face ID')));
    });
  });
}
