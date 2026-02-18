import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;


class LocalNotificationService {
  static const bool _inAppOnly = false;
  static const String _scheduledKey = 'scheduled_notifications';
  static const int _maxNotificationId = 2147483647; // 32-bit signed int max
  static const String _channelId = 'yatrika_reminders_v3';
  static const String _channelName = 'Yatrika Reminders';
  static const String _channelDescription =
      'Local trip and itinerary reminder alerts';
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static int _lastNotificationId = 0;

  static Future<void> initialize() async {
    if (_initialized || kIsWeb) {
      return;
    }

    tz.initializeTimeZones();
    try {
      final timezoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezoneName));
      debugPrint('Local timezone set: $timezoneName');
    } catch (e) {
      debugPrint('Failed to set local timezone, using default: $e');
    }

    if (!_inAppOnly) {
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings();
      const settings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notificationsPlugin.initialize(settings);
      await requestPermissions();
    }
    _initialized = true;
  }

  static Future<void> requestPermissions() async {
    if (kIsWeb || _inAppOnly) {
      return;
    }

    final androidImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidImplementation?.requestNotificationsPermission();
    if (Platform.isAndroid) {
      final canScheduleExact =
          await androidImplementation?.canScheduleExactNotifications();
      if (canScheduleExact == false) {
        await androidImplementation?.requestExactAlarmsPermission();
      }
    }

    final iosImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    await iosImplementation?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  static Future<bool> areNotificationsEnabled() async {
    if (_inAppOnly) return true;
    if (kIsWeb) return false;

    final androidImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    final androidEnabled = await androidImplementation?.areNotificationsEnabled();
    if (androidEnabled != null) {
      return androidEnabled;
    }

    // iOS plugin does not expose a direct "enabled" check here; assume true after permission prompt.
    return true;
  }

  static Future<void> showInstantNotification({
    required String title,
    required String body,
  }) async {
    if (kIsWeb || _inAppOnly) return;
    if (!_initialized) {
      await initialize();
    }

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.max,
        priority: Priority.high,
        channelShowBadge: true,
        category: AndroidNotificationCategory.alarm,
        playSound: true,
        enableVibration: true,
        audioAttributesUsage: AudioAttributesUsage.alarm,
      ),
      iOS: DarwinNotificationDetails(),
    );

    await _notificationsPlugin.show(
      _nextNotificationId(),
      title,
      body,
      details,
    );
  }

  static Future<bool> scheduleReminder({
    required String title,
    required String body,
    required DateTime scheduledAt,
  }) async {
    try {
      if (kIsWeb) {
        return false;
      }

      if (!_initialized) {
        await initialize();
      }

      if (scheduledAt.isBefore(DateTime.now())) {
        return false;
      }

      final id = _nextNotificationId();

      if (_inAppOnly) {
        await _storeScheduledNotification(
          ScheduledNotification(
            id: id,
            title: title,
            body: body,
            scheduledAt: scheduledAt,
          ),
        );
        return true;
      }

      await requestPermissions();
      final enabled = await areNotificationsEnabled();
      if (!enabled) {
        throw Exception('Notifications are disabled in system settings');
      }

      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.max,
          priority: Priority.high,
          category: AndroidNotificationCategory.alarm,
          playSound: true,
          enableVibration: true,
          channelShowBadge: true,
          audioAttributesUsage: AudioAttributesUsage.alarm,
        ),
        iOS: DarwinNotificationDetails(),
      );

      // id generated above
      AndroidScheduleMode scheduleMode =
          AndroidScheduleMode.inexactAllowWhileIdle;

      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (Platform.isAndroid) {
        final canScheduleExact =
            await androidImplementation?.canScheduleExactNotifications();
        scheduleMode = (canScheduleExact ?? false)
            ? AndroidScheduleMode.alarmClock
            : AndroidScheduleMode.inexactAllowWhileIdle;
      }

      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledAt, tz.local),
        details,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: scheduleMode,
      );

      await _storeScheduledNotification(
        ScheduledNotification(
          id: id,
          title: title,
          body: body,
          scheduledAt: scheduledAt,
        ),
      );

      return true;
    } catch (e, st) {
      debugPrint('scheduleReminder error: $e');
      debugPrint('$st');
      rethrow;
    }
  }

  static int _nextNotificationId() {
    final seed = DateTime.now().millisecondsSinceEpoch % _maxNotificationId;
    if (seed <= _lastNotificationId) {
      _lastNotificationId += 1;
    } else {
      _lastNotificationId = seed;
    }
    if (_lastNotificationId <= 0 || _lastNotificationId >= _maxNotificationId) {
      _lastNotificationId = 1;
    }
    return _lastNotificationId;
  }

  static Future<void> _storeScheduledNotification(
    ScheduledNotification notification,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await _getStoredScheduledNotifications();

    list.removeWhere((n) => n.id == notification.id);
    list.removeWhere(
      (n) =>
          n.title == notification.title &&
          n.body == notification.body &&
          n.scheduledAt.isAtSameMomentAs(notification.scheduledAt),
    );
    list.add(notification);
    list.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

    final encoded = list.map((n) => jsonEncode(n.toJson())).toList();
    await prefs.setStringList(_scheduledKey, encoded);
  }

  static Future<List<ScheduledNotification>> getUpcomingScheduledNotifications() async {
    final all = await _getStoredScheduledNotifications();
    final now = DateTime.now();
    return all.where((n) => n.scheduledAt.isAfter(now)).toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
  }

  static Future<List<ScheduledNotification>> getDueScheduledNotifications() async {
    final all = await _getStoredScheduledNotifications();
    final now = DateTime.now();
    final recentWindow = now.subtract(const Duration(days: 1));
    return all
        .where(
          (n) =>
              !n.scheduledAt.isAfter(now) &&
              n.scheduledAt.isAfter(recentWindow),
        )
        .toList()
      ..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
  }

  static Future<void> removeScheduledNotificationById(int id) async {
    if (!_inAppOnly) {
      await _notificationsPlugin.cancel(id);
    }
    final all = await _getStoredScheduledNotifications();
    final kept = all.where((n) => n.id != id).toList();
    final prefs = await SharedPreferences.getInstance();
    final encoded = kept.map((n) => jsonEncode(n.toJson())).toList();
    await prefs.setStringList(_scheduledKey, encoded);
  }

  static Future<void> clearTripReminders() async {
    final all = await _getStoredScheduledNotifications();
    final tripItems =
        all.where((n) => n.title == 'Yatrika Trip Reminder').toList();

    if (!_inAppOnly) {
      for (final item in tripItems) {
        await _notificationsPlugin.cancel(item.id);
      }
    }

    final kept = all.where((n) => n.title != 'Yatrika Trip Reminder').toList();
    final prefs = await SharedPreferences.getInstance();
    final encoded = kept.map((n) => jsonEncode(n.toJson())).toList();
    await prefs.setStringList(_scheduledKey, encoded);
  }

  static Future<List<ScheduledNotification>> _getStoredScheduledNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_scheduledKey) ?? <String>[];
    final parsed = <ScheduledNotification>[];

    for (final item in raw) {
      try {
        final map = jsonDecode(item) as Map<String, dynamic>;
        parsed.add(ScheduledNotification.fromJson(map));
      } catch (_) {}
    }

    final now = DateTime.now();
    final keepAfter = now.subtract(const Duration(days: 1));
    final kept = parsed.where((n) => n.scheduledAt.isAfter(keepAfter)).toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

    // Keep storage clean by removing old entries.
    final encoded = kept.map((n) => jsonEncode(n.toJson())).toList();
    await prefs.setStringList(_scheduledKey, encoded);

    return kept;
  }

  static Future<NotificationDebugInfo> getDebugInfo() async {
    if (!_initialized && !kIsWeb) {
      await initialize();
    }

    final enabled = await areNotificationsEnabled();
    bool exactAllowed = false;

    final androidImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (!kIsWeb && Platform.isAndroid) {
      exactAllowed =
          await androidImplementation?.canScheduleExactNotifications() ?? false;
    }

    final pending = _inAppOnly
        ? <PendingNotificationRequest>[]
        : await _notificationsPlugin.pendingNotificationRequests();
    final upcoming = await getUpcomingScheduledNotifications();

    return NotificationDebugInfo(
      notificationsEnabled: enabled,
      exactAlarmAllowed: exactAllowed,
      pendingNotificationCount: pending.length,
      storedUpcomingCount: upcoming.length,
      nextUpcomingAt: upcoming.isNotEmpty ? upcoming.first.scheduledAt : null,
    );
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

class NotificationDebugInfo {
  NotificationDebugInfo({
    required this.notificationsEnabled,
    required this.exactAlarmAllowed,
    required this.pendingNotificationCount,
    required this.storedUpcomingCount,
    required this.nextUpcomingAt,
  });

  final bool notificationsEnabled;
  final bool exactAlarmAllowed;
  final int pendingNotificationCount;
  final int storedUpcomingCount;
  final DateTime? nextUpcomingAt;
}
