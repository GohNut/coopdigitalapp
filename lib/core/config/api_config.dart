enum ApiEnvironment { dev, staging, uat, production }

class ApiConfig {
  // อ่านค่าจาก Command Line: flutter run --dart-define=ENV=dev
  static const String _env = String.fromEnvironment('ENV', defaultValue: 'prod');

  static ApiEnvironment get _currentEnvironment {
    switch (_env.toLowerCase()) {
      case 'dev':
        return ApiEnvironment.dev;
      case 'staging':
        return ApiEnvironment.staging;
      case 'uat':
        return ApiEnvironment.uat;
      case 'prod':
      case 'production':
      default:
        return ApiEnvironment.production;
    }
  }

  static String get baseUrl {
    switch (_currentEnvironment) {
      case ApiEnvironment.dev:
        return 'http://192.168.1.5:8080/api/v1'; 
      case ApiEnvironment.staging:
        return 'https://member.rspcoop.com/api/v1'; 
      case ApiEnvironment.uat:
        return 'https://member.rspcoop.com/api/v1'; 
      case ApiEnvironment.production:
        return 'https://member.rspcoop.com/api/v1';
    }
  }
}
