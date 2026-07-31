import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/medication_log_model.dart';
import '../../services/medication_log_service.dart';

enum MedicationAlarmResult {
  taken,
  snoozed,
  skipped,
}

class MedicationAlarmView extends StatefulWidget {
  final MedicationLogModel medicationLog;

  const MedicationAlarmView({
    super.key,
    required this.medicationLog,
  });

  @override
  State<MedicationAlarmView> createState() =>
      _MedicationAlarmViewState();
}

class _MedicationAlarmViewState extends State<MedicationAlarmView>
    with TickerProviderStateMixin {
  final MedicationLogService _logService =
  MedicationLogService();

  late final AnimationController _holdController;
  late final AnimationController _pulseController;
  late final AnimationController _entranceController;

  late final Animation<double> _pulseAnimation;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  Timer? _clockTimer;
  DateTime _currentTime = DateTime.now();

  bool _isProcessing = false;
  bool _isHolding = false;

  static const Color _primary = Color(0xFF276B5A);
  static const Color _primaryDark = Color(0xFF173F36);
  static const Color _primaryLight = Color(0xFFE2F2EA);
  static const Color _background = Color(0xFFF2F7F4);
  static const Color _surface = Colors.white;
  static const Color _textPrimary = Color(0xFF1B332D);
  static const Color _textSecondary = Color(0xFF66766F);
  static const Color _danger = Color(0xFFB24545);
  static const Color _warning = Color(0xFFB97920);

  @override
  void initState() {
    super.initState();

    _holdController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _holdController.addStatusListener(
          (AnimationStatus status) {
        if (status == AnimationStatus.completed &&
            _isHolding &&
            !_isProcessing) {
          HapticFeedback.heavyImpact();
          _confirmMedicationTaken();
        }
      },
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    );

    _pulseAnimation = Tween<double>(
      begin: 0.96,
      end: 1.04,
    ).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: Curves.easeOutCubic,
      ),
    );

    _pulseController.repeat(reverse: true);
    _entranceController.forward();

    _clockTimer = Timer.periodic(
      const Duration(seconds: 1),
          (_) {
        if (!mounted) return;

        setState(() {
          _currentTime = DateTime.now();
        });
      },
    );
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _holdController.dispose();
    _pulseController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  Future<void> _confirmMedicationTaken() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _isHolding = false;
    });

    try {
      await _logService.markAsTaken(
        logId: widget.medicationLog.id,
      );

      if (!mounted) return;

      Navigator.of(context).pop(
        MedicationAlarmResult.taken,
      );
    } catch (error) {
      _holdController.reset();

      if (!mounted) return;

      setState(() {
        _isProcessing = false;
        _isHolding = false;
      });

      _showMessage(
        'No fue posible registrar la toma: $error',
        isError: true,
      );
    }
  }

  Future<void> _snoozeMedication() async {
    if (_isProcessing) return;

    final bool? confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return _SnoozeSheet(
          onCancel: () {
            Navigator.of(bottomSheetContext).pop(false);
          },
          onConfirm: () {
            Navigator.of(bottomSheetContext).pop(true);
          },
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      await _logService.markAsSnoozed(
        logId: widget.medicationLog.id,
      );

      if (!mounted) return;

      Navigator.of(context).pop(
        MedicationAlarmResult.snoozed,
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isProcessing = false;
      });

      _showMessage(
        'No fue posible aplazar la alarma: $error',
        isError: true,
      );
    }
  }

  Future<void> _skipMedication() async {
    if (_isProcessing) return;

    final String? reason =
    await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return _SkipReasonSheet(
          onSelected: (reason) {
            Navigator.of(bottomSheetContext).pop(reason);
          },
        );
      },
    );

    if (reason == null ||
        reason.trim().isEmpty ||
        !mounted) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      await _logService.markAsSkipped(
        logId: widget.medicationLog.id,
        reason: reason,
      );

      if (!mounted) return;

      Navigator.of(context).pop(
        MedicationAlarmResult.skipped,
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isProcessing = false;
      });

      _showMessage(
        'No fue posible registrar la omisión: $error',
        isError: true,
      );
    }
  }

  void _startHolding() {
    if (_isProcessing) return;

    HapticFeedback.selectionClick();

    setState(() {
      _isHolding = true;
    });

    _holdController.forward(from: 0);
  }

  void _cancelHolding() {
    if (_isProcessing) return;

    setState(() {
      _isHolding = false;
    });

    _holdController.animateBack(
      0,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  void _showMessage(
      String message, {
        bool isError = false,
      }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(18),
        backgroundColor:
        isError ? _danger : _primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_outline_rounded,
              color: Colors.white,
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _medicationName {
    final name =
    widget.medicationLog.medicationName.trim();

    return name.isEmpty ? 'Medicamento' : name;
  }

  String get _doseText {
    final dose = widget.medicationLog.dose.trim();

    return dose.isEmpty ? 'Dosis indicada' : dose;
  }

  String get _instructionsText {
    final instructions =
    widget.medicationLog.instructions.trim();

    return instructions.isEmpty
        ? 'Sigue las indicaciones de tu tratamiento.'
        : instructions;
  }

  String get _scheduledTime {
    final time =
    widget.medicationLog.scheduledTime.trim();

    return time.isEmpty ? 'Hora programada' : time;
  }

  String get _currentClock {
    final hour = _currentTime.hour;
    final minute =
    _currentTime.minute.toString().padLeft(2, '0');

    final hour12 = hour % 12 == 0 ? 12 : hour % 12;
    final period = hour >= 12 ? 'p. m.' : 'a. m.';

    return '$hour12:$minute $period';
  }

  String get _currentDate {
    const months = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];

    return '${_currentTime.day} de '
        '${months[_currentTime.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: _background,
        body: Stack(
          children: [
            const Positioned.fill(
              child: _AlarmBackground(),
            ),
            SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final compact =
                          constraints.maxHeight < 740;

                      return SingleChildScrollView(
                        physics:
                        const BouncingScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(
                          20,
                          compact ? 14 : 20,
                          20,
                          28,
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight:
                            constraints.maxHeight - 50,
                          ),
                          child: Column(
                            children: [
                              _buildTopBar(),
                              SizedBox(
                                height: compact ? 18 : 26,
                              ),
                              _buildClock(),
                              SizedBox(
                                height: compact ? 18 : 24,
                              ),
                              _buildMedicationHero(
                                compact: compact,
                              ),
                              SizedBox(
                                height: compact ? 18 : 24,
                              ),
                              _buildHoldAction(),
                              const SizedBox(height: 13),
                              _buildSecondaryActions(),
                              const SizedBox(height: 18),
                              _buildSafetyMessage(),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            if (_isProcessing)
              Positioned.fill(
                child: AbsorbPointer(
                  child: Container(
                    color: Colors.black.withValues(
                      alpha: 0.08,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: _surface.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.75),
            ),
          ),
          child: const Icon(
            Icons.favorite_rounded,
            color: _primary,
            size: 25,
          ),
        ),
        const SizedBox(width: 11),
        const Expanded(
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Text(
                'VitaCare AI',
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'Recordatorio de tratamiento',
                style: TextStyle(
                  color: _textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 11,
            vertical: 7,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F4ED),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.notifications_active_rounded,
                color: _primary,
                size: 17,
              ),
              SizedBox(width: 5),
              Text(
                'Ahora',
                style: TextStyle(
                  color: _primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildClock() {
    return Column(
      children: [
        Text(
          _currentClock,
          style: const TextStyle(
            color: _primaryDark,
            fontSize: 45,
            height: 1,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _currentDate,
          style: const TextStyle(
            color: _textSecondary,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildMedicationHero({
    required bool compact,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
        compact ? 20 : 24,
      ),
      decoration: BoxDecoration(
        color: _surface.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Colors.white,
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: _primaryDark.withValues(alpha: 0.08),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          ScaleTransition(
            scale: _pulseAnimation,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: compact ? 104 : 118,
                  height: compact ? 104 : 118,
                  decoration: BoxDecoration(
                    color:
                    _primary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                ),
                Container(
                  width: compact ? 82 : 92,
                  height: compact ? 82 : 92,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF3B8772),
                        _primaryDark,
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _primary.withValues(
                          alpha: 0.24,
                        ),
                        blurRadius: 22,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.medication_rounded,
                    color: Colors.white,
                    size: 47,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: compact ? 14 : 18),
          const Text(
            'ES HORA DE TU MEDICAMENTO',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _primary,
              fontSize: 13,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _medicationName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _textPrimary,
              fontSize: 28,
              height: 1.08,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _doseText,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _primary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: compact ? 16 : 20),
          Row(
            children: [
              Expanded(
                child: _InfoTile(
                  icon: Icons.schedule_rounded,
                  label: 'Programado',
                  value: _scheduledTime,
                  accent: _primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _InfoTile(
                  icon: Icons.medical_information_outlined,
                  label: 'Estado',
                  value: 'Pendiente',
                  accent: _warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: _primaryLight,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: const Color(0xFFCBE3D6),
              ),
            ),
            child: Row(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: _primary,
                  size: 23,
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    _instructionsText,
                    style: const TextStyle(
                      color: _textPrimary,
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

  Widget _buildHoldAction() {
    return AnimatedBuilder(
      animation: _holdController,
      builder: (context, child) {
        final progress = _holdController.value;

        return Semantics(
          button: true,
          label:
          'Mantén presionado para confirmar que tomaste el medicamento',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onLongPressStart: (_) {
              _startHolding();
            },
            onLongPressEnd: (_) {
              _cancelHolding();
            },
            onLongPressCancel: _cancelHolding,
            child: AnimatedContainer(
              duration:
              const Duration(milliseconds: 160),
              width: double.infinity,
              height: 92,
              decoration: BoxDecoration(
                color: _isHolding
                    ? _primaryDark
                    : _primary,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: _primary.withValues(alpha: 0.28),
                    blurRadius: _isHolding ? 20 : 14,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius:
                      BorderRadius.circular(25),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: progress,
                          child: Container(
                            color: Colors.white.withValues(
                              alpha: 0.16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Padding(
                      padding:
                      const EdgeInsets.symmetric(
                        horizontal: 18,
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 52,
                            height: 52,
                            child: _isProcessing
                                ? const Padding(
                              padding:
                              EdgeInsets.all(12),
                              child:
                              CircularProgressIndicator(
                                strokeWidth: 3,
                                color: Colors.white,
                              ),
                            )
                                : Stack(
                              alignment:
                              Alignment.center,
                              children: [
                                CircularProgressIndicator(
                                  value: progress,
                                  strokeWidth: 4,
                                  backgroundColor:
                                  Colors.white
                                      .withValues(
                                    alpha: 0.25,
                                  ),
                                  color: Colors.white,
                                ),
                                const Icon(
                                  Icons
                                      .check_rounded,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              mainAxisAlignment:
                              MainAxisAlignment.center,
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Ya tomé mi medicamento',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight:
                                    FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _isHolding
                                      ? 'Mantén presionado...'
                                      : 'Mantén presionado para confirmar',
                                  style: TextStyle(
                                    color: Colors.white
                                        .withValues(
                                      alpha: 0.84,
                                    ),
                                    fontSize: 13,
                                    fontWeight:
                                    FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.touch_app_rounded,
                            color: Colors.white,
                            size: 25,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSecondaryActions() {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 60,
            child: OutlinedButton.icon(
              onPressed:
              _isProcessing ? null : _snoozeMedication,
              style: OutlinedButton.styleFrom(
                foregroundColor: _primary,
                backgroundColor: Colors.white,
                side: const BorderSide(
                  color: Color(0xFFC7DDD3),
                  width: 1.4,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(19),
                ),
              ),
              icon: const Icon(
                Icons.snooze_rounded,
                size: 24,
              ),
              label: const Text(
                'Posponer',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: SizedBox(
            height: 60,
            child: OutlinedButton.icon(
              onPressed:
              _isProcessing ? null : _skipMedication,
              style: OutlinedButton.styleFrom(
                foregroundColor: _danger,
                backgroundColor: Colors.white,
                side: const BorderSide(
                  color: Color(0xFFE5C4C4),
                  width: 1.4,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(19),
                ),
              ),
              icon: const Icon(
                Icons.cancel_outlined,
                size: 23,
              ),
              label: const Text(
                'Omitir',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSafetyMessage() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.health_and_safety_outlined,
          size: 19,
          color: _primary,
        ),
        SizedBox(width: 8),
        Flexible(
          child: Text(
            'Sigue siempre las indicaciones de tu médico',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _AlarmBackground extends StatelessWidget {
  const _AlarmBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFDCEFE6),
                Color(0xFFF2F7F4),
                Color(0xFFF7F9F8),
              ],
              stops: [0, 0.42, 1],
            ),
          ),
          child: SizedBox.expand(),
        ),
        Positioned(
          top: -80,
          right: -60,
          child: Container(
            width: 230,
            height: 230,
            decoration: BoxDecoration(
              color: const Color(0xFF6EA58F)
                  .withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          top: 130,
          left: -90,
          child: Container(
            width: 210,
            height: 210,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.44),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAF8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE2EAE6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: accent,
                size: 19,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: _MedicationAlarmViewState
                        ._textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color:
              _MedicationAlarmViewState._textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SnoozeSheet extends StatelessWidget {
  const _SnoozeSheet({
    required this.onCancel,
    required this.onConfirm,
  });

  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.only(top: 50),
        padding: const EdgeInsets.fromLTRB(
          22,
          12,
          22,
          24,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(30),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 46,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFD2DAD6),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 22),
            Container(
              width: 66,
              height: 66,
              decoration: const BoxDecoration(
                color: Color(0xFFE7F3ED),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.snooze_rounded,
                color: _MedicationAlarmViewState._primary,
                size: 34,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Posponer recordatorio',
              style: TextStyle(
                color:
                _MedicationAlarmViewState._textPrimary,
                fontSize: 21,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'La alarma volverá a mostrarse en 5 minutos.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color:
                _MedicationAlarmViewState._textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: onConfirm,
                style: FilledButton.styleFrom(
                  backgroundColor:
                  _MedicationAlarmViewState._primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(17),
                  ),
                ),
                icon: const Icon(Icons.alarm_add_rounded),
                label: const Text(
                  'Recordarme en 5 minutos',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: onCancel,
              child: const Text('Cancelar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkipReasonSheet extends StatelessWidget {
  const _SkipReasonSheet({
    required this.onSelected,
  });

  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.only(top: 35),
        padding: const EdgeInsets.fromLTRB(
          20,
          12,
          20,
          24,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(30),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 46,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFD2DAD6),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              '¿Por qué deseas omitirlo?',
              textAlign: TextAlign.center,
              style: TextStyle(
                color:
                _MedicationAlarmViewState._textPrimary,
                fontSize: 21,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              'Selecciona el motivo para mantener actualizado tu seguimiento.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color:
                _MedicationAlarmViewState._textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            _ReasonOption(
              icon: Icons.inventory_2_outlined,
              title: 'No tengo el medicamento',
              subtitle: 'Necesito conseguirlo o surtir la receta',
              onTap: () {
                onSelected(
                  'No tengo el medicamento',
                );
              },
            ),
            _ReasonOption(
              icon: Icons.sick_outlined,
              title: 'Me siento mal',
              subtitle: 'Presento molestias o efectos secundarios',
              onTap: () {
                onSelected('Me siento mal');
              },
            ),
            _ReasonOption(
              icon: Icons.schedule_rounded,
              title: 'Lo tomaré después',
              subtitle: 'No puedo tomarlo en este momento',
              onTap: () {
                onSelected('Lo tomaré después');
              },
            ),
            _ReasonOption(
              icon: Icons.more_horiz_rounded,
              title: 'Otro motivo',
              subtitle: 'Tengo una razón diferente',
              onTap: () {
                onSelected('Otro motivo');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ReasonOption extends StatelessWidget {
  const _ReasonOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
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
                  decoration: const BoxDecoration(
                    color: Color(0xFFE7F3ED),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color:
                    _MedicationAlarmViewState._primary,
                    size: 24,
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
                          color: _MedicationAlarmViewState
                              ._textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: _MedicationAlarmViewState
                              ._textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: _MedicationAlarmViewState
                      ._textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}