import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/alarm_payload.dart';
import './AlarmService/alarm_receiver.dart';


class NotificationService {
  NotificationService._();

  static final NotificationService instance =
  NotificationService._();

  final FlutterLocalNotificationsPlugin
  _notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  /*
   * Se inicializa con UTC para evitar:
   *
   * LateInitializationError:
   * Field '_local' has not been initialized.
   *
   * Después se reemplaza por la zona horaria real
   * del dispositivo.
   */
  tz.Location _local = tz.UTC;

  bool _isInitialized = false;

  static const String _channelId =
      'vitacare_medication_channel';

  static const String _channelName =
      'Recordatorios de medicamentos';

  static const String _channelDescription =
      'Notificaciones y alarmas para recordar la toma de medicamentos.';

  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    await _initializeTimezone();

    const AndroidInitializationSettings
    androidInitializationSettings =
    AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const DarwinInitializationSettings
    iosInitializationSettings =
    DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initializationSettings =
    InitializationSettings(
      android: androidInitializationSettings,
      iOS: iosInitializationSettings,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse:
      _onNotificationResponse,
    );

    await _createNotificationChannel();
    await requestPermissions();

    _isInitialized = true;

    debugPrint(
      'NotificationService inicializado correctamente.',
    );
  }

  Future<void> _initializeTimezone() async {
    /*
     * Carga la base de datos de zonas horarias.
     */
    tz.initializeTimeZones();

    try {
      final TimezoneInfo timezoneInfo =
      await FlutterTimezone.getLocalTimezone();

      final String timezoneIdentifier =
          timezoneInfo.identifier;

      _local = tz.getLocation(
        timezoneIdentifier,
      );

      tz.setLocalLocation(_local);

      debugPrint(
        'Zona horaria configurada: $timezoneIdentifier',
      );
    } catch (error, stackTrace) {
      /*
       * Si el dispositivo devuelve una zona horaria
       * desconocida, usamos UTC para evitar que la
       * aplicación se cierre.
       */
      _local = tz.UTC;
      tz.setLocalLocation(_local);

      debugPrint(
        'No se pudo obtener la zona horaria local: $error',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      debugPrint(
        'Se utilizará UTC temporalmente.',
      );
    }
  }

  Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel =
    AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    final AndroidFlutterLocalNotificationsPlugin?
    androidPlugin =
    _notificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(
      channel,
    );
  }

  Future<void> requestPermissions() async {
    final AndroidFlutterLocalNotificationsPlugin?
    androidPlugin =
    _notificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.requestNotificationsPermission();

    /*
     * Necesario para alarmas exactas en versiones
     * recientes de Android.
     */
    try {
      await androidPlugin?.requestExactAlarmsPermission();
    } catch (error) {
      debugPrint(
        'No se pudo solicitar permiso de alarmas exactas: $error',
      );
    }

    final IOSFlutterLocalNotificationsPlugin?
    iosPlugin =
    _notificationsPlugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();

    await iosPlugin?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<void> scheduleMedicationNotification({
    required AlarmPayload payload,
  }) async {
    await _ensureInitialized();

    final DateTime now = DateTime.now();

    if (!payload.scheduledDateTime.isAfter(now)) {
      throw ArgumentError(
        'La fecha de la notificación debe ser posterior a la fecha actual.',
      );
    }

    final tz.TZDateTime scheduledDate =
    tz.TZDateTime.from(
      payload.scheduledDateTime,
      _local,
    );

    const AndroidNotificationDetails androidDetails =
    AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      fullScreenIntent: true,
      ongoing: false,
      autoCancel: true,
      playSound: true,
      enableVibration: true,
    );

    const DarwinNotificationDetails iosDetails =
    DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails =
    NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final String notificationBody =
    _buildNotificationBody(
      payload,
    );

    await _notificationsPlugin.zonedSchedule(
      payload.notificationId,
      'Hora de tomar ${payload.medicationName}',
      notificationBody,
      scheduledDate,
      notificationDetails,
      androidScheduleMode:
      AndroidScheduleMode.exactAllowWhileIdle,
      payload: jsonEncode(
        payload.toMap(),
      ),
    );

    debugPrint(
      'Notificación programada correctamente.',
    );

    debugPrint(
      'Medicamento: ${payload.medicationName}',
    );

    debugPrint(
      'Fecha: ${payload.scheduledDateTime}',
    );

    debugPrint(
      'Notification ID: ${payload.notificationId}',
    );
  }

  Future<void> showInstantNotification({
    required AlarmPayload payload,
  }) async {
    await _ensureInitialized();

    const AndroidNotificationDetails androidDetails =
    AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      fullScreenIntent: true,
      playSound: true,
      enableVibration: true,
    );

    const DarwinNotificationDetails iosDetails =
    DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails =
    NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      payload.notificationId,
      'Hora de tomar ${payload.medicationName}',
      _buildNotificationBody(payload),
      notificationDetails,
      payload: jsonEncode(
        payload.toMap(),
      ),
    );
  }

  Future<void> cancelNotification(
      int notificationId,
      ) async {
    await _ensureInitialized();

    await _notificationsPlugin.cancel(
      notificationId,
    );

    debugPrint(
      'Notificación cancelada: $notificationId',
    );
  }

  Future<void> cancelAllNotifications() async {
    await _ensureInitialized();

    await _notificationsPlugin.cancelAll();

    debugPrint(
      'Todas las notificaciones fueron canceladas.',
    );
  }

  Future<List<PendingNotificationRequest>>
  getPendingNotifications() async {
    await _ensureInitialized();

    return _notificationsPlugin
        .pendingNotificationRequests();
  }

  String _buildNotificationBody(
      AlarmPayload payload,
      ) {
    final List<String> information = [];

    if (payload.dose.trim().isNotEmpty) {
      information.add(
        'Dosis: ${payload.dose.trim()}',
      );
    }

    if (payload.instructions.trim().isNotEmpty) {
      information.add(
        payload.instructions.trim(),
      );
    }

    if (information.isEmpty) {
      return 'Toca la notificación para revisar tu medicamento.';
    }

    return information.join(' · ');
  }

  void _onNotificationResponse(
      NotificationResponse response,
      ) {
    final String? payload = response.payload;

    if (payload == null || payload.trim().isEmpty) {
      debugPrint(
        'La notificación no contiene información.',
      );

      return;
    }

    AlarmReceiver.instance.handlePayload(
      payload,
    );
  }

  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }
}