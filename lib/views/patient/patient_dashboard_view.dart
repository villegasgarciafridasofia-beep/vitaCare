import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../models/notification_history_model.dart';
import '../../services/auth_service.dart';
import '../../services/notification_history_service.dart';
import '../../models/medication_log_model.dart';
import '../../models/medication_model.dart';
import '../../models/user_model.dart';
import '../../routes/app_routes.dart';
import '../../services/firestore_service.dart';
import '../../services/medication_log_service.dart';
import '../../services/medication_service.dart';
import '../medications/medications_view.dart';
import 'my_caregivers_view.dart';
import 'location_view.dart';
import 'personal_information_view.dart';
import 'routine_daily_view.dart';
import 'settings_view.dart';

class PatientDashboardView extends StatefulWidget {
  const PatientDashboardView({super.key});

  @override
  State<PatientDashboardView> createState() => _PatientDashboardViewState();
}

class _PatientDashboardViewState extends State<PatientDashboardView> {
  static const Color primaryDark = Color(0xFF285F50);
  static const Color primary = Color(0xFF3E806B);
  static const Color primaryLight = Color(0xFFE4F1EA);
  static const Color background = Color(0xFFF4F8F5);
  static const Color textDark = Color(0xFF24463E);
  static const Color textSoft = Color(0xFF64756E);
  static const Color borderColor = Color(0xFFE1EAE5);

  final FirestoreService _firestoreService = FirestoreService();
  final MedicationService _medicationService = MedicationService();
  final MedicationLogService _medicationLogService = MedicationLogService();
  final NotificationHistoryService _notificationHistoryService =
  NotificationHistoryService();

  List<NotificationHistoryModel> _notifications = [];

  int _selectedIndex = 0;
  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _isLoggingOut = false;
  String? _errorMessage;

  UserModel? _patient;
  List<MedicationModel> _medications = [];
  List<MedicationLogModel> _logs = [];
  List<_DoseItem> _todayDoses = [];

  final List<String> _titles = const [
    'Inicio',
    'Medicamentos',
    'Notificaciones',
    'Mi perfil',
  ];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: _buildAppBar(),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildHomeView(),
          const MedicationsView(),
          _buildNotificationsView(),
          _buildProfileView(),
        ],
      ),
      bottomNavigationBar: _buildNavigationBar(),
    );
  }

  Future<void> _loadDashboardData({bool refresh = false}) async {
    final User? authUser = FirebaseAuth.instance.currentUser;

    if (authUser == null) {
      if (!mounted) return;

      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.auth,
            (Route<dynamic> route) => false,
      );
      return;
    }

    setState(() {
      if (refresh) {
        _isRefreshing = true;
      } else {
        _isLoading = true;
      }
      _errorMessage = null;
    });

    try {
      final results = await Future.wait<dynamic>([
        _firestoreService.getUser(authUser.uid),
        _medicationService.getPatientMedications(authUser.uid),
        _medicationLogService.getPatientLogs(authUser.uid),
      ]);

      final UserModel? patient = results[0] as UserModel?;
      final List<MedicationModel> medications =
      results[1] as List<MedicationModel>;
      final List<MedicationLogModel> logs =
      results[2] as List<MedicationLogModel>;

      final List<MedicationModel> activeMedications = medications
          .where((medication) => _isMedicationActiveToday(medication))
          .toList();

      final List<_DoseItem> todayDoses = _buildTodayDoses(
        medications: activeMedications,
        logs: logs,
      );

      if (!mounted) return;

      setState(() {
        _patient = patient;
        _medications = activeMedications;
        _logs = logs;
        _todayDoses = todayDoses;
      });

      await _loadNotificationHistory(authUser.uid);
    } catch (error, stackTrace) {
      debugPrint('Error al cargar el dashboard: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      setState(() {
        _errorMessage =
        'No fue posible cargar la información. Revisa tu conexión.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    }
  }

  Future<void> _loadNotificationHistory(String patientUid) async {
    try {
      final List<NotificationHistoryModel> notifications =
          await _notificationHistoryService.getRecentNotifications(patientUid);

      if (!mounted) return;

      setState(() {
        _notifications = notifications.take(10).toList();
      });
    } catch (error, stackTrace) {
      // El historial no debe impedir que el dashboard cargue.
      debugPrint('No fue posible cargar el historial de notificaciones: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      setState(() {
        _notifications = [];
      });
    }
  }

  bool _isMedicationActiveToday(MedicationModel medication) {
    if (!medication.active) return false;

    final DateTime today = _dateOnly(DateTime.now());
    final DateTime startDate = _dateOnly(medication.startDate);
    final DateTime? endDate =
    medication.endDate == null ? null : _dateOnly(medication.endDate!);

    if (startDate.isAfter(today)) return false;
    if (endDate != null && endDate.isBefore(today)) return false;

    return true;
  }

  List<_DoseItem> _buildTodayDoses({
    required List<MedicationModel> medications,
    required List<MedicationLogModel> logs,
  }) {
    final DateTime now = DateTime.now();
    final List<MedicationLogModel> todayLogs = logs
        .where((log) => _isSameDay(log.scheduledDateTime, now))
        .toList();

    final Set<String> usedLogIds = <String>{};
    final List<_DoseItem> doses = [];

    for (final medication in medications) {
      for (final String rawTime in medication.times) {
        final DateTime? scheduledDateTime = _combineTodayWithTime(rawTime);

        if (scheduledDateTime == null) {
          continue;
        }

        MedicationLogModel? matchingLog;
        Duration? shortestDifference;

        for (final log in todayLogs) {
          if (usedLogIds.contains(log.id)) continue;
          if (log.medicationId != medication.id) continue;

          final Duration difference =
          log.scheduledDateTime.difference(scheduledDateTime).abs();

          if (difference <= const Duration(hours: 3) &&
              (shortestDifference == null ||
                  difference < shortestDifference)) {
            matchingLog = log;
            shortestDifference = difference;
          }
        }

        if (matchingLog != null) {
          usedLogIds.add(matchingLog.id);
        }

        doses.add(
          _DoseItem(
            medication: medication,
            scheduledDateTime:
            matchingLog?.scheduledDateTime ?? scheduledDateTime,
            log: matchingLog,
          ),
        );
      }
    }

    // Agrega registros que no coincidieron con un horario del medicamento.
    // Esto ayuda con dosis pospuestas o registros antiguos.
    for (final log in todayLogs) {
      if (usedLogIds.contains(log.id)) continue;

      final MedicationModel? medication = _findMedicationById(log.medicationId);

      if (medication != null) {
        doses.add(
          _DoseItem(
            medication: medication,
            scheduledDateTime: log.scheduledDateTime,
            log: log,
          ),
        );
      }
    }

    doses.sort(
          (a, b) => a.scheduledDateTime.compareTo(b.scheduledDateTime),
    );

    return doses
        .where((dose) => dose.status.toLowerCase() != 'cancelled')
        .toList();
  }

  MedicationModel? _findMedicationById(String medicationId) {
    for (final medication in _medications) {
      if (medication.id == medicationId) {
        return medication;
      }
    }
    return null;
  }

  int get _totalToday => _todayDoses.length;

  int get _takenToday => _todayDoses
      .where((dose) => dose.status.toLowerCase() == 'taken')
      .length;

  int get _missedToday => _todayDoses.where((dose) {
    final String status = dose.status.toLowerCase();
    return status == 'missed' || status == 'skipped';
  }).length;

  int get _pendingToday => _todayDoses.where((dose) {
    final String status = dose.status.toLowerCase();
    return status == 'pending' || status == 'snoozed';
  }).length;

  int get _unreadNotifications =>
      _notifications.where((notification) => !notification.isRead).length;

  double get _dailyProgress {
    if (_totalToday == 0) return 0;
    return (_takenToday / _totalToday).clamp(0.0, 1.0);
  }

  double get _weeklyProgress {
    final DateTime now = DateTime.now();
    final DateTime start =
    _dateOnly(now).subtract(const Duration(days: 6));

    final List<MedicationLogModel> evaluableLogs = _logs.where((log) {
      final String status = log.status.toLowerCase();
      final bool validStatus =
          status == 'taken' || status == 'missed' || status == 'skipped';

      return validStatus &&
          !log.scheduledDateTime.isBefore(start) &&
          !log.scheduledDateTime.isAfter(now);
    }).toList();

    if (evaluableLogs.isEmpty) return 0;

    final int taken = evaluableLogs
        .where((log) => log.status.toLowerCase() == 'taken')
        .length;

    return (taken / evaluableLogs.length).clamp(0.0, 1.0);
  }

  _DoseItem? get _nextDose {
    final DateTime now = DateTime.now();

    for (final dose in _todayDoses) {
      final String status = dose.status.toLowerCase();
      final bool stillPending = status == 'pending' || status == 'snoozed';

      if (stillPending && dose.scheduledDateTime.isAfter(now)) {
        return dose;
      }
    }

    for (final dose in _todayDoses) {
      final String status = dose.status.toLowerCase();
      if (status == 'pending' || status == 'snoozed') {
        return dose;
      }
    }

    return null;
  }

  List<MedicationLogModel> get _recentLogs {
    final List<MedicationLogModel> logs = List.of(_logs);

    logs.sort((a, b) {
      final DateTime aDate = a.confirmedAt ?? a.updatedAt;
      final DateTime bDate = b.confirmedAt ?? b.updatedAt;
      return bDate.compareTo(aDate);
    });

    return logs.take(5).toList();
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      centerTitle: false,
      backgroundColor: Colors.white,
      foregroundColor: textDark,
      surfaceTintColor: Colors.white,
      titleSpacing: 20,
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: primaryLight,
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.health_and_safety_rounded,
              color: primaryDark,
              size: 24,
            ),
          ),
          const SizedBox(width: 11),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'VitaCare AI',
                style: TextStyle(
                  color: textDark,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                _titles[_selectedIndex],
                style: const TextStyle(
                  color: textSoft,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Actualizar',
          onPressed: _isRefreshing
              ? null
              : () => _loadDashboardData(refresh: true),
          icon: _isRefreshing
              ? const SizedBox(
            width: 21,
            height: 21,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
              : const Icon(Icons.refresh_rounded),
        ),
        IconButton(
          tooltip: 'Notificaciones',
          onPressed: () {
            setState(() => _selectedIndex = 2);
          },
          icon: Badge(
            isLabelVisible: _unreadNotifications > 0,
            label: Text(
              _unreadNotifications > 9
                  ? '9+'
                  : '$_unreadNotifications',
              style: const TextStyle(fontSize: 10),
            ),
            backgroundColor: const Color(0xFFE15C5C),
            child: Icon(
              _selectedIndex == 2
                  ? Icons.notifications_rounded
                  : Icons.notifications_none_rounded,
              color: primaryDark,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 14),
          child: InkWell(
            borderRadius: BorderRadius.circular(30),
            onTap: () {
              setState(() => _selectedIndex = 3);
            },
            child: CircleAvatar(
              radius: 19,
              backgroundColor: primaryDark,
              backgroundImage: _profileImageProvider,
              child: _profileImageProvider == null
                  ? Text(
                _getUserInitial(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              )
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationBar() {
    return NavigationBar(
      selectedIndex: _selectedIndex,
      height: 72,
      backgroundColor: Colors.white,
      indicatorColor: primaryLight,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      onDestinationSelected: (int index) {
        setState(() => _selectedIndex = index);

        if (index == 0) {
          _loadDashboardData(refresh: true);
        }
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded, color: primaryDark),
          label: 'Inicio',
        ),
        NavigationDestination(
          icon: Icon(Icons.medication_outlined),
          selectedIcon: Icon(Icons.medication_rounded, color: primaryDark),
          label: 'Medicinas',
        ),
        NavigationDestination(
          icon: Icon(Icons.notifications_none_rounded),
          selectedIcon: Icon(Icons.notifications_rounded, color: primaryDark),
          label: 'Avisos',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline_rounded),
          selectedIcon: Icon(Icons.person_rounded, color: primaryDark),
          label: 'Perfil',
        ),
      ],
    );
  }

  Widget _buildHomeView() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: primaryDark),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    return SafeArea(
      top: false,
      child: RefreshIndicator(
        color: primaryDark,
        onRefresh: () => _loadDashboardData(refresh: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
          children: [
            _buildWelcomeCard(),
            const SizedBox(height: 20),
            _buildDailyStats(),
            const SizedBox(height: 20),
            _buildNextMedicationCard(),
            const SizedBox(height: 24),
            _buildSectionHeader(
              title: 'Accesos rápidos',
              actionText: 'Actualizar',
              onTap: () => _loadDashboardData(refresh: true),
            ),
            const SizedBox(height: 14),
            _buildQuickAccessGrid(),
            const SizedBox(height: 24),
            _buildSectionHeader(
              title: 'Actividad reciente',
              actionText: 'Ver avisos',
              onTap: () {
                setState(() => _selectedIndex = 2);
              },
            ),
            const SizedBox(height: 14),
            _buildRecentActivity(),
            const SizedBox(height: 24),
            _buildAiInsightCard(),
            const SizedBox(height: 24),
            _buildWeeklyProgressCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return RefreshIndicator(
      color: primaryDark,
      onRefresh: () => _loadDashboardData(refresh: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 100),
          const Icon(
            Icons.cloud_off_rounded,
            size: 70,
            color: textSoft,
          ),
          const SizedBox(height: 18),
          Text(
            _errorMessage ?? 'Ocurrió un error inesperado.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: textDark,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: _loadDashboardData,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Intentar nuevamente'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryDark,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard() {
    final int dailyPercent = (_dailyProgress * 100).round();

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF4B927B),
            Color(0xFF285F50),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: primaryDark.withOpacity(0.20),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${_getGreeting()}, ${_patient?.name.trim().isNotEmpty == true ? _patient!.name : _getDisplayName()}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.14),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.favorite_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _buildWelcomeMessage(),
            style: const TextStyle(
              color: Color(0xFFE6F3ED),
              fontSize: 14,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.13),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _HeroMetric(
                    icon: Icons.monitor_heart_rounded,
                    label: 'Cumplimiento de hoy',
                    value: '$dailyPercent%',
                  ),
                ),
                const SizedBox(
                  height: 38,
                  child: VerticalDivider(color: Color(0x55FFFFFF)),
                ),
                Expanded(
                  child: _HeroMetric(
                    icon: Icons.medication_rounded,
                    label: 'Tomados hoy',
                    value: '$_takenToday de $_totalToday',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _buildWelcomeMessage() {
    if (_totalToday == 0) {
      return 'No tienes dosis programadas para hoy.';
    }

    if (_pendingToday == 0 && _missedToday == 0) {
      return '¡Excelente! Has completado todos tus medicamentos de hoy.';
    }

    if (_missedToday > 0) {
      return 'Tienes $_missedToday dosis omitida${_missedToday == 1 ? '' : 's'} y $_pendingToday pendiente${_pendingToday == 1 ? '' : 's'}.';
    }

    return 'Tienes $_pendingToday medicamento${_pendingToday == 1 ? '' : 's'} pendiente${_pendingToday == 1 ? '' : 's'} para hoy.';
  }

  Widget _buildDailyStats() {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.medication_rounded,
            value: '$_totalToday',
            label: 'Dosis de hoy',
            background: primaryLight,
            iconColor: primaryDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.check_circle_rounded,
            value: '$_takenToday',
            label: 'Tomadas',
            background: const Color(0xFFE7F5E9),
            iconColor: const Color(0xFF43855A),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: _missedToday > 0
                ? Icons.warning_amber_rounded
                : Icons.schedule_rounded,
            value: _missedToday > 0 ? '$_missedToday' : '$_pendingToday',
            label: _missedToday > 0 ? 'Omitidas' : 'Pendientes',
            background: _missedToday > 0
                ? const Color(0xFFFFE8E8)
                : const Color(0xFFFFF0DF),
            iconColor: _missedToday > 0
                ? const Color(0xFFB94747)
                : const Color(0xFFB66A2D),
          ),
        ),
      ],
    );
  }

  Widget _buildNextMedicationCard() {
    final _DoseItem? dose = _nextDose;

    if (dose == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: borderColor),
        ),
        child: const Row(
          children: [
            CircleAvatar(
              radius: 29,
              backgroundColor: Color(0xFFE7F5E9),
              child: Icon(
                Icons.task_alt_rounded,
                color: Color(0xFF43855A),
                size: 30,
              ),
            ),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sin dosis pendientes',
                    style: TextStyle(
                      color: textDark,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'No tienes otro medicamento pendiente para hoy.',
                    style: TextStyle(
                      color: textSoft,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final bool overdue = dose.scheduledDateTime.isBefore(DateTime.now());

    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Próximo medicamento',
                  style: TextStyle(
                    color: textDark,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: overdue
                      ? const Color(0xFFFFE8E8)
                      : const Color(0xFFFFF0DF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  overdue
                      ? 'Dosis atrasada'
                      : _remainingTime(dose.scheduledDateTime),
                  style: TextStyle(
                    color: overdue
                        ? const Color(0xFFB94747)
                        : const Color(0xFF9A5B25),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 17),
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: primaryLight,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.medication_rounded,
                  color: primaryDark,
                  size: 31,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dose.medication.name,
                      style: const TextStyle(
                        color: textDark,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${dose.medication.doseQuantity} ${dose.medication.doseUnit} · ${_formatDateTimeTime(dose.scheduledDateTime)}',
                      style: const TextStyle(
                        color: textSoft,
                        fontSize: 13,
                      ),
                    ),
                    if (dose.medication.instructions.trim().isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        dose.medication.instructions,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: textSoft,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Ver medicamentos',
                onPressed: () {
                  setState(() => _selectedIndex = 1);
                },
                icon: const Icon(
                  Icons.chevron_right_rounded,
                  color: primaryDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String actionText,
    required VoidCallback onTap,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: textDark,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        TextButton(
          onPressed: onTap,
          child: Text(
            actionText,
            style: const TextStyle(
              color: primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAccessGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,

      // Hace las tarjetas un poco más altas.
      childAspectRatio: 1.02,

      children: [
        _DashboardMenuCard(
          icon: Icons.medication_rounded,
          title: 'Medicamentos',
          subtitle: '${_medications.length} tratamientos activos',
          iconBackground: primaryLight,
          iconColor: primaryDark,
          onTap: () {
            setState(() => _selectedIndex = 1);
          },
        ),
        _DashboardMenuCard(
          icon: Icons.family_restroom_rounded,
          title: 'Familiares',
          subtitle:
          '${_patient?.caregivers.length ?? 0} cuidadores vinculados',
          iconBackground: const Color(0xFFF0EAF8),
          iconColor: const Color(0xFF73539B),
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const MyCaregiversView(),
              ),
            );

            if (mounted) {
              _loadDashboardData(refresh: true);
            }
          },
        ),
        _DashboardMenuCard(
          icon: Icons.location_on_rounded,
          title: 'Ubicación',
          subtitle: 'Zonas y monitoreo',
          iconBackground: const Color(0xFFFFEFE1),
          iconColor: const Color(0xFFB66A2D),
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const LocationView(),
              ),
            );
          },
        ),
        _DashboardMenuCard(
          icon: Icons.sos_rounded,
          title: 'Emergencia',
          subtitle: _patient?.emergencyContact.trim().isNotEmpty == true
              ? 'Contacto configurado'
              : 'Sin contacto registrado',
          iconBackground: const Color(0xFFFFE8E8),
          iconColor: const Color(0xFFB94747),
          onTap: () {
            _showComingSoon('Alerta de emergencia');
          },
        ),
      ],
    );
  }
  Widget _buildRecentActivity() {
    final List<MedicationLogModel> logs = _recentLogs.take(3).toList();

    if (logs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: borderColor),
        ),
        child: const Row(
          children: [
            Icon(
              Icons.history_rounded,
              color: textSoft,
              size: 30,
            ),
            SizedBox(width: 13),
            Expanded(
              child: Text(
                'Todavía no hay actividad registrada.',
                style: TextStyle(
                  color: textSoft,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          for (int index = 0; index < logs.length; index++) ...[
            _ActivityTile(
              icon: _statusIcon(logs[index].status),
              iconColor: _statusColor(logs[index].status),
              iconBackground:
              _statusColor(logs[index].status).withOpacity(0.12),
              title: logs[index].medicationName,
              subtitle: _statusText(logs[index]),
              trailing: _formatDateTimeTime(
                logs[index].confirmedAt ??
                    logs[index].scheduledDateTime,
              ),
            ),
            if (index < logs.length - 1)
              const Divider(
                height: 1,
                indent: 74,
                color: borderColor,
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildAiInsightCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFE6F3F3),
            Color(0xFFEAF5EF),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFCDE3DE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.smart_toy_rounded,
                  color: Color(0xFF31787A),
                  size: 27,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'VitaCare AI',
                      style: TextStyle(
                        color: textDark,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Resumen inteligente del día',
                      style: TextStyle(
                        color: textSoft,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _buildInsightMessage(),
            style: const TextStyle(
              color: textDark,
              fontSize: 14,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () =>
                  _showComingSoon('Asistente VitaCare AI'),
              icon: const Icon(Icons.chat_bubble_outline_rounded),
              label: const Text('Hablar con VitaCare AI'),
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryDark,
                side: const BorderSide(color: Color(0xFF9ECBC0)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _buildInsightMessage() {
    if (_totalToday == 0) {
      return 'No tienes medicamentos programados para hoy. '
          'Puedes revisar tus tratamientos activos desde la sección de medicamentos.';
    }

    if (_missedToday > 0) {
      return 'Detecté $_missedToday dosis omitida${_missedToday == 1 ? '' : 's'} hoy. '
          'Revisa tu tratamiento y comunícate con tu médico si tienes dudas.';
    }

    if (_pendingToday == 0) {
      return '¡Excelente trabajo! Completaste todas tus dosis programadas para hoy.';
    }

    final int percent = (_dailyProgress * 100).round();

    return 'Has completado el $percent% de tus dosis de hoy. '
        'Aún tienes $_pendingToday pendiente${_pendingToday == 1 ? '' : 's'}.';
  }

  Widget _buildWeeklyProgressCard() {
    final int weeklyPercent = (_weeklyProgress * 100).round();

    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Cumplimiento semanal',
                  style: TextStyle(
                    color: textDark,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '$weeklyPercent%',
                style: const TextStyle(
                  color: primaryDark,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              minHeight: 11,
              value: _weeklyProgress,
              backgroundColor: primaryLight,
              valueColor:
              const AlwaysStoppedAnimation<Color>(primary),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _weeklyProgressMessage(weeklyPercent),
            style: const TextStyle(
              color: textSoft,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  String _weeklyProgressMessage(int percent) {
    if (percent == 0) {
      return 'Aún no hay suficientes registros para calcular tu progreso semanal.';
    }

    if (percent >= 90) {
      return 'Excelente constancia durante los últimos siete días.';
    }

    if (percent >= 70) {
      return 'Vas bien. Mantén tus horarios para seguir mejorando.';
    }

    return 'Tu cumplimiento puede mejorar. Revisa las dosis omitidas o atrasadas.';
  }

  Widget _buildNotificationsView() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: primaryDark),
      );
    }

    final List<MedicationLogModel> logs = _recentLogs;

    return SafeArea(
      top: false,
      child: RefreshIndicator(
        color: primaryDark,
        onRefresh: () => _loadDashboardData(refresh: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    decoration: const BoxDecoration(
                      color: primaryLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.notifications_active_rounded,
                      color: primaryDark,
                      size: 35,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Centro de notificaciones',
                    style: TextStyle(
                      color: textDark,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    'Tienes $_pendingToday dosis pendiente${_pendingToday == 1 ? '' : 's'} para hoy.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: textSoft,
                      fontSize: 14,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _NotificationSummaryItem(
                          icon: Icons.schedule_rounded,
                          value: '$_pendingToday',
                          label: 'Pendientes',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _NotificationSummaryItem(
                          icon: Icons.mark_email_unread_outlined,
                          value: '$_unreadNotifications',
                          label: 'Sin leer',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _NotificationSummaryItem(
                          icon: Icons.history_rounded,
                          value: '${_notifications.length}',
                          label: 'Recientes',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'Actividad registrada',
              style: TextStyle(
                color: textDark,
                fontSize: 19,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            if (logs.isEmpty)
              _buildEmptyLogs()
            else
              ...logs.map(
                    (log) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _NotificationCard(
                    icon: _statusIcon(log.status),
                    iconColor: _statusColor(log.status),
                    title: log.medicationName,
                    subtitle:
                    '${_statusText(log)} · ${_formatShortDate(log.scheduledDateTime)}',
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyLogs() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: borderColor),
      ),
      child: const Text(
        'Todavía no existen registros de medicamentos.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: textSoft,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildProfileView() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: primaryDark),
      );
    }

    final User? authUser = FirebaseAuth.instance.currentUser;
    final String email =
    _patient?.email.isNotEmpty == true
        ? _patient!.email
        : authUser?.email ?? 'Correo no disponible';

    return SafeArea(
      top: false,
      child: RefreshIndicator(
        color: primaryDark,
        onRefresh: () => _loadDashboardData(refresh: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: primaryLight,
                    backgroundImage: _profileImageProvider,
                    child: _profileImageProvider == null
                        ? Text(
                      _getUserInitial(),
                      style: const TextStyle(
                        color: primaryDark,
                        fontSize: 34,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                        : null,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    _fullName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: textDark,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    email,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: textSoft,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: _ProfileMetric(
                          value: '${_medications.length}',
                          label: 'Tratamientos',
                        ),
                      ),
                      const SizedBox(
                        height: 38,
                        child: VerticalDivider(color: borderColor),
                      ),
                      Expanded(
                        child: _ProfileMetric(
                          value:
                          '${_patient?.caregivers.length ?? 0}',
                          label: 'Cuidadores',
                        ),
                      ),
                      const SizedBox(
                        height: 38,
                        child: VerticalDivider(color: borderColor),
                      ),
                      Expanded(
                        child: _ProfileMetric(
                          value:
                          '${(_weeklyProgress * 100).round()}%',
                          label: 'Cumplimiento',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _ProfileOption(
              icon: Icons.person_outline_rounded,
              title: 'Información personal',
              subtitle: _patient?.phoneNumber.isNotEmpty == true
                  ? _patient!.phoneNumber
                  : 'Consulta y actualiza tus datos',
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PersonalInformationView(patient: _patient),
                  ),
                );

                if (mounted) {
                  _loadDashboardData(refresh: true);
                }
              },
            ),
            _ProfileOption(
              icon: Icons.family_restroom_rounded,
              title: 'Mis cuidadores',
              subtitle:
              '${_patient?.caregivers.length ?? 0} personas vinculadas',
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MyCaregiversView(),
                  ),
                );

                if (mounted) {
                  _loadDashboardData(refresh: true);
                }
              },
            ),
            _ProfileOption(
              icon: Icons.schedule_rounded,
              title: 'Rutina diaria',
              subtitle: _patient?.isRoutineConfigured == true
                  ? 'Rutina configurada'
                  : 'Rutina pendiente de configurar',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RoutineDailyView(patient: _patient),
                  ),
                );
              },
            ),
            _ProfileOption(
              icon: Icons.settings_outlined,
              title: 'Configuración',
              subtitle: 'Preferencias de la aplicación',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SettingsView(),
                  ),
                );
              },
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: OutlinedButton.icon(
                onPressed: _isLoggingOut ? null : _confirmLogout,
                icon: _isLoggingOut
                    ? const SizedBox(
                  width: 21,
                  height: 21,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.3,
                  ),
                )
                    : const Icon(Icons.logout_rounded),
                label: Text(
                  _isLoggingOut
                      ? 'Cerrando sesión...'
                      : 'Cerrar sesión',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFB94747),
                  side: const BorderSide(color: Color(0xFFEABBBB)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  ImageProvider<Object>? get _profileImageProvider {
    final String firestoreImage = _patient?.profileImage.trim() ?? '';

    if (firestoreImage.isNotEmpty) {
      return NetworkImage(firestoreImage);
    }

    final String firebaseImage =
        FirebaseAuth.instance.currentUser?.photoURL?.trim() ?? '';

    if (firebaseImage.isNotEmpty) {
      return NetworkImage(firebaseImage);
    }

    return null;
  }

  String get _fullName {
    final UserModel? patient = _patient;

    if (patient == null) {
      return _getDisplayName();
    }

    final String fullName = [
      patient.name,
      patient.paternalLastName,
      patient.maternalLastName,
    ].where((part) => part.trim().isNotEmpty).join(' ');

    return fullName.isEmpty ? _getDisplayName() : fullName;
  }

  String _emergencyContactLabel() {
    final String contact = _patient?.emergencyContact.trim() ?? '';

    if (contact.isEmpty) {
      return 'sin configurar';
    }

    return contact;
  }

  Future<void> _confirmLogout() async {
    final bool? shouldLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          icon: const CircleAvatar(
            radius: 28,
            backgroundColor: Color(0xFFFFE8E8),
            child: Icon(
              Icons.logout_rounded,
              color: Color(0xFFB94747),
            ),
          ),
          title: const Text(
            '¿Cerrar sesión?',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textDark,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: const Text(
            'Tendrás que iniciar sesión nuevamente para entrar a VitaCare AI.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textSoft,
              height: 1.4,
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB94747),
                foregroundColor: Colors.white,
              ),
              child: const Text('Cerrar sesión'),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true) {
      await _logout();
    }
  }

  Future<void> _logout() async {
    try {
      setState(() => _isLoggingOut = true);

      await AuthService().logout();

      if (!mounted) return;

      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.auth,
            (Route<dynamic> route) => false,
      );
    } catch (error, stackTrace) {
      debugPrint('Error al cerrar sesión: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      _showSnackBar(
        message: 'No fue posible cerrar la sesión.',
        icon: Icons.error_outline_rounded,
        backgroundColor: const Color(0xFFFFF1F1),
        foregroundColor: const Color(0xFF9B3434),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoggingOut = false);
      }
    }
  }

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  bool _isSameDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  DateTime? _combineTodayWithTime(String rawTime) {
    final _ParsedTime? parsed = _parseTime(rawTime);

    if (parsed == null) return null;

    final DateTime today = DateTime.now();

    return DateTime(
      today.year,
      today.month,
      today.day,
      parsed.hour,
      parsed.minute,
    );
  }

  _ParsedTime? _parseTime(String input) {
    String value = input.trim().toUpperCase();

    if (value.isEmpty) return null;

    final bool isPm = value.contains('PM');
    final bool isAm = value.contains('AM');

    value = value
        .replaceAll('A. M.', '')
        .replaceAll('P. M.', '')
        .replaceAll('AM', '')
        .replaceAll('PM', '')
        .trim();

    final List<String> parts = value.split(':');

    if (parts.isEmpty) return null;

    int? hour = int.tryParse(parts[0].trim());
    int minute = 0;

    if (parts.length > 1) {
      final String minuteText =
      parts[1].replaceAll(RegExp(r'[^0-9]'), '');
      minute = int.tryParse(minuteText) ?? 0;
    }

    if (hour == null || minute < 0 || minute > 59) {
      return null;
    }

    if (isPm && hour < 12) {
      hour += 12;
    }

    if (isAm && hour == 12) {
      hour = 0;
    }

    if (hour < 0 || hour > 23) {
      return null;
    }

    return _ParsedTime(hour: hour, minute: minute);
  }

  String _remainingTime(DateTime scheduledDateTime) {
    final Duration difference =
    scheduledDateTime.difference(DateTime.now());

    if (difference.isNegative) {
      return 'Ahora';
    }

    if (difference.inMinutes < 1) {
      return 'En menos de 1 min';
    }

    if (difference.inHours < 1) {
      return 'En ${difference.inMinutes} min';
    }

    final int hours = difference.inHours;
    final int minutes = difference.inMinutes.remainder(60);

    if (minutes == 0) {
      return 'En $hours h';
    }

    return 'En $hours h $minutes min';
  }

  String _formatDateTimeTime(DateTime dateTime) {
    final int hour = dateTime.hour;
    final int minute = dateTime.minute;
    final String period = hour >= 12 ? 'PM' : 'AM';
    final int displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);

    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }

  String _formatShortDate(DateTime dateTime) {
    final DateTime now = DateTime.now();

    if (_isSameDay(dateTime, now)) {
      return 'Hoy, ${_formatDateTimeTime(dateTime)}';
    }

    final DateTime yesterday =
    now.subtract(const Duration(days: 1));

    if (_isSameDay(dateTime, yesterday)) {
      return 'Ayer, ${_formatDateTimeTime(dateTime)}';
    }

    return '${dateTime.day.toString().padLeft(2, '0')}/'
        '${dateTime.month.toString().padLeft(2, '0')}/'
        '${dateTime.year}';
  }

  String _statusText(MedicationLogModel log) {
    switch (log.status.toLowerCase()) {
      case 'taken':
        return 'Medicamento tomado';
      case 'snoozed':
        return 'Recordatorio pospuesto ${log.snoozeCount} vez${log.snoozeCount == 1 ? '' : 'ces'}';
      case 'skipped':
        return 'Dosis omitida';
      case 'missed':
        return 'Dosis no tomada';
      case 'cancelled':
        return 'Recordatorio cancelado';
      case 'pending':
      default:
        return 'Dosis pendiente';
    }
  }

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'taken':
        return Icons.check_circle_rounded;
      case 'snoozed':
        return Icons.snooze_rounded;
      case 'skipped':
        return Icons.remove_circle_outline_rounded;
      case 'missed':
        return Icons.warning_amber_rounded;
      case 'cancelled':
        return Icons.cancel_outlined;
      case 'pending':
      default:
        return Icons.schedule_rounded;
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'taken':
        return const Color(0xFF43855A);
      case 'snoozed':
        return const Color(0xFF73539B);
      case 'skipped':
      case 'missed':
        return const Color(0xFFB94747);
      case 'cancelled':
        return const Color(0xFF71817A);
      case 'pending':
      default:
        return const Color(0xFFB66A2D);
    }
  }

  String _getGreeting() {
    final int hour = DateTime.now().hour;

    if (hour < 12) return 'Buenos días';
    if (hour < 19) return 'Buenas tardes';
    return 'Buenas noches';
  }

  String _getUserInitial() {
    final String source = _patient?.name.trim().isNotEmpty == true
        ? _patient!.name
        : _getDisplayName();

    return source.trim().isEmpty
        ? 'P'
        : source.trim().substring(0, 1).toUpperCase();
  }

  String _getDisplayName() {
    final User? user = FirebaseAuth.instance.currentUser;
    final String? displayName = user?.displayName?.trim();

    if (displayName != null && displayName.isNotEmpty) {
      return displayName.split(' ').first;
    }

    final String? email = user?.email;

    if (email != null && email.contains('@')) {
      final String emailName = email.split('@').first;

      if (emailName.isNotEmpty) {
        return emailName[0].toUpperCase() + emailName.substring(1);
      }
    }

    return 'Paciente';
  }

  void _showComingSoon(String feature) {
    _showSnackBar(
      message: '$feature estará disponible próximamente.',
      icon: Icons.construction_rounded,
      backgroundColor: const Color(0xFFFFF3E8),
      foregroundColor: const Color(0xFF8A571C),
    );
  }

  void _showSnackBar({
    required String message,
    required IconData icon,
    required Color backgroundColor,
    required Color foregroundColor,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: backgroundColor,
        elevation: 6,
        margin: const EdgeInsets.all(18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: Row(
          children: [
            Icon(icon, color: foregroundColor),
            const SizedBox(width: 11),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: foregroundColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DoseItem {
  final MedicationModel medication;
  final DateTime scheduledDateTime;
  final MedicationLogModel? log;

  const _DoseItem({
    required this.medication,
    required this.scheduledDateTime,
    required this.log,
  });

  String get status => log?.status ?? 'pending';
}

class _ParsedTime {
  final int hour;
  final int minute;

  const _ParsedTime({
    required this.hour,
    required this.minute,
  });
}

class _HeroMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _HeroMetric({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 22),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFFDCEFE8),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color background;
  final Color iconColor;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.background,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 15,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _PatientDashboardViewState.borderColor,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              color: _PatientDashboardViewState.textDark,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _PatientDashboardViewState.textSoft,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardMenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconBackground;
  final Color iconColor;
  final VoidCallback onTap;

  const _DashboardMenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconBackground,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: _PatientDashboardViewState.borderColor,
            ),
          ),
          child: LayoutBuilder(
            builder: (
                BuildContext context,
                BoxConstraints constraints,
                ) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: iconBackground,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(
                      icon,
                      color: iconColor,
                      size: 26,
                    ),
                  ),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color:
                          _PatientDashboardViewState.textDark,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color:
                          _PatientDashboardViewState.textSoft,
                          fontSize: 11.5,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}


class _ActivityTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String subtitle;
  final String trailing;

  const _ActivityTile({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 23),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _PatientDashboardViewState.textDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: _PatientDashboardViewState.textSoft,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            trailing,
            style: const TextStyle(
              color: _PatientDashboardViewState.textSoft,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationSummaryItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _NotificationSummaryItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Color(0xFFE4F1EA),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: Color(0xFF285F50),
            size: 22,
          ),
          const SizedBox(height: 7),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF24463E),
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF64756E),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  const _NotificationCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: _PatientDashboardViewState.borderColor,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _PatientDashboardViewState.textDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: _PatientDashboardViewState.textSoft,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileMetric extends StatelessWidget {
  final String value;
  final String label;

  const _ProfileMetric({
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: _PatientDashboardViewState.primaryDark,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _PatientDashboardViewState.textSoft,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

class _ProfileOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ProfileOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 11),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(
          color: _PatientDashboardViewState.borderColor,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 6,
        ),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFE4F1EA),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: const Color(0xFF285F50)),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: _PatientDashboardViewState.textDark,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            color: _PatientDashboardViewState.textSoft,
            fontSize: 12,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: Color(0xFF71817A),
        ),
        onTap: onTap,
      ),
    );
  }
}