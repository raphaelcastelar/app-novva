class Env {
  const Env._();

  static const apiBaseUrl = String.fromEnvironment(
    'NOVVA_API_BASE_URL',
    defaultValue: 'https://api.example.invalid',
  );

  static const useMockApi = bool.fromEnvironment(
    'NOVVA_USE_MOCK_API',
    defaultValue: true,
  );
}
