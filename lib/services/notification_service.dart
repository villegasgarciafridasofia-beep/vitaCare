import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/alarm_payload.dart';
import 'AlarmService/alarm_receiver.dart';
import 'navigation_service.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  tz.Location _local = tz.UTC;

  bool _initialized = false;

  // =========================================================
  // CONFIGURACIÓN DEL CANAL
  // =========================================================

  /*
   * Se utiliza un canal nuevo porque Android conserva
   * la configuración de sonido de los canales anteriores.
   */
  static const String medicationChannelId = 'medication_alarm_channel_v7';

  static const String medicationChannelName = 'Alarmas de medicamentos';

  static const String medicationChannelDescription =
      'Recordatorios importantes para tomar medicamentos';

  // =========================================================
  // INICIALIZACIÓN
  // =========================================================

  Future<void> initialize() async {
    if (_initialized) {
      debugPrint('NotificationService ya estaba inicializado.');
      return;
    }

    try {
      await _configureTimezone();

      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
          );

      const InitializationSettings initializationSettings =
          InitializationSettings(android: androidSettings, iOS: iosSettings);

      final bool? initialized = await flutterLocalNotificationsPlugin
          .initialize(
            initializationSettings,
            onDidReceiveNotificationResponse: _onNotificationResponse,
            onDidReceiveBackgroundNotificationResponse:
                notificationTapBackground,
          );

      debugPrint(
        'Plugin de notificaciones inicializado: '
        '$initialized',
      );

      await _createAndroidNotificationChannel();

      await requestPermissions();

      _initialized = true;

      debugPrint('NotificationService inicializado correctamente.');
    } catch (error, stackTrace) {
      debugPrint('Error inicializando NotificationService: $error');

      debugPrintStack(stackTrace: stackTrace);

      rethrow;
    }
  }

  // =========================================================
  // CONFIGURAR ZONA HORARIA
  // =========================================================

  Future<void> _configureTimezone() async {
    tz.initializeTimeZones();

    try {
      final TimezoneInfo timezoneInfo =
          await FlutterTimezone.getLocalTimezone();

      final String timezoneIdentifier = timezoneInfo.identifier;

      _local = tz.getLocation(timezoneIdentifier);

      tz.setLocalLocation(_local);

      debugPrint(
        'Zona horaria configurada: '
        '$timezoneIdentifier',
      );
    } catch (error) {
      _local = tz.UTC;

      tz.setLocalLocation(tz.UTC);

      debugPrint(
        'No fue posible detectar la zona horaria: '
        '$error',
      );

      debugPrint('Se utilizará UTC temporalmente.');
    }
  }

  // =========================================================
  // CREAR CANAL DE NOTIFICACIONES PARA ANDROID
  // =========================================================

  Future<void> _createAndroidNotificationChannel() async {
    if (kIsWeb) {
      return;
    }

    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    if (androidPlugin == null) {
      debugPrint(
        'No se encontró el plugin de notificaciones '
        'de Android.',
      );
      return;
    }

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      medicationChannelId,
      medicationChannelName,
      description: medicationChannelDescription,
      importance: Importance.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('medication_alarm'),
      enableVibration: true,
      showBadge: true,
      audioAttributesUsage: AudioAttributesUsage.alarm,
    );

    await androidPlugin.createNotificationChannel(channel);

    debugPrint(
      'Canal de alarma creado: '
      '$medicationChannelId',
    );
  }

  // =========================================================
  // SOLICITAR PERMISOS
  // =========================================================

  Future<void> requestPermissions() async {
    if (kIsWeb) {
      return;
    }

    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    if (androidPlugin == null) {
      debugPrint(
        'No fue posible solicitar permisos '
        'en Android.',
      );
      return;
    }

    try {
      final bool? notificationsGranted = await androidPlugin
          .requestNotificationsPermission();

      debugPrint(
        'Permiso de notificaciones: '
        '$notificationsGranted',
      );

      final bool? canScheduleExact = await androidPlugin
          .canScheduleExactNotifications();

      debugPrint(
        'Puede programar alarmas exactas: '
        '$canScheduleExact',
      );

      if (canScheduleExact != true) {
        final bool? exactAlarmGranted = await androidPlugin
            .requestExactAlarmsPermission();

        debugPrint(
          'Permiso de alarmas exactas: '
          '$exactAlarmGranted',
        );
      }
    } catch (error, stackTrace) {
      debugPrint('Error solicitando permisos: $error');

      debugPrintStack(stackTrace: stackTrace);
    }
  }

  // =========================================================
  // DETALLES DE LA NOTIFICACIÓN
  // =========================================================

  NotificationDetails _buildNotificationDetails({required String ticker}) {
    const RawResourceAndroidNotificationSound alarmSound =
        RawResourceAndroidNotificationSound('medication_alarm');

    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          medicationChannelId,
          medicationChannelName,
          channelDescription: medicationChannelDescription,
          importance: Importance.max,
          priority: Priority.max,
          playSound: true,
          sound: alarmSound,
          enableVibration: true,
          category: AndroidNotificationCategory.alarm,
          visibility: NotificationVisibility.public,
          fullScreenIntent: false,
          autoCancel: true,
          ongoing: false,
          audioAttributesUsage: AudioAttributesUsage.alarm,
          ticker: ticker,
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    return NotificationDetails(android: androidDetails, iOS: iosDetails);
  } // =========================================================
  // NOTIFICACIÓN INMEDIATA DE PRUEBA
  // =========================================================

  Future<void> showTestNotification() async {
    await _ensureInitialized();

    final NotificationDetails details = _buildNotificationDetails(
      ticker: 'Prueba de notificación de VitaCare AI',
    );

    await flutterLocalNotificationsPlugin.show(
      999,
      'Prueba de VitaCare AI',
      'Las notificaciones funcionan correctamente',
      details,
      payload: jsonEncode(<String, dynamic>{'type': 'test'}),
    );

    debugPrint('Notificación inmediata enviada.');
  }

  // =========================================================
  // PRUEBA PROGRAMADA EN UN MINUTO
  // =========================================================

  Future<void> scheduleOneMinuteTest() async {
    await _ensureInitialized();

    final tz.TZDateTime now = tz.TZDateTime.now(_local);

    final tz.TZDateTime scheduledDate = now.add(const Duration(minutes: 1));

    final NotificationDetails details = _buildNotificationDetails(
      ticker: 'Prueba programada de VitaCare AI',
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
      999998,
      'Prueba programada de VitaCare AI',
      'Esta alarma fue programada hace un minuto.',
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: jsonEncode(<String, dynamic>{'type': 'scheduled_test'}),
    );

    debugPrint('Prueba programada para: $scheduledDate');
  }

  // =========================================================
  // PROGRAMAR NOTIFICACIÓN DE MEDICAMENTO
  // =========================================================

  Future<void> scheduleMedicationNotification({
    required AlarmPayload payload,
  }) async {
    await _ensureInitialized();

    final tz.TZDateTime scheduledDate = _convertToLocalTimezone(
      payload.scheduledDateTime,
    );

    final tz.TZDateTime now = tz.TZDateTime.now(_local);

    final Duration difference = scheduledDate.difference(now);

    debugPrint('Fecha actual: $now');
    debugPrint('Fecha programada: $scheduledDate');
    debugPrint('Segundos restantes: ${difference.inSeconds}');

    if (!scheduledDate.isAfter(now)) {
      throw ArgumentError(
        'La fecha programada debe ser posterior '
        'a la fecha actual.',
      );
    }

    if (difference.inSeconds < 10) {
      throw ArgumentError(
        'El recordatorio debe programarse al menos '
        '10 segundos después de la hora actual.',
      );
    }

    final String notificationPayload = jsonEncode(payload.toJson());

    final NotificationDetails notificationDetails = _buildNotificationDetails(
      ticker: 'Es hora de tomar ${payload.medicationName}',
    );

    debugPrint("======================================");
    debugPrint("PROGRAMANDO MEDICAMENTO");
    debugPrint("Medicamento: ${payload.medicationName}");
    debugPrint("Hora: $scheduledDate");
    debugPrint("Notification ID: ${payload.notificationId}");
    debugPrint("======================================");

    await flutterLocalNotificationsPlugin.zonedSchedule(
      payload.notificationId,
      'Hora de tomar tu medicamento',
      '${payload.medicationName} - ${payload.dose}',
      scheduledDate,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: notificationPayload,
    );

    debugPrint('Notificación programada correctamente.');

    debugPrint('Notification ID: ${payload.notificationId}');

    debugPrint('Medicamento: ${payload.medicationName}');

    debugPrint(
      'Medication log ID: '
      '${payload.medicationLogId}',
    );

    debugPrint('Hora programada: $scheduledDate');

    final List<PendingNotificationRequest> pending =
        await getPendingNotifications();

    debugPrint(
      'Total de notificaciones pendientes: '
      '${pending.length}',
    );
  }

  // =========================================================
  // CANCELAR UNA NOTIFICACIÓN
  // =========================================================

  Future<void> cancelNotification(int notificationId) async {
    await _ensureInitialized();

    await flutterLocalNotificationsPlugin.cancel(notificationId);

    debugPrint('Notificación cancelada: $notificationId');
  }

  // =========================================================
  // CANCELAR TODAS LAS NOTIFICACIONES
  // =========================================================

  Future<void> cancelAllNotifications() async {
    await _ensureInitialized();

    await flutterLocalNotificationsPlugin.cancelAll();

    debugPrint('Todas las notificaciones fueron canceladas.');
  }

  // =========================================================
  // OBTENER NOTIFICACIONES PENDIENTES
  // =========================================================

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    await _ensureInitialized();

    return flutterLocalNotificationsPlugin.pendingNotificationRequests();
  }

  // =========================================================
  // CONVERTIR FECHA A ZONA HORARIA LOCAL
  // =========================================================

  tz.TZDateTime _convertToLocalTimezone(DateTime dateTime) {
    if (dateTime.isUtc) {
      return tz.TZDateTime.from(dateTime, _local);
    }

    return tz.TZDateTime(
      _local,
      dateTime.year,
      dateTime.month,
      dateTime.day,
      dateTime.hour,
      dateTime.minute,
      dateTime.second,
    );
  }

  // =========================================================
  // VERIFICAR INICIALIZACIÓN
  // =========================================================

  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await initialize();
    }
  }

  // =========================================================
  // IDENTIFICAR NOTIFICACIONES DE PRUEBA
  // =========================================================

  static bool _isTestPayload(String? encodedPayload) {
    if (encodedPayload == null || encodedPayload.trim().isEmpty) {
      return false;
    }

    try {
      final dynamic decoded = jsonDecode(encodedPayload);

      if (decoded is! Map<String, dynamic>) {
        return false;
      }

      final String type = decoded['type']?.toString() ?? '';

      return type == 'test' || type == 'scheduled_test';
    } catch (_) {
      return false;
    }
  } // =========================================================
  // TOCAR NOTIFICACIÓN
  // =========================================================

  static void _onNotificationResponse(NotificationResponse response) {
    debugPrint('Notificación presionada.');

    debugPrint('ID de notificación: ${response.id}');

    debugPrint('Payload: ${response.payload}');

    unawaited(_processNotificationResponse(response));
  }

  static Future<void> _processNotificationResponse(
    NotificationResponse response,
  ) async {
    try {
      if (_isTestPayload(response.payload)) {
        debugPrint('Se presionó una notificación de prueba.');
        return;
      }

      await NavigationService.waitUntilAppReady();

      await AlarmReceiver.instance.handlePayload(response.payload);

      final int? notificationId = response.id;

      if (notificationId != null) {
        await NotificationService.instance.cancelNotification(notificationId);
      }
    } catch (error, stackTrace) {
      debugPrint('Error procesando la notificación: $error');

      debugPrintStack(stackTrace: stackTrace);
    }
  }

  // =========================================================
  // APP ABIERTA DESDE UNA NOTIFICACIÓN
  // =========================================================

  Future<void> handleInitialNotification() async {
    await _ensureInitialized();

    try {
      final NotificationAppLaunchDetails? launchDetails =
          await flutterLocalNotificationsPlugin
              .getNotificationAppLaunchDetails();

      if (launchDetails == null ||
          launchDetails.didNotificationLaunchApp != true) {
        debugPrint(
          'La aplicación no fue abierta '
          'desde una notificación.',
        );
        return;
      }

      final NotificationResponse? response = launchDetails.notificationResponse;

      if (response == null) {
        debugPrint(
          'No se encontró una respuesta '
          'de notificación inicial.',
        );
        return;
      }

      debugPrint(
        'La aplicación fue abierta '
        'desde una notificación.',
      );

      debugPrint('ID inicial: ${response.id}');

      debugPrint('Payload inicial: ${response.payload}');

      if (_isTestPayload(response.payload)) {
        debugPrint(
          'La aplicación fue abierta '
          'desde una notificación de prueba.',
        );
        return;
      }

      await NavigationService.waitUntilAppReady();

      await AlarmReceiver.instance.handlePayload(response.payload);

      final int? notificationId = response.id;

      if (notificationId != null) {
        await cancelNotification(notificationId);
      }
    } catch (error, stackTrace) {
      debugPrint(
        'Error procesando la notificación inicial: '
        '$error',
      );

      debugPrintStack(stackTrace: stackTrace);
    }
  }
}

// ===========================================================
// RESPUESTA CUANDO SE TOCA EN SEGUNDO PLANO
// ===========================================================

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  debugPrint('Notificación presionada en segundo plano.');

  debugPrint('ID de notificación: ${response.id}');

  debugPrint('Payload: ${response.payload}');
}
