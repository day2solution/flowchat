class Environment {
  static const String environment = String.fromEnvironment('ENV', defaultValue: 'dev');

  static String get hostApiUrl {
    switch (environment) {
      case 'production':
        return 'https://www.jogeshwaricharaja.com/flowchat-api-service';
      case 'qa':
        return 'http://192.168.0.133:8080/flowchat-api-service';
      case 'dev':
        return 'http://192.168.0.133:8081';
      default:
        return 'http://192.168.0.133:8081';
    }
  }
  static String get socketUrl {
    switch (environment) {
      case 'production':
        return 'ws://www.jogeshwaricharaja.com/flowchat-api-service';
      case 'qa':
        return 'ws://192.168.0.133:8080/flowchat-api-service';
      case 'dev':
        return 'ws://192.168.0.133:8081';
      default:
        return 'ws://192.168.0.133:8081';
    }
  }

  static bool get debugMode => environment != 'production';
}

void main() {
  if (Environment.debugMode) {
    print('Running in ${Environment.environment} mode');
    print('API URL: ${Environment.hostApiUrl}');
    print('Socket URL: ${Environment.socketUrl}');
    print('Debug Mode: ${Environment.debugMode}');
  }
}
