import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class DeviceStorageInfo {
  const DeviceStorageInfo({
    required this.totalMb,
    required this.freeMb,
    required this.usedMb,
    required this.usedFraction,
  });

  final double totalMb;
  final double freeMb;
  final double usedMb;
  final double usedFraction;

  String get totalFormatted => _formatMb(totalMb);
  String get freeFormatted => _formatMb(freeMb);
  String get usedFormatted => _formatMb(usedMb);

  int get usedPercent => (usedFraction * 100).round().clamp(0, 100);

  static String _formatMb(double mb) {
    if (mb <= 0) return '--';
    if (mb >= 1024) {
      final gb = mb / 1024;
      return gb >= 100 ? '${gb.round()} GB' : '${gb.toStringAsFixed(1)} GB';
    }
    return '${mb.round()} MB';
  }
}

class DeviceStorageService {
  DeviceStorageService._();

  static const _channel = MethodChannel('flow_drive/device_storage');

  static Future<DeviceStorageInfo?> fetch() async {
    if (kIsWeb) return null;

    try {
      final result = await _channel.invokeMethod<Object>('getStorageInfo');
      if (result is! Map) return null;

      final totalMb = _readMb(result['totalMb']);
      final freeMb = _readMb(result['freeMb']);

      if (totalMb == null || freeMb == null || totalMb <= 0) return null;

      final usedMb = (totalMb - freeMb).clamp(0.0, totalMb);
      final usedFraction = (usedMb / totalMb).clamp(0.0, 1.0);

      return DeviceStorageInfo(
        totalMb: totalMb,
        freeMb: freeMb,
        usedMb: usedMb,
        usedFraction: usedFraction,
      );
    } on MissingPluginException {
      return _fetchFallback();
    } on PlatformException {
      return _fetchFallback();
    }
  }

  static double? _readMb(Object? value) {
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return null;
  }

  static Future<DeviceStorageInfo?> _fetchFallback() async {
    if (!Platform.isAndroid && !Platform.isIOS) return null;
    return null;
  }
}
