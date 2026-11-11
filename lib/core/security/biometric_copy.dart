import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Textos e ícone da autenticação biométrica conforme a plataforma.
///
/// No iOS o app usa somente Face ID; no Android aceita qualquer biometria
/// cadastrada (digital, rosto ou íris), então o termo genérico é "biometria".
class BiometricCopy {
  const BiometricCopy._({
    required this.authReason,
    required this.offerTitle,
    required this.offerBody,
    required this.enabledMessage,
    required this.enableFailedMessage,
    required this.disabledMessage,
    required this.settingsTitle,
    required this.settingsAvailable,
    required this.settingsUnavailable,
    required this.icon,
  });

  final String authReason;
  final String offerTitle;
  final String offerBody;
  final String enabledMessage;
  final String enableFailedMessage;
  final String disabledMessage;
  final String settingsTitle;
  final String settingsAvailable;
  final String settingsUnavailable;
  final IconData icon;

  static const faceId = BiometricCopy._(
    authReason: 'Use o Face ID para acessar sua conta Novva.',
    offerTitle: 'Ativar Face ID?',
    offerBody:
        'Nas próximas vezes, confirme o CPF salvo e use o Face ID no lugar da senha.',
    enabledMessage: 'Face ID ativado com sucesso.',
    enableFailedMessage: 'Não foi possível ativar o Face ID.',
    disabledMessage: 'Face ID desativado.',
    settingsTitle: 'Entrar com Face ID',
    settingsAvailable: 'Use o Face ID após confirmar o CPF salvo',
    settingsUnavailable: 'Face ID não está configurado neste aparelho',
    icon: Icons.face_outlined,
  );

  static const biometrics = BiometricCopy._(
    authReason: 'Use a biometria para acessar sua conta Novva.',
    offerTitle: 'Ativar biometria?',
    offerBody:
        'Nas próximas vezes, confirme o CPF salvo e use a biometria no lugar da senha.',
    enabledMessage: 'Biometria ativada com sucesso.',
    enableFailedMessage: 'Não foi possível ativar a biometria.',
    disabledMessage: 'Biometria desativada.',
    settingsTitle: 'Entrar com biometria',
    settingsAvailable: 'Use a biometria após confirmar o CPF salvo',
    settingsUnavailable: 'Nenhuma biometria está cadastrada neste aparelho',
    icon: Icons.fingerprint,
  );

  static BiometricCopy get current =>
      defaultTargetPlatform == TargetPlatform.iOS ? faceId : biometrics;
}
