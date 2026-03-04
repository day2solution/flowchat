import 'dart:developer' as dev;
import 'package:flowchat/config/environment.dart';

class Logger {
  static void log(String tag, String message, {Object? error, StackTrace? stack}) {
    // 🔥 Respects your Application Level Config
    if (Environment.debugMode) {
      dev.log(
        message,
        name: tag,      // This is where you put the "File Name" or "Module Name"
        error: error,
        stackTrace: stack,
        time: DateTime.now(),
      );
    }
  }
}