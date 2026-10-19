import 'package:local_auth/local_auth.dart';

import 'secure_storage_service.dart';
import 'token_manager.dart';

class BiometricAuthService {
  const BiometricAuthService(
    this._localAuthentication,
    this._storage,
    this._tokenManager,
  );

  final LocalAuthentication _localAuthentication;
  final SecureStorageService _storage;
  final TokenManager _tokenManager;

  static const _enabledKey = 'face_id_enabled';
  static const _offerHandledKey = 'face_id_offer_handled';

  Future<bool> get isEnabled async {
    try {
      return await _storage.read(_enabledKey) == 'true';
    } catch (_) {
      return false;
    }
  }

  Future<bool> get wasOfferHandled async {
    try {
      return await _storage.read(_offerHandledKey) == 'true';
    } catch (_) {
      return false;
    }
  }

  Future<bool> canCheckBiometrics() async {
    try {
      if (!await _localAuthentication.canCheckBiometrics) return false;
      final biometrics = await _localAuthentication.getAvailableBiometrics();
      return biometrics.contains(BiometricType.face);
    } catch (_) {
      return false;
    }
  }

  Future<bool> canUseForLogin() async =>
      await isEnabled &&
      await canCheckBiometrics() &&
      await _tokenManager.hasStoredSession();

  Future<bool> shouldOfferSetup() async =>
      !await isEnabled &&
      !await wasOfferHandled &&
      await canCheckBiometrics() &&
      await _tokenManager.hasStoredSession();

  Future<bool> authenticate() async {
    try {
      return await _localAuthentication.authenticate(
        localizedReason: 'Use o Face ID para acessar sua conta Novva.',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
    } catch (_) {
      return false;
    }
  }

  Future<bool> enable() async {
    if (!await canCheckBiometrics() ||
        !await _tokenManager.hasStoredSession()) {
      return false;
    }
    final authenticated = await authenticate();
    await markOfferHandled();
    if (!authenticated) return false;
    await _storage.write(_enabledKey, 'true');
    return true;
  }

  Future<void> disable() => _storage.delete(_enabledKey);

  Future<void> markOfferHandled() => _storage.write(_offerHandledKey, 'true');

  Future<void> clear() async {
    await Future.wait([
      _storage.delete(_enabledKey),
      _storage.delete(_offerHandledKey),
    ]);
  }
}
