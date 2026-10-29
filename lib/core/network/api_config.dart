class ApiConfig {
  ApiConfig._();
  static const String baseUrl = String.fromEnvironment(
    'MONO_API_BASE_URL',
    defaultValue: 'https://hotmusiczone.com/fioso/api',
  );
  static const Duration timeout = Duration(seconds: 15);
}
