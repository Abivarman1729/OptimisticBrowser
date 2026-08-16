class AppConfig {
  static const apiBaseUrl = String.fromEnvironment('OPTIMISTIC_API', defaultValue: 'http://10.0.2.2:8787');
  static const aiBaseUrl = String.fromEnvironment('OPTIMISTIC_AI', defaultValue: 'http://10.0.2.2:8000');
  static const appName = 'Optimistic Browser';
  static const defaultSearchRegion = 'IN';
  static const defaultSearchLanguage = 'en';
  static const maxSearchLength = 500;

  static Null get homeTitle => null;

  static Null get homeSubtitle => null;
}
