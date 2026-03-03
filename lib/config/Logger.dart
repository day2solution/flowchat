import 'dart:developer' as developer;
import 'environment.dart';

class Logger {
  static void log(String message) {
    if (Environment.debugMode) {
      developer.log(message);
    }
  }
}
