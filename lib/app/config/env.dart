class Env {
  const Env._();

  static const apiBaseUrl = String.fromEnvironment(
    'NOVVA_API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000/api/',
  );

  static const useMockApi = bool.fromEnvironment(
    'NOVVA_USE_MOCK_API',
    defaultValue: false,
  );
}
