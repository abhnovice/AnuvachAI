import 'dart:io';
import 'package:flutter/services.dart';

class LocalFeatures {
  static const channel = MethodChannel('ai.anuvach/local_features');
  Future<bool> startMicrophone(String language) async =>
      await channel.invokeMethod<bool>('startMic', {'language': language}) ??
      false;
  Future<void> stopMicrophone() => channel.invokeMethod<void>('stopMic');
  Future<List<Map<String, dynamic>>> apps() async {
    if (!Platform.isAndroid) throw UnsupportedError('iOS');
    final list = await channel.invokeListMethod<dynamic>('listApps') ?? [];
    return list.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  Future<Uint8List?> appIcon(String package) =>
      channel.invokeMethod<Uint8List>('appIcon', {'package': package});
  Future<void> openAccessibility() =>
      channel.invokeMethod<void>('openAccessibility');
  Future<void> openLink(Uri uri) =>
      channel.invokeMethod<void>('openLink', {'url': uri.toString()});
  Future<void> openApp(String package) =>
      channel.invokeMethod<void>('openApp', {'package': package});
}
