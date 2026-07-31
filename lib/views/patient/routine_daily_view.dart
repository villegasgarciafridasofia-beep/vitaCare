import 'package:flutter/material.dart';

import '../../models/user_model.dart';
import '../../services/firestore_service.dart';

class RoutineDailyView extends StatefulWidget {
  final UserModel? patient;

  const RoutineDailyView({
    super.key,
    required this.patient,
  });

  static const Color primaryDark = Color(0xFF285F50);
  static const Color primary = Color(0xFF3E806B);
  static const Color primaryLight = Color(0xFFE4F1EA);
  static const Color background = Color(0xFFF4F8F5);
  static const Color textDark = Color(0xFF24463E);
  static const Color textSoft = Color(0xFF64756E);
  static const Color borderColor = Color(0xFFE1EAE5);

  @override
  State<RoutineDailyView> createState() => _RoutineDailyViewState();
}

class _RoutineDailyViewState extends State<RoutineDailyView> {
  final FirestoreService _firestoreService = FirestoreService();

  UserModel? _patient;
  bool _isSaving = false;

  static const Color primaryDark = RoutineDailyView.primaryDark;
  static const Color primary = RoutineDailyView.primary;
  static const Color primaryLight = RoutineDailyView.primaryLight;
  static const Color background = RoutineDailyView.background;
  static const Color textDark = RoutineDailyView.textDark;
  static const Color textSoft = RoutineDailyView.textSoft;
  static const Color borderColor = RoutineDailyView.borderColor;

  @override
  void initState() {
    super.initState();
    _patient = widget.patient;
  }

  @override
  Widget build(BuildContext context) {
    final UserModel? user = _patient;

    if (user == null) {
      return const Scaffold(
        backgroundColor: background,
        body: SafeArea(
          child: _EmptyRoutineState(),
        ),
      );
    }

    final bool configured = user.isRoutineConfigured;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text(
          'Rutina diaria',
          style: TextStyle(
            color: textDark,
            fontWeight: FontWeight.w800,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: primaryDark,
        surfaceTintColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Editar rutina',
            onPressed: _isSaving
                ? null
                : () {
              _editRoutine(user);
            },
            icon: _isSaving
                ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.3,
                color: primaryDark,
              ),
            )
                : const Icon(Icons.edit_calendar_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            20,
            18,
            20,
            32,
          ),
          children: [
            _buildHeroCard(
              user: user,
              configured: configured,
            ),
            const SizedBox(height: 20),
            _buildRoutineSummary(
              user: user,
              configured: configured,
            ),
            const SizedBox(height: 24),
            const _SectionHeader(
              title: 'Tu día',
              subtitle:
              'Horarios utilizados para personalizar tus recordatorios',
            ),
            const SizedBox(height: 14),
            _buildTimeline(user),
            const SizedBox(height: 24),
            const _SectionHeader(
              title: 'Preferencias',
              subtitle:
              'Configuración utilizada para adaptar las notificaciones',
            ),
            const SizedBox(height: 14),
            _buildPreferencesCard(user),
            const SizedBox(height: 24),
            _buildSmartScheduleNotice(),
          ],
        ),
      ),
    );
  }

  Future<void> _editRoutine(UserModel user) async {
    String wakeUpTime = user.wakeUpTime;
    String breakfastTime = user.breakfastTime;
    String lunchTime = user.lunchTime;
    String dinnerTime = user.dinnerTime;
    String sleepTime = user.sleepTime;
    bool allowNightReminders = user.allowNightReminders;
    int reminderMinutesBefore = user.reminderMinutesBefore;

    final bool? shouldSave = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext bottomSheetContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.90,
              ),
              padding: EdgeInsets.fromLTRB(
                20,
                12,
                20,
                MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
              ),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 48,
                        height: 5,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD5DFDA),
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Row(
                        children: [
                          CircleAvatar(
                            radius: 25,
                            backgroundColor: primaryLight,
                            child: Icon(
                              Icons.edit_calendar_rounded,
                              color: primaryDark,
                            ),
                          ),
                          SizedBox(width: 13),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Editar rutina',
                                  style: TextStyle(
                                    color: textDark,
                                    fontSize: 21,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                SizedBox(height: 3),
                                Text(
                                  'Actualiza tus horarios diarios',
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
                      const SizedBox(height: 22),
                      _EditableTimeTile(
                        icon: Icons.wb_sunny_outlined,
                        title: 'Hora de despertar',
                        value: _displayTime(wakeUpTime),
                        onTap: () async {
                          final String? value = await _selectTime(
                            currentValue: wakeUpTime,
                          );
                          if (value != null) {
                            setModalState(() => wakeUpTime = value);
                          }
                        },
                      ),
                      _EditableTimeTile(
                        icon: Icons.free_breakfast_outlined,
                        title: 'Desayuno',
                        value: _displayTime(breakfastTime),
                        onTap: () async {
                          final String? value = await _selectTime(
                            currentValue: breakfastTime,
                          );
                          if (value != null) {
                            setModalState(() => breakfastTime = value);
                          }
                        },
                      ),
                      _EditableTimeTile(
                        icon: Icons.restaurant_outlined,
                        title: 'Comida',
                        value: _displayTime(lunchTime),
                        onTap: () async {
                          final String? value = await _selectTime(
                            currentValue: lunchTime,
                          );
                          if (value != null) {
                            setModalState(() => lunchTime = value);
                          }
                        },
                      ),
                      _EditableTimeTile(
                        icon: Icons.dinner_dining_outlined,
                        title: 'Cena',
                        value: _displayTime(dinnerTime),
                        onTap: () async {
                          final String? value = await _selectTime(
                            currentValue: dinnerTime,
                          );
                          if (value != null) {
                            setModalState(() => dinnerTime = value);
                          }
                        },
                      ),
                      _EditableTimeTile(
                        icon: Icons.nightlight_round,
                        title: 'Hora de dormir',
                        value: _displayTime(sleepTime),
                        onTap: () async {
                          final String? value = await _selectTime(
                            currentValue: sleepTime,
                          );
                          if (value != null) {
                            setModalState(() => sleepTime = value);
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                        secondary: Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: primaryLight,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.bedtime_outlined,
                            color: primaryDark,
                          ),
                        ),
                        title: const Text(
                          'Recordatorios nocturnos',
                          style: TextStyle(
                            color: textDark,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        subtitle: const Text(
                          'Permitir alarmas durante tus horas de descanso',
                          style: TextStyle(
                            color: textSoft,
                            fontSize: 12,
                          ),
                        ),
                        value: allowNightReminders,
                        activeThumbColor: primaryDark,
                        onChanged: (bool value) {
                          setModalState(() => allowNightReminders = value);
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        initialValue: reminderMinutesBefore,
                        decoration: InputDecoration(
                          labelText: 'Avisar antes',
                          prefixIcon: const Icon(
                            Icons.notifications_active_outlined,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 5,
                            child: Text('5 minutos antes'),
                          ),
                          DropdownMenuItem(
                            value: 10,
                            child: Text('10 minutos antes'),
                          ),
                          DropdownMenuItem(
                            value: 15,
                            child: Text('15 minutos antes'),
                          ),
                          DropdownMenuItem(
                            value: 30,
                            child: Text('30 minutos antes'),
                          ),
                        ],
                        onChanged: (int? value) {
                          if (value != null) {
                            setModalState(() => reminderMinutesBefore = value);
                          }
                        },
                      ),
                      const SizedBox(height: 22),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: FilledButton.icon(
                          onPressed: () {
                            Navigator.of(bottomSheetContext).pop(true);
                          },
                          icon: const Icon(Icons.save_rounded),
                          label: const Text(
                            'Guardar cambios',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: primaryDark,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(17),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          Navigator.of(bottomSheetContext).pop(false);
                        },
                        child: const Text('Cancelar'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (shouldSave != true || !mounted) return;

    setState(() => _isSaving = true);

    try {
      await _firestoreService.updateUserRoutine(
        uid: user.uid,
        wakeUpTime: wakeUpTime,
        breakfastTime: breakfastTime,
        lunchTime: lunchTime,
        dinnerTime: dinnerTime,
        sleepTime: sleepTime,
        allowNightReminders: allowNightReminders,
        reminderMinutesBefore: reminderMinutesBefore,
      );

      final UserModel? updatedUser = await _firestoreService.getUser(user.uid);

      if (!mounted) return;

      setState(() {
        _patient = updatedUser ?? _patient;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: primaryDark,
          content: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white),
              SizedBox(width: 10),
              Expanded(child: Text('Rutina actualizada correctamente')),
            ],
          ),
        ),
      );
    } catch (error, stackTrace) {
      debugPrint('Error actualizando la rutina: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFB94747),
          content: Text('No fue posible guardar la rutina: $error'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<String?> _selectTime({
    required String currentValue,
  }) async {
    final TimeOfDay initialTime =
        _timeFromString(currentValue) ?? TimeOfDay.now();

    final TimeOfDay? selectedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
      helpText: 'Selecciona la hora',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: primaryDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedTime == null) return null;

    return '${selectedTime.hour.toString().padLeft(2, '0')}:'
        '${selectedTime.minute.toString().padLeft(2, '0')}';
  }

  TimeOfDay? _timeFromString(String value) {
    final String normalized = value.trim().toUpperCase();

    if (normalized.isEmpty) return null;

    final bool isPm =
        normalized.contains('PM') || normalized.contains('P. M.');
    final bool isAm =
        normalized.contains('AM') || normalized.contains('A. M.');

    final String cleanValue = normalized
        .replaceAll('A. M.', '')
        .replaceAll('P. M.', '')
        .replaceAll('AM', '')
        .replaceAll('PM', '')
        .trim();

    final List<String> parts = cleanValue.split(':');

    if (parts.length != 2) return null;

    int? hour = int.tryParse(parts[0].trim());
    final int? minute = int.tryParse(
      parts[1].replaceAll(RegExp(r'[^0-9]'), ''),
    );

    if (hour == null || minute == null || minute > 59) return null;

    if (isPm && hour < 12) hour += 12;
    if (isAm && hour == 12) hour = 0;
    if (hour > 23) return null;

    return TimeOfDay(hour: hour, minute: minute);
  }

  Widget _buildHeroCard({
    required UserModel user,
    required bool configured,
  }) {
    return Container(
      padding: const EdgeInsets.all(23),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF4B927B),
            Color(0xFF285F50),
          ],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: primaryDark.withValues(alpha: 0.20),
            blurRadius: 24,
            offset: const Offset(0, 11),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  configured
                      ? Icons.schedule_rounded
                      : Icons.pending_actions_rounded,
                  color: Colors.white,
                  size: 31,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      configured
                          ? 'Rutina configurada'
                          : 'Rutina pendiente',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      configured
                          ? 'Tus recordatorios se adaptan a tus horarios.'
                          : 'Configura tus horarios para recibir recordatorios inteligentes.',
                      style: const TextStyle(
                        color: Color(0xFFE6F3ED),
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 13,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Icon(
                  configured
                      ? Icons.check_circle_rounded
                      : Icons.info_outline_rounded,
                  color: Colors.white,
                  size: 21,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    configured
                        ? 'VitaCare AI utiliza esta rutina para evitar recordatorios durante tus horas de descanso.'
                        : 'Completa la rutina para mejorar la precisión de tus horarios de medicamentos.',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoutineSummary({
    required UserModel user,
    required bool configured,
  }) {
    return Row(
      children: [
        Expanded(
          child: _SummaryMetric(
            icon: Icons.wb_sunny_outlined,
            value: _displayTime(user.wakeUpTime),
            label: 'Despertar',
            background: primaryLight,
            iconColor: primaryDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryMetric(
            icon: Icons.restaurant_rounded,
            value: _displayTime(user.lunchTime),
            label: 'Comida',
            background: const Color(0xFFFFF0DF),
            iconColor: const Color(0xFFB66A2D),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryMetric(
            icon: Icons.nightlight_round,
            value: _displayTime(user.sleepTime),
            label: 'Dormir',
            background: const Color(0xFFF0EAF8),
            iconColor: const Color(0xFF73539B),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeline(UserModel user) {
    final List<_RoutineEventData> events = [
      _RoutineEventData(
        icon: Icons.wb_sunny_outlined,
        title: 'Hora de despertar',
        time: _displayTime(user.wakeUpTime),
        description:
        'Inicio estimado de tus actividades diarias.',
        color: const Color(0xFFB66A2D),
        background: const Color(0xFFFFF0DF),
      ),
      _RoutineEventData(
        icon: Icons.free_breakfast_outlined,
        title: 'Desayuno',
        time: _displayTime(user.breakfastTime),
        description:
        'Referencia para medicamentos antes o después de alimentos.',
        color: const Color(0xFF3E668B),
        background: const Color(0xFFE6EFF7),
      ),
      _RoutineEventData(
        icon: Icons.restaurant_outlined,
        title: 'Comida',
        time: _displayTime(user.lunchTime),
        description:
        'Horario principal de alimentación durante el día.',
        color: primaryDark,
        background: primaryLight,
      ),
      _RoutineEventData(
        icon: Icons.dinner_dining_outlined,
        title: 'Cena',
        time: _displayTime(user.dinnerTime),
        description:
        'Referencia para tratamientos nocturnos.',
        color: const Color(0xFF73539B),
        background: const Color(0xFFF0EAF8),
      ),
      _RoutineEventData(
        icon: Icons.nightlight_round,
        title: 'Hora de dormir',
        time: _displayTime(user.sleepTime),
        description:
        'Inicio de tu periodo habitual de descanso.',
        color: const Color(0xFF4A5878),
        background: const Color(0xFFE9ECF4),
      ),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(
        18,
        18,
        18,
        8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: primaryDark.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        children: [
          for (int index = 0;
          index < events.length;
          index++)
            _TimelineItem(
              event: events[index],
              isLast: index == events.length - 1,
            ),
        ],
      ),
    );
  }

  Widget _buildPreferencesCard(UserModel user) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          _PreferenceItem(
            icon: Icons.bedtime_outlined,
            title: 'Recordatorios nocturnos',
            subtitle: user.allowNightReminders
                ? 'Permitidos durante el horario de descanso'
                : 'Evitados durante el horario de descanso',
            enabled: user.allowNightReminders,
          ),
          const Divider(
            height: 25,
            indent: 58,
            color: borderColor,
          ),
          _PreferenceItem(
            icon: Icons.auto_awesome_rounded,
            title: 'Horarios inteligentes',
            subtitle: user.isRoutineConfigured
                ? 'Activos y adaptados a tu rutina'
                : 'Pendientes de configurar',
            enabled: user.isRoutineConfigured,
          ),
        ],
      ),
    );
  }

  Widget _buildSmartScheduleNotice() {
    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFE6F3F3),
            Color(0xFFEAF5EF),
          ],
        ),
        borderRadius: BorderRadius.circular(23),
        border: Border.all(
          color: const Color(0xFFCDE3DE),
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: Colors.white,
            child: Icon(
              Icons.smart_toy_rounded,
              color: Color(0xFF31787A),
            ),
          ),
          SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Horarios inteligentes',
                  style: TextStyle(
                    color: textDark,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 7),
                Text(
                  'VitaCare AI utiliza tu rutina para sugerir horarios de medicamentos que interfieran lo menos posible con tus comidas y descanso.',
                  style: TextStyle(
                    color: textDark,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _displayTime(String value) {
    final String time = value.trim();

    if (time.isEmpty) {
      return 'Sin definir';
    }

    return _formatTime(time);
  }

  String _formatTime(String value) {
    String normalized = value.trim().toUpperCase();

    if (normalized.contains('AM') ||
        normalized.contains('PM') ||
        normalized.contains('A. M.') ||
        normalized.contains('P. M.')) {
      return value;
    }

    final List<String> parts = normalized.split(':');

    if (parts.length != 2) {
      return value;
    }

    final int? hour = int.tryParse(parts[0]);
    final int? minute = int.tryParse(parts[1]);

    if (hour == null || minute == null) {
      return value;
    }

    final String period =
    hour >= 12 ? 'p. m.' : 'a. m.';
    final int displayHour =
    hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);

    return '$displayHour:'
        '${minute.toString().padLeft(2, '0')} '
        '$period';
  }
}

class _EditableTimeTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;

  const _EditableTimeTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Material(
        color: const Color(0xFFF6F9F7),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 14,
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: RoutineDailyView.primaryLight,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    icon,
                    color: RoutineDailyView.primaryDark,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: RoutineDailyView.textDark,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        value,
                        style: const TextStyle(
                          color: RoutineDailyView.textSoft,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: RoutineDailyView.textSoft,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoutineEventData {
  final IconData icon;
  final String title;
  final String time;
  final String description;
  final Color color;
  final Color background;

  const _RoutineEventData({
    required this.icon,
    required this.title,
    required this.time,
    required this.description,
    required this.color,
    required this.background,
  });
}

class _TimelineItem extends StatelessWidget {
  final _RoutineEventData event;
  final bool isLast;

  const _TimelineItem({
    required this.event,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 50,
            child: Column(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: event.background,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    event.icon,
                    color: event.color,
                    size: 23,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(
                        vertical: 5,
                      ),
                      color: RoutineDailyView.borderColor,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: isLast ? 12 : 22,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          event.title,
                          style: const TextStyle(
                            color:
                            RoutineDailyView.textDark,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: event.background,
                          borderRadius:
                          BorderRadius.circular(16),
                        ),
                        child: Text(
                          event.time,
                          style: TextStyle(
                            color: event.color,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    event.description,
                    style: const TextStyle(
                      color: RoutineDailyView.textSoft,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreferenceItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;

  const _PreferenceItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: enabled
                ? RoutineDailyView.primaryLight
                : const Color(0xFFE9ECEA),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            icon,
            color: enabled
                ? RoutineDailyView.primaryDark
                : RoutineDailyView.textSoft,
            size: 23,
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: RoutineDailyView.textDark,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  color: RoutineDailyView.textSoft,
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 9,
            vertical: 5,
          ),
          decoration: BoxDecoration(
            color: enabled
                ? const Color(0xFFE7F5E9)
                : const Color(0xFFFFF0DF),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Text(
            enabled ? 'Activo' : 'Inactivo',
            style: TextStyle(
              color: enabled
                  ? const Color(0xFF43855A)
                  : const Color(0xFFB66A2D),
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: RoutineDailyView.textDark,
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            color: RoutineDailyView.textSoft,
            fontSize: 12,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color background;
  final Color iconColor;

  const _SummaryMetric({
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
        horizontal: 8,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: RoutineDailyView.borderColor,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 41,
            height: 41,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 21,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: RoutineDailyView.textDark,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: RoutineDailyView.textSoft,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyRoutineState extends StatelessWidget {
  const _EmptyRoutineState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 94,
              height: 94,
              decoration: BoxDecoration(
                color: RoutineDailyView.primaryLight,
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Icon(
                Icons.schedule_outlined,
                color: RoutineDailyView.primaryDark,
                size: 47,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Rutina no disponible',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: RoutineDailyView.textDark,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'No fue posible cargar los datos de la rutina diaria.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: RoutineDailyView.textSoft,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(
                Icons.arrow_back_rounded,
              ),
              label: const Text('Regresar'),
              style: FilledButton.styleFrom(
                backgroundColor:
                RoutineDailyView.primaryDark,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}