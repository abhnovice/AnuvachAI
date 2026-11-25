import 'dart:io';
import 'package:flutter/services.dart';
import 'reporting.dart';

abstract interface class DeviceReview {
  bool get available;
  Future<Json> checkSecureLock();
  Future<void> openSettings();
}

class PlatformDeviceReview implements DeviceReview {
  static const _channel = MethodChannel('ai.anuvach/device_review');
  @override
  bool get available => Platform.isAndroid;
  @override
  Future<Json> checkSecureLock() async {
    if (!available) {
      throw UnsupportedError(
        'Automatic device checks are unavailable on iOS in this stage.',
      );
    }
    final secure = await _channel.invokeMethod<bool>('checkSecureLock');
    if (secure == null) throw StateError('Device check returned no result.');
    return {
      'check': 'secure_screen_lock',
      'platform': 'android',
      'value': secure,
      'checkedAt': DateTime.now().toUtc().toIso8601String(),
      'source': 'client_public_api',
    };
  }

  @override
  Future<void> openSettings() async =>
      _channel.invokeMethod<void>('openSettings');
}
