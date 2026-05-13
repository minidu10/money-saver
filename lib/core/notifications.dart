import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'preferences.dart';

const _kReminderEnabled = 'reminder_enabled';
const _kReminderHour = 'reminder_hour';
const _kReminderMinute = 'reminder_minute';
const int _reminderId = 1001;

class NotificationService {
  NotificationService(this._plugin);
  final FlutterLocalNotificationsPlugin _plugin;
  static bool _tzInitialized = false;

  static Future<NotificationService> init() async {
    final plugin = FlutterLocalNotificationsPlugin();
    await plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );
    if (!_tzInitialized) {
      tzdata.initializeTimeZones();
      _tzInitialized = true;
    }
    return NotificationService(plugin);
  }

  Future<bool> requestPermission() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    final granted = await android?.requestNotificationsPermission();
    final exact = await android?.requestExactAlarmsPermission();
    return (granted ?? true) && (exact ?? true);
  }

  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
  }) async {
    await _plugin.cancel(id: _reminderId);

    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id: _reminderId,
      title: 'Money Saver',
      body: "Don't forget to log today's expenses",
      scheduledDate: scheduled,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder',
          'Daily reminder',
          channelDescription: 'Reminder to log your expenses',
          importance: Importance.defaultImportance,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelReminder() => _plugin.cancel(id: _reminderId);
}

final notificationServiceProvider = Provider<NotificationService>(
  (_) => throw UnimplementedError(
    'Override notificationServiceProvider in main() with the initialized service.',
  ),
);

class ReminderState {
  final bool enabled;
  final int hour;
  final int minute;
  const ReminderState({
    required this.enabled,
    required this.hour,
    required this.minute,
  });

  String get formattedTime =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}

class ReminderNotifier extends Notifier<ReminderState> {
  @override
  ReminderState build() {
    final p = ref.read(sharedPreferencesProvider);
    return ReminderState(
      enabled: p.getBool(_kReminderEnabled) ?? false,
      hour: p.getInt(_kReminderHour) ?? 20,
      minute: p.getInt(_kReminderMinute) ?? 0,
    );
  }

  Future<void> setEnabled(bool value) async {
    final p = ref.read(sharedPreferencesProvider);
    final svc = ref.read(notificationServiceProvider);
    await p.setBool(_kReminderEnabled, value);
    if (value) {
      final ok = await svc.requestPermission();
      if (!ok) {
        await p.setBool(_kReminderEnabled, false);
        return;
      }
      await svc.scheduleDailyReminder(hour: state.hour, minute: state.minute);
    } else {
      await svc.cancelReminder();
    }
    state = ReminderState(
        enabled: value, hour: state.hour, minute: state.minute);
  }

  Future<void> setTime(int hour, int minute) async {
    final p = ref.read(sharedPreferencesProvider);
    final svc = ref.read(notificationServiceProvider);
    await p.setInt(_kReminderHour, hour);
    await p.setInt(_kReminderMinute, minute);
    state =
        ReminderState(enabled: state.enabled, hour: hour, minute: minute);
    if (state.enabled) {
      await svc.scheduleDailyReminder(hour: hour, minute: minute);
    }
  }
}

final reminderProvider =
    NotifierProvider<ReminderNotifier, ReminderState>(ReminderNotifier.new);

// Re-export for main.dart bootstrap.
typedef SP = SharedPreferences;
