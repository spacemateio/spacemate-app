import 'dart:io';

enum Environment {
  dev,
  test,
  prod,
}

class EnvironmentConfig {
  static Environment environment = Environment.dev;  // Default environment

  static String get baseUrl {
    if (Platform.isAndroid) {
      switch (environment) {
        case Environment.dev:
          return 'http://10.0.2.2:3000';
        case Environment.test:
          return 'https://test.spacemate.io';
        case Environment.prod:
          return 'https://spacemate.io';
      }
    } else if (Platform.isIOS) {
      switch (environment) {
        case Environment.dev:
          return 'http://localhost:3000';
        case Environment.test:
          return 'https://test.spacemate.io';
        case Environment.prod:
          return 'https://spacemate.io';
      }
    }
    return 'http://127.0.0.1:3000';
  }
}