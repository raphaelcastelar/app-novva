class Env {
  const Env._();

  static const apiBaseUrl = String.fromEnvironment(
    'NOVVA_API_BASE_URL',
    defaultValue: 'https://api-novva.inovarcontabilidadex.com.br/api/v1/',
  );

  static const useMockApi = bool.fromEnvironment(
    'NOVVA_USE_MOCK_API',
    defaultValue: false,
  );

  static void validateForRelease({required bool releaseMode}) {
    if (!releaseMode) return;
    final uri = Uri.tryParse(apiBaseUrl);
    if (useMockApi || uri?.scheme != 'https' || !apiBaseUrl.endsWith('/')) {
      throw StateError(
        'Build de produção exige API HTTPS, URL terminada em / e mocks desativados.',
      );
    }
  }
}
