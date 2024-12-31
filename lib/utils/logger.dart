import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:logger/logger.dart';

final logger = Logger(
  printer: PrettyPrinter(),
);

void logInfo(String message) {
  if (kDebugMode) {
    logger.i(message);
  }
}

void logDebug(String message) {
  if (kDebugMode) {
    logger.d(message);
  }
}

void logError(String message) {
  logger.e(message);
}

void logWarning(String message) {
  if (kDebugMode) {
    logger.w(message);
  }
}
