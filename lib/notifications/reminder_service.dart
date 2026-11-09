import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as timezone_data;
import 'package:timezone/timezone.dart' as timezone;

import '../data/study_models.dart';

enum ReminderResult {
  scheduledExact,
  scheduledApproximate,
  noPermission,
  unsupported,
  tooLate,
  noReminder,
}

class ReminderService {
  static const _channel = AndroidNotificationChannel(
    'studyflow_reminders',
    'Avisos de estudo',
    description: 'Lembretes dos compromissos cadastrados no calendário.',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  String? initializationError;
  bool _initialized = false;

  bool get supportsScheduledReminders =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<void> initialize() async {
    if (!supportsScheduledReminders) return;

    timezone_data.initializeTimeZones();
    final deviceTimezone = await FlutterTimezone.getLocalTimezone();
    timezone.setLocalLocation(timezone.getLocation(deviceTimezone.identifier));

    final initialized = await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
    if (initialized != true) {
      throw StateError('Não foi possível iniciar as notificações do Android.');
    }

    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_channel);
    _initialized = true;
  }

  Future<ReminderResult> schedule(CalendarEvent event) async {
    if (event.reminderMinutes == null) return ReminderResult.noReminder;
    if (!supportsScheduledReminders || !_initialized) {
      return ReminderResult.unsupported;
    }

    final scheduledAt = event.dateTime.subtract(
      Duration(minutes: event.reminderMinutes!),
    );
    if (!scheduledAt.isAfter(DateTime.now())) return ReminderResult.tooLate;

    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final permission = await android?.requestNotificationsPermission();
    if (permission == false ||
        await android?.areNotificationsEnabled() == false) {
      return ReminderResult.noPermission;
    }

    var exactPermission = await android?.canScheduleExactNotifications();
    if (exactPermission != true) {
      exactPermission = await android?.requestExactAlarmsPermission();
    }
    final exact = exactPermission == true;

    await _plugin.zonedSchedule(
      id: event.id,
      title: 'Lembrete: ${event.title}',
      body: event.description.isEmpty
          ? '${event.kind} às ${_formatTime(event.dateTime)}'
          : event.description,
      scheduledDate: timezone.TZDateTime.from(scheduledAt, timezone.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'studyflow_reminders',
          'Avisos de estudo',
          channelDescription:
              'Lembretes dos compromissos cadastrados no calendário.',
          importance: Importance.max,
          priority: Priority.high,
          category: AndroidNotificationCategory.reminder,
          visibility: NotificationVisibility.private,
          playSound: true,
          enableVibration: true,
        ),
      ),
      androidScheduleMode: exact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
      payload: event.id.toString(),
    );
    return exact
        ? ReminderResult.scheduledExact
        : ReminderResult.scheduledApproximate;
  }

  Future<void> cancel(int id) => _plugin.cancel(id: id);

  String _formatTime(DateTime value) =>
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
}
