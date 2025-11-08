
import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart'; // لو هتستخدم الإنترنت


String encryptText(String text) {
  final key = encrypt.Key.fromUtf8('my32lengthsupersecretnooneknows1');
  final iv = encrypt.IV.fromUtf8('my16bytesiv12345');
  final encrypter = encrypt.Encrypter(encrypt.AES(key));
  final encrypted = encrypter.encrypt(text, iv: iv);
  return encrypted.base64;
}

// متغير عالمي لتتبع وقت بدء التطبيق
DateTime? _appStartTime;

// دالة لاسترجاع معرف الجهاز
Future<String> getDeviceId() async {
  final prefs = await SharedPreferences.getInstance();
  final deviceInfo = DeviceInfoPlugin();
  String deviceId = '';

  if (Platform.isAndroid) {
    final androidInfo = await deviceInfo.androidInfo;
    deviceId = androidInfo.id;
  } else if (Platform.isIOS) {
    final iosInfo = await deviceInfo.iosInfo;
    deviceId = iosInfo.identifierForVendor ?? '';
  }

  prefs.setString('device_id', deviceId);
  prefs.setString('encrypted_device_id', encryptText(deviceId));
  return deviceId;
}

// دالة للتحقق من الاتصال بالإنترنت
Future<bool> _isConnectedToInternet() async {
  try {
    final result = await InternetAddress.lookup('google.com');
    return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
  } catch (_) {
    return false;
  }
}

Future<bool> checkLicenseStatus() async {
  final prefs = await SharedPreferences.getInstance();
  final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  String deviceId = '';

  if (Platform.isAndroid) {
    final androidInfo = await deviceInfo.androidInfo;
    deviceId = androidInfo.id;
  } else if (Platform.isIOS) {
    final iosInfo = await deviceInfo.iosInfo;
    deviceId = iosInfo.identifierForVendor ?? '';
  }

  prefs.setString('device_id', deviceId);
  prefs.setString('encrypted_device_id', encryptText(deviceId));

  final String? serialNumber = prefs.getString('serial_number');
  if (serialNumber != null && await isValidSerial(serialNumber)) {
    final expiry = prefs.getInt('serial_expiry');
    if (expiry == -1) return true; // Lifetime license
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    if (now < expiry!) return true; // Valid serial with expiry
  }

  // تحقق من الفترة التجريبية (5 دقائق)
  _appStartTime = _appStartTime ?? DateTime.now();
  final int totalUsageSeconds = prefs.getInt('total_usage_seconds') ?? 0;
  const int trialPeriodSeconds = 60; // 5 دقائق

  final currentUsage = DateTime.now().difference(_appStartTime!).inSeconds + totalUsageSeconds;
  if (currentUsage < trialPeriodSeconds) {
    return true; // اسمح بالدخول خلال 5 دقائق
  }

  await prefs.setInt('total_usage_seconds', currentUsage);
  return false;
}

// دالة لتحديث وقت الاستخدام
Future<void> updateUsageTime(DateTime startTime) async {
  final prefs = await SharedPreferences.getInstance();
  if (_appStartTime != null) {
    final now = DateTime.now();
    final usageDuration = now.difference(startTime).inSeconds;
    final int totalUsageSeconds = (prefs.getInt('total_usage_seconds') ?? 0) + usageDuration;
    await prefs.setInt('total_usage_seconds', totalUsageSeconds);
    _appStartTime = null;
  }
}

// دالة للتحقق من صحة الرمز التسلسلي
Future<bool> isValidSerial(String serial) async {
  final prefs = await SharedPreferences.getInstance();
  final encryptedDeviceId = prefs.getString('encrypted_device_id') ?? '';

  final parts = serial.split('-');
  if (parts.length != 4) return false;

  final type = parts[0];
  final duration = parts[1];
  final year = parts[2];
  final serialDeviceId = parts[3];

  if (serialDeviceId != encryptedDeviceId) return false;

  if (type == 'TRIAL' && duration == '3DAYS' && year == '2025') {
    final expiry = DateTime.now().add(const Duration(days: 3)).millisecondsSinceEpoch ~/ 1000;
    await prefs.setInt('serial_expiry', expiry);
    return true;
  } else if (type == 'MONTH' && duration == '30DAYS' && year == '2025') {
    final expiry = DateTime.now().add(const Duration(days: 30)).millisecondsSinceEpoch ~/ 1000;
    await prefs.setInt('serial_expiry', expiry);
    return true;
  } else if (type == 'LIFETIME' && duration == 'LIFETIME' && year == '2025') {
    await prefs.setInt('serial_expiry', -1);
    return true;
  }

  return false;
}

// دالة لحفظ الرمز التسلسلي
Future<void> saveSerialNumber(String serial) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('serial_number', serial);
}