import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../models/alarm_payload.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance =
  NotificationService._();

  final FlutterLocalNotificationsPlugin
  flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  tz.Location _local = tz.UTC;

  bool _initialized = false;

  static const String medicationChannelId =
      'medication_channel';

  static const String medicationChannelName =
      'Recordatorios de medicamentos';

  static const String medicationChannelDescription =
      'Alertas para recordar la toma de medicamentos';

  /// Inicializa el servicio de notificaciones.
  Future<void> initialize() async {
    if (_initialized) {
      debugPrint(
        'NotificationService ya estaba inicializado.',
      );
      return;
    }

    try {
      await _configureTimezone();

      const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );

      const DarwinInitializationSettings iosSettings =
      DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initializationSettings =
      InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      final bool? initialized =
      await flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse:
        _onNotificationResponse,
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

      debugPrint(
        'NotificationService inicializado correctamente.',
      );
    } catch (error, stackTrace) {
      debugPrint(
        'Error inicializando NotificationService: $error',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      rethrow;
    }
  }

  /// Configura la zona horaria del teléfono.
  Future<void> _configureTimezone() async {
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
        'Zona horaria configurada: '
            '$timezoneIdentifier',
      );
    } catch (error) {
      _local = tz.UTC;

      tz.setLocalLocation(
        tz.UTC,
      );

      debugPrint(
        'No fue posible detectar la zona horaria: '
            '$error',
      );

      debugPrint(
        'Se utilizará UTC temporalmente.',
      );
    }
  }

  /// Crea el canal de recordatorios en Android.
  Future<void> _createAndroidNotificationChannel() async {
    if (kIsWeb) {
      return;
    }

    final AndroidFlutterLocalNotificationsPlugin?
    androidPlugin =
    flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin == null) {
      debugPrint(
        'No se encontró el plugin de Android.',
      );
      return;
    }

    const AndroidNotificationChannel channel =
    AndroidNotificationChannel(
      medicationChannelId,
      medicationChannelName,
      description: medicationChannelDescription,
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    await androidPlugin.createNotificationChannel(
      channel,
    );

    debugPrint(
      'Canal de notificaciones creado correctamente.',
    );
  }

  /// Solicita los permisos necesarios en Android.
  Future<void> requestPermissions() async {
    if (kIsWeb ||
        defaultTargetPlatform != TargetPlatform.android) {
      return;
    }

    final AndroidFlutterLocalNotificationsPlugin?
    androidPlugin =
    flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin == null) {
      debugPrint(
        'No se encontró la implementación de Android.',
      );
      return;
    }

    final bool? notificationsGranted =
    await androidPlugin
        .requestNotificationsPermission();

    debugPrint(
      'Permiso de notificaciones: '
          '$notificationsGranted',
    );

    try {
      final bool? exactAlarmsGranted =
      await androidPlugin
          .requestExactAlarmsPermission();

      debugPrint(
        'Permiso de alarmas exactas: '
            '$exactAlarmsGranted',
      );
    } catch (error) {
      debugPrint(
        'No se pudo solicitar el permiso de '
            'alarmas exactas: $error',
      );
    }
  }

  /// Muestra una notificación inmediata de prueba.
  Future<void> showTestNotification() async {
    await _ensureInitialized();

    const AndroidNotificationDetails androidDetails =
    AndroidNotificationDetails(
      medicationChannelId,
      medicationChannelName,
      channelDescription:
      medicationChannelDescription,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      fullScreenIntent: true,

      // Se quita al tocarla.
      autoCancel: true,

      // No permanece fija en el panel.
      ongoing: false,

      ticker:
      'Prueba de notificación de VitaCare AI',
    );

    const DarwinNotificationDetails iosDetails =
    DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details =
    NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      999,
      'Prueba de VitaCare AI',
      'Las notificaciones funcionan correctamente',
      details,
      payload: jsonEncode(
        <String, dynamic>{
          'type': 'test',
        },
      ),
    );

    debugPrint(
      'Notificación inmediata enviada.',
    );
  }

  /// Programa una notificación de medicamento.
  Future<void> scheduleMedicationNotification({
    required AlarmPayload payload,
  }) async {
    await _ensureInitialized();

    final tz.TZDateTime scheduledDate =
    _convertToLocalTimezone(
      payload.scheduledDateTime,
    );

    final tz.TZDateTime now =
    tz.TZDateTime.now(_local);

    final Duration difference =
    scheduledDate.difference(now);

    debugPrint(
      'Fecha actual: $now',
    );

    debugPrint(
      'Fecha programada: $scheduledDate',
    );

    debugPrint(
      'Segundos restantes: '
          '${difference.inSeconds}',
    );

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

    final String notificationPayload =
    jsonEncode(
      payload.toJson(),
    );

    final AndroidNotificationDetails androidDetails =
    AndroidNotificationDetails(
      medicationChannelId,
      medicationChannelName,
      channelDescription:
      medicationChannelDescription,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      fullScreenIntent: true,

      // Desaparece cuando el usuario la toca.
      autoCancel: true,

      // Permite retirarla del panel.
      ongoing: false,

      ticker:
      'Es hora de tomar ${payload.medicationName}',
    );

    const DarwinNotificationDetails iosDetails =
    DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails notificationDetails =
    NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
      payload.notificationId,
      'Hora de tomar tu medicamento',
      '${payload.medicationName} - '
          '${payload.dose}',
      scheduledDate,
      notificationDetails,
      androidScheduleMode:
      AndroidScheduleMode.exactAllowWhileIdle,
      payload: notificationPayload,
    );

    debugPrint(
      'Notificación programada correctamente.',
    );

    debugPrint(
      'Notification ID: '
          '${payload.notificationId}',
    );

    debugPrint(
      'Medicamento: '
          '${payload.medicationName}',
    );

    debugPrint(
      'Hora programada: $scheduledDate',
    );
  }

  /// Cancela una notificación por su ID.
  Future<void> cancelNotification(
      int notificationId,
      ) async {
    await flutterLocalNotificationsPlugin.cancel(
      notificationId,
    );

    debugPrint(
      'Notificación cancelada: '
          '$notificationId',
    );
  }

  /// Cancela todas las notificaciones.
  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin
        .cancelAll();

    debugPrint(
      'Todas las notificaciones fueron canceladas.',
    );
  }

  /// Obtiene las notificaciones programadas.
  Future<List<PendingNotificationRequest>>
  getPendingNotifications() async {
    return flutterLocalNotificationsPlugin
        .pendingNotificationRequests();
  }

  /// Convierte una fecha normal a la zona horaria
  /// configurada en el dispositivo.
  tz.TZDateTime _convertToLocalTimezone(
      DateTime dateTime,
      ) {
    if (dateTime.isUtc) {
      return tz.TZDateTime.from(
        dateTime,
        _local,
      );
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

  /// Verifica que el servicio esté inicializado.
  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await initialize();
    }
  }

  /// Se ejecuta cuando el usuario toca una notificación
  /// con la aplicación abierta o en segundo plano.
  static void _onNotificationResponse(
      NotificationResponse response,
      ) {
    debugPrint(
      'Notificación presionada.',
    );

    debugPrint(
      'ID de notificación: ${response.id}',
    );

    debugPrint(
      'Payload: ${response.payload}',
    );

    final int? notificationId = response.id;

    if (notificationId != null) {
      unawaited(
        NotificationService.instance
            .cancelNotification(notificationId),
      );
    }

    /*
      Aquí puedes enviar el payload a AlarmReceiver
      para abrir MedicationAlarmView.

      Por ahora, la notificación se elimina correctamente
      del panel cuando el usuario la toca.
    */
  }
}

/// Esta función debe estar fuera de la clase.
///
/// Se ejecuta cuando el usuario toca una notificación
/// mientras la aplicación está cerrada o en segundo plano.
@pragma('vm:entry-point')
void notificationTapBackground(
    NotificationResponse response,
    ) {
  debugPrint(
    'Notificación presionada en segundo plano.',
  );

  debugPrint(
    'ID de notificación: ${response.id}',
  );

  debugPrint(
    'Payload: ${response.payload}',
  );
}