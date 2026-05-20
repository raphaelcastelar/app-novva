class BiometricAuthService {
  const BiometricAuthService();

  Future<bool> canCheckBiometrics() async => false;

  Future<bool> authenticate() async {
    throw UnimplementedError(
      'Biometria preparada para integração futura. Adicione local_auth quando o target iOS estiver configurado.',
    );
  }
}
