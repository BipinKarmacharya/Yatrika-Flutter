import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart'; 

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static const _scheduledKey = 'scheduled_notifications';

  static Future<void> initialize({bool inAppOnly = false}) async {
    if (_initialized || kIsWeb) return;

    // --- Timezone setup ---
    tz.initializeTimeZones();
    try {
      final timezoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezoneName));
      debugPrint('Local timezone set: $timezoneName');
    } catch (e) {
      debugPrint('Failed to set local timezone, using default: $e');
    }

    if (inAppOnly) {
      _initialized = true;
      return;
    }

    // --- Platform-specific initialization ---
    final androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    final iosSettings = DarwinInitializationSettings();
    final linuxSettings = LinuxInitializationSettings(defaultActionName: 'Open');

    final settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      linux: Platform.isLinux ? linuxSettings : null,
    );

    await _notificationsPlugin.initialize(settings);

    // --- Request permissions ---
    await _requestPermissions();

    _initialized = true;
  }

  static Future<void> _requestPermissions() async {
    if (kIsWeb) return;

    // Android
    if (Platform.isAndroid) {
      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidImplementation?.requestNotificationsPermission();
      final canScheduleExact =
          await androidImplementation?.canScheduleExactNotifications();
      if (canScheduleExact == false) {
        await androidImplementation?.requestExactAlarmsPermission();
      }
    }

    // iOS
    if (Platform.isIOS || Platform.isMacOS) {
      final iosImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      await iosImplementation?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    // Linux currently does not require explicit permissions
  }

  // --- Example for showing an instant notification ---
  static Future<void> showInstantNotification({
    required String title,
    required String body,
  }) async {
    if (kIsWeb) return;
    if (!_initialized) await initialize();

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        'default_channel',
        'Default Channel',
        channelDescription: 'General notifications',
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
      linux: LinuxNotificationDetails(),
    );

    await _notificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000), // unique id
      title,
      body,
      details,
    );
  }

  /// Get all upcoming notifications
  static Future<List<ScheduledNotification>> getUpcomingScheduledNotifications() async {
    final all = await _getStoredScheduledNotifications();
    final now = DateTime.now();
    return all.where((n) => n.scheduledAt.isAfter(now)).toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
  }

  /// Get due notifications (within past 1 day)
  static Future<List<ScheduledNotification>> getDueScheduledNotifications() async {
    final all = await _getStoredScheduledNotifications();
    final now = DateTime.now();
    final recentWindow = now.subtract(const Duration(days: 1));
    return all.where((n) => !n.scheduledAt.isAfter(now) && n.scheduledAt.isAfter(recentWindow)).toList()
      ..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
  }

  /// Internal: fetch stored notifications from SharedPreferences
  static Future<List<ScheduledNotification>> _getStoredScheduledNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_scheduledKey) ?? [];
    final parsed = <ScheduledNotification>[];
    for (final item in raw) {
      try {
        final map = jsonDecode(item) as Map<String, dynamic>;
        parsed.add(ScheduledNotification.fromJson(map));
      } catch (_) {}
    }
    return parsed;
  }

  /// Save a notification to local storage
  static Future<void> storeScheduledNotification(ScheduledNotification n) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await _getStoredScheduledNotifications();
    list.removeWhere((x) => x.id == n.id);
    list.add(n);
    final encoded = list.map((x) => jsonEncode(x.toJson())).toList();
    await prefs.setStringList(_scheduledKey, encoded);
  }
}


class ScheduledNotification {
  ScheduledNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.scheduledAt,
  });

  final int id;
  final String title;
  final String body;
  final DateTime scheduledAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'scheduledAt': scheduledAt.toIso8601String(),
      };

  factory ScheduledNotification.fromJson(Map<String, dynamic> json) {
    return ScheduledNotification(
      id: json['id'] as int,
      title: json['title'] as String,
      body: json['body'] as String,
      scheduledAt: DateTime.parse(json['scheduledAt'] as String),
    );
  }
}
