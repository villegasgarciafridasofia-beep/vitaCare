import 'package:flutter/material.dart';

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

class _MedicationAlarmViewState
    extends State<MedicationAlarmView>
    with TickerProviderStateMixin {
  final MedicationLogService _logService =
  MedicationLogService();

  late final AnimationController _holdController;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  bool _isProcessing = false;
  bool _isHolding = false;

  @override
  void initState() {
    super.initState();

    // Controla la confirmación al mantener presionado.
    _holdController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _holdController.addStatusListener((status) {
      if (status == AnimationStatus.completed &&
          _isHolding &&
          !_isProcessing) {
        _confirmMedicationTaken();
      }
    });

    // Animación suave del icono del medicamento.
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 900,
      ),
    );

    _pulseAnimation = Tween<double>(
      begin: 0.92,
      end: 1.08,
    ).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    _pulseController.repeat(
      reverse: true,
    );
  }

  @override
  void dispose() {
    _holdController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  // =========================================================
  // MARCAR MEDICAMENTO COMO TOMADO
  // =========================================================

  Future<void> _confirmMedicationTaken() async {
    if (_isProcessing) {
      return;
    }

    setState(() {
      _isProcessing = true;
      _isHolding = false;
    });

    try {
      await _logService.markAsTaken(
        logId: widget.medicationLog.id,
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(
        MedicationAlarmResult.taken,
      );
    } catch (error) {
      _holdController.reset();

      if (!mounted) {
        return;
      }

      setState(() {
        _isProcessing = false;
        _isHolding = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No fue posible registrar la toma: $error',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // =========================================================
  // POSPONER MEDICAMENTO
  // =========================================================

  Future<void> _snoozeMedication() async {
    if (_isProcessing) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      await _logService.markAsSnoozed(
        logId: widget.medicationLog.id,
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(
        MedicationAlarmResult.snoozed,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isProcessing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No fue posible aplazar la alarma: $error',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // =========================================================
  // OMITIR MEDICAMENTO
  // =========================================================

  Future<void> _skipMedication() async {
    if (_isProcessing) {
      return;
    }

    final String? reason =
    await showModalBottomSheet<String>(
      context: context,
      isDismissible: true,
      enableDrag: true,
      showDragHandle: true,
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              24,
              4,
              24,
              24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
              CrossAxisAlignment.stretch,
              children: [
                Text(
                  '¿Por qué deseas omitirlo?',
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    bottomSheetContext,
                  ).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Selecciona el motivo para continuar.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                _ReasonOption(
                  icon: Icons.medication_outlined,
                  text: 'No tengo el medicamento',
                  onTap: () {
                    Navigator.of(
                      bottomSheetContext,
                    ).pop(
                      'No tengo el medicamento',
                    );
                  },
                ),

                _ReasonOption(
                  icon: Icons.sentiment_satisfied_alt,
                  text: 'Me siento bien',
                  onTap: () {
                    Navigator.of(
                      bottomSheetContext,
                    ).pop(
                      'Me siento bien',
                    );
                  },
                ),

                _ReasonOption(
                  icon: Icons.schedule_rounded,
                  text: 'Lo tomaré después',
                  onTap: () {
                    Navigator.of(
                      bottomSheetContext,
                    ).pop(
                      'Lo tomaré después',
                    );
                  },
                ),

                _ReasonOption(
                  icon: Icons.more_horiz_rounded,
                  text: 'Otro motivo',
                  onTap: () {
                    Navigator.of(
                      bottomSheetContext,
                    ).pop(
                      'Otro motivo',
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );

    if (reason == null || reason.trim().isEmpty) {
      return;
    }

    if (!mounted) {
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

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(
        MedicationAlarmResult.skipped,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isProcessing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No fue posible registrar la omisión: $error',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // =========================================================
  // CONTROL DEL BOTÓN MANTENER PRESIONADO
  // =========================================================

  void _startHolding() {
    if (_isProcessing) {
      return;
    }

    setState(() {
      _isHolding = true;
    });

    _holdController.forward(
      from: 0,
    );
  }

  void _cancelHolding() {
    if (_isProcessing) {
      return;
    }

    setState(() {
      _isHolding = false;
    });

    _holdController.reverse();
  }

  // =========================================================
  // INFORMACIÓN DEL MEDICAMENTO
  // =========================================================

  String get _medicationName {
    final String name =
    widget.medicationLog.medicationName.trim();

    if (name.isEmpty) {
      return 'Medicamento';
    }

    return name;
  }

  String get _doseText {
    final String dose =
    widget.medicationLog.dose.trim();

    if (dose.isEmpty) {
      return 'Dosis indicada';
    }

    return dose;
  }

  String get _instructionsText {
    final String instructions =
    widget.medicationLog.instructions.trim();

    if (instructions.isEmpty) {
      return 'Sigue las indicaciones de tu tratamiento.';
    }

    return instructions;
  }

  String get _scheduledTime {
    final String time =
    widget.medicationLog.scheduledTime.trim();

    if (time.isEmpty) {
      return 'Hora programada';
    }

    return time;
  }

  // =========================================================
  // INTERFAZ PRINCIPAL
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                theme.colorScheme.primaryContainer
                    .withValues(
                  alpha: 0.75,
                ),
                Colors.white,
                Colors.white,
              ],
              stops: const [
                0,
                0.40,
                1,
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 22,
                vertical: 18,
              ),
              child: Column(
                children: [
                  _buildHeader(theme),

                  const SizedBox(height: 18),

                  Expanded(
                    child: SingleChildScrollView(
                      physics:
                      const BouncingScrollPhysics(),
                      child: Column(
                        children: [
                          _buildAlarmIcon(theme),

                          const SizedBox(height: 18),

                          Text(
                            'ES HORA DE TU MEDICAMENTO',
                            textAlign: TextAlign.center,
                            style: theme
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                              fontWeight:
                              FontWeight.w800,
                              letterSpacing: 0.6,
                              height: 1.2,
                            ),
                          ),

                          const SizedBox(height: 22),

                          _buildMedicationCard(
                            theme,
                          ),

                          const SizedBox(height: 26),

                          _buildHoldButton(
                            theme,
                          ),

                          const SizedBox(height: 16),

                          _buildSnoozeButton(
                            theme,
                          ),

                          const SizedBox(height: 10),

                          _buildSkipButton(
                            theme,
                          ),

                          const SizedBox(height: 18),

                          _buildFooter(
                            theme,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================
  // ENCABEZADO
  // =========================================================

  Widget _buildHeader(
      ThemeData theme,
      ) {
    return Row(
      mainAxisAlignment:
      MainAxisAlignment.center,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: theme.colorScheme.primary,
          ),
          child: const Icon(
            Icons.favorite_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'VitaCare AI',
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  // =========================================================
  // ICONO ANIMADO
  // =========================================================

  Widget _buildAlarmIcon(
      ThemeData theme,
      ) {
    return ScaleTransition(
      scale: _pulseAnimation,
      child: Container(
        width: 116,
        height: 116,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary
                  .withValues(
                alpha: 0.20,
              ),
              blurRadius: 24,
              spreadRadius: 7,
            ),
          ],
        ),
        child: Icon(
          Icons.medication_rounded,
          size: 64,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  // =========================================================
  // TARJETA DEL MEDICAMENTO
  // =========================================================

  Widget _buildMedicationCard(
      ThemeData theme,
      ) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 5,
      shadowColor: Colors.black.withValues(
        alpha: 0.12,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          26,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(
          24,
        ),
        child: Column(
          children: [
            Text(
              _medicationName.toUpperCase(),
              textAlign: TextAlign.center,
              style: theme
                  .textTheme
                  .headlineSmall
                  ?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w900,
              ),
            ),

            const SizedBox(height: 12),

            Text(
              _doseText,
              textAlign: TextAlign.center,
              style: theme
                  .textTheme
                  .titleLarge
                  ?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 16),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(
                16,
              ),
              decoration: BoxDecoration(
                color: theme
                    .colorScheme
                    .surfaceContainerHighest
                    .withValues(
                  alpha: 0.55,
                ),
                borderRadius:
                BorderRadius.circular(
                  18,
                ),
              ),
              child: Row(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color:
                    theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _instructionsText,
                      style: theme
                          .textTheme
                          .bodyLarge
                          ?.copyWith(
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Container(
              padding:
              const EdgeInsets.symmetric(
                horizontal: 22,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                borderRadius:
                BorderRadius.circular(
                  30,
                ),
                color: theme
                    .colorScheme
                    .primaryContainer,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    color:
                    theme.colorScheme.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _scheduledTime,
                    style: theme
                        .textTheme
                        .titleLarge
                        ?.copyWith(
                      color:
                      theme.colorScheme.primary,
                      fontWeight:
                      FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // BOTÓN CONFIRMAR TOMA
  // =========================================================

  Widget _buildHoldButton(
      ThemeData theme,
      ) {
    return AnimatedBuilder(
      animation: _holdController,
      builder: (
          BuildContext context,
          Widget? child,
          ) {
        final double progress =
            _holdController.value;

        return GestureDetector(
          onLongPressStart: (_) {
            _startHolding();
          },
          onLongPressEnd: (_) {
            _cancelHolding();
          },
          onLongPressCancel:
          _cancelHolding,
          child: Container(
            width: double.infinity,
            constraints:
            const BoxConstraints(
              minHeight: 96,
            ),
            decoration: BoxDecoration(
              borderRadius:
              BorderRadius.circular(
                24,
              ),
              color: theme
                  .colorScheme
                  .primaryContainer,
              border: Border.all(
                color:
                theme.colorScheme.primary,
                width: 2.4,
              ),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: FractionallySizedBox(
                    alignment:
                    Alignment.centerLeft,
                    widthFactor: progress,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius:
                        BorderRadius.circular(
                          21,
                        ),
                        color: theme
                            .colorScheme
                            .primary
                            .withValues(
                          alpha: 0.24,
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
                      vertical: 12,
                    ),
                    child: Row(
                      mainAxisAlignment:
                      MainAxisAlignment.center,
                      children: [
                        if (_isProcessing)
                          const SizedBox(
                            width: 32,
                            height: 32,
                            child:
                            CircularProgressIndicator(
                              strokeWidth: 3,
                            ),
                          )
                        else
                          Icon(
                            Icons
                                .check_circle_rounded,
                            size: 42,
                            color: theme
                                .colorScheme
                                .primary,
                          ),

                        const SizedBox(width: 14),

                        Flexible(
                          child: Column(
                            mainAxisAlignment:
                            MainAxisAlignment
                                .center,
                            children: [
                              Text(
                                'YA TOMÉ MI MEDICAMENTO',
                                textAlign:
                                TextAlign.center,
                                style: theme
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                  fontWeight:
                                  FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                _isHolding
                                    ? 'Continúa presionando...'
                                    : 'Mantén presionado durante 2 segundos',
                                textAlign:
                                TextAlign.center,
                                style: theme
                                    .textTheme
                                    .bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // =========================================================
  // BOTÓN POSPONER
  // =========================================================

  Widget _buildSnoozeButton(
      ThemeData theme,
      ) {
    return SizedBox(
      width: double.infinity,
      height: 62,
      child: OutlinedButton.icon(
        onPressed: _isProcessing
            ? null
            : _snoozeMedication,
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: theme.colorScheme.primary,
            width: 2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(
              18,
            ),
          ),
        ),
        icon: const Icon(
          Icons.snooze_rounded,
          size: 28,
        ),
        label: const Text(
          'RECORDARME EN 5 MINUTOS',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  // =========================================================
  // BOTÓN OMITIR
  // =========================================================

  Widget _buildSkipButton(
      ThemeData theme,
      ) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: TextButton.icon(
        onPressed: _isProcessing
            ? null
            : _skipMedication,
        style: TextButton.styleFrom(
          foregroundColor:
          theme.colorScheme.error,
          shape: RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(
              18,
            ),
          ),
        ),
        icon: const Icon(
          Icons.cancel_outlined,
          size: 27,
        ),
        label: const Text(
          'OMITIR MEDICAMENTO',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  // =========================================================
  // PIE DE PANTALLA
  // =========================================================

  Widget _buildFooter(
      ThemeData theme,
      ) {
    return Row(
      mainAxisAlignment:
      MainAxisAlignment.center,
      children: [
        Icon(
          Icons.health_and_safety_outlined,
          size: 20,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Text(
          'Tu salud es importante',
          style: theme
              .textTheme
              .bodyMedium
              ?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ===========================================================
// OPCIÓN DE MOTIVO DE OMISIÓN
// ===========================================================

class _ReasonOption extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;

  const _ReasonOption({
    required this.icon,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme =
    Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(
        bottom: 10,
      ),
      child: Material(
        color: theme
            .colorScheme
            .surfaceContainerHighest
            .withValues(
          alpha: 0.55,
        ),
        borderRadius:
        BorderRadius.circular(
          16,
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius:
          BorderRadius.circular(
            16,
          ),
          child: Padding(
            padding:
            const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 16,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color:
                  theme.colorScheme.primary,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    text,
                    style: theme
                        .textTheme
                        .bodyLarge
                        ?.copyWith(
                      fontWeight:
                      FontWeight.w600,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}