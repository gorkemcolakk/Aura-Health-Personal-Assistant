class AppConfig {
  static const String aiProxyUrl = String.fromEnvironment(
    'AURA_AI_PROXY_URL',
    defaultValue: 'http://127.0.0.1:8787',
  );

  static bool get hasAiProxy => aiProxyUrl.trim().isNotEmpty;
}
