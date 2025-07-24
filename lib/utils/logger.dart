import 'package:flutter/foundation.dart';

class Logger {
  static const String _tag = 'PharmacyApp';

  static void debug(String message, [String? tag]) {
    if (kDebugMode) {
      debugPrint('[$_tag${tag != null ? ':$tag' : ''}] DEBUG: $message');
    }
  }

  static void info(String message, [String? tag]) {
    if (kDebugMode) {
      debugPrint('[$_tag${tag != null ? ':$tag' : ''}] INFO: $message');
    }
  }

  static void warning(String message, [String? tag]) {
    if (kDebugMode) {
      debugPrint('[$_tag${tag != null ? ':$tag' : ''}] WARNING: $message');
    }
  }

  static void error(String message, [String? tag, Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      debugPrint('[$_tag${tag != null ? ':$tag' : ''}] ERROR: $message');
      if (error != null) {
        debugPrint('Error details: $error');
      }
      if (stackTrace != null) {
        debugPrint('Stack trace: $stackTrace');
      }
    }
  }

  static void network(String message, [String? endpoint]) {
    if (kDebugMode) {
      debugPrint('[$_tag:NETWORK${endpoint != null ? ':$endpoint' : ''}] $message');
    }
  }

  static void auth(String message) {
    if (kDebugMode) {
      debugPrint('[$_tag:AUTH] $message');
    }
  }

  static void prescription(String message) {
    if (kDebugMode) {
      debugPrint('[$_tag:PRESCRIPTION] $message');
    }
  }

  static void cart(String message) {
    if (kDebugMode) {
      debugPrint('[$_tag:CART] $message');
    }
  }

  static void order(String message) {
    if (kDebugMode) {
      debugPrint('[$_tag:ORDER] $message');
    }
  }
}
