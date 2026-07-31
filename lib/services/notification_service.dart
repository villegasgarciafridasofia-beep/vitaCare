import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/alarm_payload.dart';
import '../views/medications/medication_alarm_view.dart';
import 'AlarmService/alarm_receiver.dart';
import 'medication_log_service.dart';
import 'navigation_service.dart';
import 'notification_history_service.dart';
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final MedicationLogService _logService = MedicationLogService();
  final NotificationHistoryService _historyService =
  NotificationHistoryService();
  tz.Location _local = tz.UTC;
  bool _initialized = false;

  bool _recoveringActiveAlarm = false;
  int? _lastOpenedNotificationId;

  static const String medicationChannelId = 'medication_alarm_full_screen_v2';
  static const String medicationChannelName = 'Alarmas de medicamentos';
  static const String medicationChannelDescription =
      'Alarmas y recordatorios importantes para tomar medicamentos';

  static const String actionMedicationTaken = 'MEDICATION_TAKEN';
  static const Duration unattendedDelay = Duration(minutes: 2);

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

      debugPrint('Plugin de notificaciones inicializado: $initialized');

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

  Future<void> _configureTimezone() async {
    tz.initializeTimeZones();

    try {
      final TimezoneInfo timezoneInfo =
          await FlutterTimezone.getLocalTimezone();

      _local = tz.getLocation(timezoneInfo.identifier);
      tz.setLocalLocation(_local);

      debugPrint('Zona horaria configurada: ${timezoneInfo.identifier}');
    } catch (error) {
      _local = tz.UTC;
      tz.setLocalLocation(tz.UTC);

      debugPrint('No fue posible detectar la zona horaria: $error');
      debugPrint('Se utilizará UTC temporalmente.');
    }
  }

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
      debugPrint('No se encontró el plugin de notificaciones de Android.');
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

    debugPrint('Canal de alarma creado: $medicationChannelId');
  }

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
      return;
    }

    try {
      final bool? notificationsGranted = await androidPlugin
          .requestNotificationsPermission();

      debugPrint('Permiso de notificaciones: $notificationsGranted');

      final bool? canScheduleExact = await androidPlugin
          .canScheduleExactNotifications();

      debugPrint('Puede programar alarmas exactas: $canScheduleExact');

      if (canScheduleExact != true) {
        final bool? exactAlarmGranted = await androidPlugin
            .requestExactAlarmsPermission();

        debugPrint('Permiso de alarmas exactas: $exactAlarmGranted');
      }

      final bool? fullScreenGranted = await androidPlugin
          .requestFullScreenIntentPermission();

      debugPrint('Permiso de pantalla completa: $fullScreenGranted');
    } catch (error, stackTrace) {
      debugPrint('Error solicitando permisos: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  NotificationDetails _buildMedicationDetails({
    required String ticker,
    required bool openFullScreen,
    required bool playAlarmSound,
  }) {
    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          medicationChannelId,
          medicationChannelName,
          channelDescription: medicationChannelDescription,
          importance: Importance.max,
          priority: Priority.max,
          playSound: playAlarmSound,
          sound: playAlarmSound
              ? const RawResourceAndroidNotificationSound('medication_alarm')
              : null,
          enableVibration: true,
          category: AndroidNotificationCategory.alarm,
          visibility: NotificationVisibility.public,
          fullScreenIntent: openFullScreen,
          autoCancel: false,
          ongoing: true,
          audioAttributesUsage: AudioAttributesUsage.alarm,
          ticker: ticker,
          actions: const <AndroidNotificationAction>[
            AndroidNotificationAction(
              actionMedicationTaken,
              'Ya me lo tomé',
              showsUserInterface: true,
              cancelNotification: false,
            ),
          ],
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    return NotificationDetails(android: androidDetails, iOS: iosDetails);
  }

  NotificationDetails _buildTestNotificationDetails({required String ticker}) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        medicationChannelId,
        medicationChannelName,
        channelDescription: medicationChannelDescription,
        importance: Importance.max,
        priority: Priority.max,
        playSound: true,
        sound: const RawResourceAndroidNotificationSound('medication_alarm'),
        enableVibration: true,
        ticker: ticker,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  Future<void> showTestNotification() async {
    await _ensureInitialized();

    const String title = 'Prueba de VitaCare AI';
    const String body = 'Las notificaciones funcionan correctamente';

    await flutterLocalNotificationsPlugin.show(
      999,
      title,
      body,
      _buildTestNotificationDetails(
        ticker: 'Prueba de notificación de VitaCare AI',
      ),
      payload: jsonEncode(<String, dynamic>{
        'type': 'test',
      }),
    );

    debugPrint('Notificación inmediata enviada.');
  }
  Future<void> scheduleOneMinuteTest() async {
    await _ensureInitialized();

    final tz.TZDateTime scheduledDate = tz.TZDateTime.now(
      _local,
    ).add(const Duration(minutes: 1));

    await flutterLocalNotificationsPlugin.zonedSchedule(
      999998,
      'Prueba programada de VitaCare AI',
      'Esta alarma fue programada hace un minuto.',
      scheduledDate,
      _buildTestNotificationDetails(ticker: 'Prueba programada de VitaCare AI'),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: jsonEncode(<String, dynamic>{'type': 'scheduled_test'}),
    );

    debugPrint('Prueba programada para: $scheduledDate');
  }

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
        'La fecha programada debe ser posterior a la fecha actual.',
      );
    }

    if (difference.inSeconds < 10) {
      throw ArgumentError(
        'El recordatorio debe programarse al menos '
        '10 segundos después de la hora actual.',
      );
    }

    final String encodedPayload = jsonEncode(payload.toJson());

    const String title = 'Hora de tomar tu medicamento';
    final String body = '${payload.medicationName} - ${payload.dose}';

    await _historyService.saveScheduledMedicationNotification(
      payload: payload,
      title: title,
      body: body,
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
      payload.notificationId,
      title,
      body,
      scheduledDate,
      _buildMedicationDetails(
        ticker: 'Es hora de tomar ${payload.medicationName}',
        openFullScreen: true,
        playAlarmSound: true,
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: encodedPayload,
    );

    final int followUpId = followUpNotificationId(payload.notificationId);

    final tz.TZDateTime followUpDate = scheduledDate.add(unattendedDelay);

    await flutterLocalNotificationsPlugin.zonedSchedule(
      followUpId,
      '¿Ya tomaste tu medicamento?',
      '${payload.medicationName} - ${payload.dose}',
      followUpDate,
      _buildMedicationDetails(
        ticker: 'Confirma si tomaste ${payload.medicationName}',
        openFullScreen: false,
        playAlarmSound: true,
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: encodedPayload,
    );

    debugPrint('Alarma principal programada: ${payload.notificationId}');
    debugPrint('Seguimiento programado: $followUpId para $followUpDate');

    final List<PendingNotificationRequest> pending =
        await getPendingNotifications();

    debugPrint('Total de notificaciones pendientes: ${pending.length}');
  }

  static int followUpNotificationId(int notificationId) {
    return notificationId ^ 0x40000000;
  }

  Future<void> cancelMedicationNotifications({
    required AlarmPayload payload,
  }) async {
    await cancelNotification(payload.notificationId);
    await cancelNotification(followUpNotificationId(payload.notificationId));
  }

  Future<void> cancelNotification(int notificationId) async {
    await _ensureInitialized();

    await flutterLocalNotificationsPlugin.cancel(notificationId);

    debugPrint('Notificación cancelada: $notificationId');
  }

  Future<void> cancelAllNotifications() async {
    await _ensureInitialized();

    await flutterLocalNotificationsPlugin.cancelAll();

    debugPrint('Todas las notificaciones fueron canceladas.');
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    await _ensureInitialized();

    return flutterLocalNotificationsPlugin.pendingNotificationRequests();
  }

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

  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await initialize();
    }
  }

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
  }

  AlarmPayload? _decodeAlarmPayload(String? encodedPayload) {
    return AlarmReceiver.instance.decodePayload(encodedPayload);
  }

  static void _onNotificationResponse(NotificationResponse response) {
    debugPrint('Notificación presionada.');
    debugPrint('ID de notificación: ${response.id}');
    debugPrint('Acción: ${response.actionId}');
    debugPrint('Payload: ${response.payload}');

    unawaited(
      NotificationService.instance._processNotificationResponse(response),
    );
  }

  Future<void> _processNotificationResponse(
    NotificationResponse response,
  ) async {
    try {
      if (_isTestPayload(response.payload)) {
        debugPrint('Se presionó una notificación de prueba.');
        return;
      }

      final AlarmPayload? payload = _decodeAlarmPayload(response.payload);

      if (payload == null) {
        return;
      }

      await _historyService.markOpened(
        patientUid: payload.patientUid,
        notificationId: payload.notificationId,
      );

      await NavigationService.waitUntilAppReady();
      _lastOpenedNotificationId =
          payload.notificationId;
      if (response.actionId == actionMedicationTaken) {
        await _registerTakenFromNotification(payload: payload);
        return;
      }

      final MedicationAlarmResult? result = await AlarmReceiver.instance
          .handlePayload(response.payload);

      if (result != null) {
        await cancelMedicationNotifications(payload: payload);
      }
    } catch (error, stackTrace) {
      debugPrint('Error procesando la notificación: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _registerTakenFromNotification({
    required AlarmPayload payload,
  }) async {
    debugPrint('Registrando medicamento como tomado desde la notificación.');

    await _logService.markAsTaken(logId: payload.medicationLogId);

    await _historyService.markAction(
      patientUid: payload.patientUid,
      notificationId: payload.notificationId,
      action: 'taken',
    );

    await cancelMedicationNotifications(payload: payload);

    debugPrint(
      '${payload.medicationName} fue registrado '
      'como tomado desde la notificación.',
    );
  }
  Future<void> recoverActiveMedicationAlarm() async {
    if (kIsWeb || _recoveringActiveAlarm) {
      return;
    }

    _recoveringActiveAlarm = true;

    try {
      await _ensureInitialized();
      await NavigationService.waitUntilAppReady();

      final List<ActiveNotification> activeNotifications =
      await flutterLocalNotificationsPlugin
          .getActiveNotifications();

      debugPrint(
        'Notificaciones activas encontradas: '
            '${activeNotifications.length}',
      );

      for (final ActiveNotification notification
      in activeNotifications.reversed) {
        final String? encodedPayload = notification.payload;

        if (encodedPayload == null ||
            encodedPayload.trim().isEmpty) {
          continue;
        }

        if (_isTestPayload(encodedPayload)) {
          continue;
        }

        final AlarmPayload? payload =
        _decodeAlarmPayload(encodedPayload);

        if (payload == null) {
          continue;
        }

        if (_lastOpenedNotificationId ==
            payload.notificationId) {
          debugPrint(
            'La alarma ${payload.notificationId} '
                'ya fue abierta.',
          );
          return;
        }

        _lastOpenedNotificationId =
            payload.notificationId;

        debugPrint(
          'Recuperando alarma activa: '
              '${payload.medicationName}',
        );

        final MedicationAlarmResult? result =
        await AlarmReceiver.instance.handlePayload(
          encodedPayload,
        );

        if (result != null) {
          await cancelMedicationNotifications(
            payload: payload,
          );
        }

        return;
      }
    } catch (error, stackTrace) {
      debugPrint(
        'Error recuperando la alarma activa: $error',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );
    } finally {
      _recoveringActiveAlarm = false;
    }
  }
  Future<void> handleInitialNotification() async {
    await _ensureInitialized();

    try {
      final NotificationAppLaunchDetails? launchDetails =
          await flutterLocalNotificationsPlugin
              .getNotificationAppLaunchDetails();

      if (launchDetails == null ||
          launchDetails.didNotificationLaunchApp != true) {
        debugPrint(
          'La aplicación no fue abierta desde una notificación.',
        );

        await recoverActiveMedicationAlarm();

        return;
      }

      final NotificationResponse? response = launchDetails.notificationResponse;

      if (response == null) {
        return;
      }

      debugPrint('La aplicación fue abierta desde una notificación.');

      await _processNotificationResponse(response);
    } catch (error, stackTrace) {
      debugPrint('Error procesando la notificación inicial: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }
}

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  debugPrint('Acción recibida en segundo plano: ${response.actionId}');

  // La acción abre la app para registrar la toma con Firebase inicializado.
}
