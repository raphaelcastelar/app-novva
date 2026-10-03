import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novva_app/core/security/secure_storage_service.dart';
import 'package:novva_app/core/security/token_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TokenManager tokenManager;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({
      'access_token': 'access-antigo',
      'refresh_token': 'refresh-antigo',
      'cpf': '12831146747',
      'user_name': 'Médico de teste',
      'preferencia_nao_relacionada': 'preservar',
    });
    tokenManager = TokenManager(
      const SecureStorageService(FlutterSecureStorage()),
    );
  });

  test('shares one token refresh between concurrent requests', () async {
    final releaseRefresh = Completer<void>();
    var calls = 0;

    Future<RefreshedSessionTokens> refresh(String refreshToken) async {
      calls++;
      expect(refreshToken, 'refresh-antigo');
      await releaseRefresh.future;
      return const RefreshedSessionTokens(
        accessToken: 'access-novo',
        refreshToken: 'refresh-novo',
      );
    }

    final first = tokenManager.refreshAccessToken(refresh);
    final second = tokenManager.refreshAccessToken(refresh);
    releaseRefresh.complete();

    expect(await first, 'access-novo');
    expect(await second, 'access-novo');
    expect(calls, 1);
    expect(await tokenManager.accessToken, 'access-novo');
    expect(await tokenManager.refreshToken, 'refresh-novo');
  });

  test('clears only session data when refresh is rejected', () async {
    await expectLater(
      tokenManager.refreshAccessToken(
        (_) async => throw Exception('refresh inválido'),
      ),
      throwsException,
    );

    expect(await tokenManager.accessToken, isNull);
    expect(await tokenManager.refreshToken, isNull);
    expect(await tokenManager.cpf, isNull);

    const storage = FlutterSecureStorage();
    expect(
      await storage.read(key: 'preferencia_nao_relacionada'),
      'preservar',
    );
  });
}
