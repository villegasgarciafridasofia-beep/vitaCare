import 'package:flutter/material.dart';

import '../../models/medication_log_model.dart';
import '../../services/medication_log_service.dart';

enum MedicationAlarmResult {
  taken,
  snoozed,
  helpRequested,
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
    with SingleTickerProviderStateMixin {
  final MedicationLogService _logService =
  MedicationLogService();

  late final AnimationController _holdController;

  bool _isProcessing = false;
  bool _isHolding = false;

  @override
  void initState() {
    super.initState();

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
  }

  @override
  void dispose() {
    _holdController.dispose();
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Medicamento registrado como tomado.',
          ),
        ),
      );

      Navigator.of(context).pop(
        MedicationAlarmResult.taken,
      );
    } catch (error) {
      _holdController.reset();

      if (!mounted) return;

      setState(() {
        _isProcessing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No fue posible registrar la toma: $error',
          ),
        ),
      );
    }
  }

  Future<void> _snoozeMedication() async {
    if (_isProcessing) return;

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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No fue posible aplazar la alarma: $error',
          ),
        ),
      );
    }
  }

  void _requestHelp() {
    if (_isProcessing) return;

    Navigator.of(context).pop(
      MedicationAlarmResult.helpRequested,
    );
  }

  void _startHolding() {
    if (_isProcessing) return;

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

    _holdController.reverse();
  }

  String get _doseText {
    final dose = widget.medicationLog.dose.trim();

    if (dose.isEmpty) {
      return 'Dosis indicada';
    }

    return dose;
  }

  String get _instructionsText {
    final instructions =
    widget.medicationLog.instructions.trim();

    if (instructions.isEmpty) {
      return 'Sigue las indicaciones de tu tratamiento.';
    }

    return instructions;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 20,
            ),
            child: Column(
              children: [
                _buildHeader(theme),

                const SizedBox(height: 20),

                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildAlarmIcon(theme),

                        const SizedBox(height: 20),

                        Text(
                          'ES HORA DE TU MEDICAMENTO',
                          textAlign: TextAlign.center,
                          style:
                          theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 24),

                        _buildMedicationCard(theme),

                        const SizedBox(height: 28),

                        _buildHoldButton(theme),

                        const SizedBox(height: 18),

                        _buildSnoozeButton(),

                        const SizedBox(height: 12),

                        _buildHelpButton(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.favorite_rounded,
          color: theme.colorScheme.primary,
          size: 28,
        ),
        const SizedBox(width: 10),
        Text(
          'VitaCare AI',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildAlarmIcon(ThemeData theme) {
    return Container(
      width: 105,
      height: 105,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: theme.colorScheme.primaryContainer,
      ),
      child: Icon(
        Icons.alarm_rounded,
        size: 58,
        color: theme.colorScheme.primary,
      ),
    );
  }

  Widget _buildMedicationCard(ThemeData theme) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            Icon(
              Icons.medication_rounded,
              size: 54,
              color: theme.colorScheme.primary,
            ),

            const SizedBox(height: 14),

            Text(
              widget.medicationLog.medicationName,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            Text(
              _doseText,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 14),

            Text(
              _instructionsText,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),

            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                color: theme.colorScheme.primaryContainer,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.medicationLog.scheduledTime,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
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

  Widget _buildHoldButton(ThemeData theme) {
    return AnimatedBuilder(
      animation: _holdController,
      builder: (context, child) {
        final progress = _holdController.value;

        return GestureDetector(
          onLongPressStart: (_) => _startHolding(),
          onLongPressEnd: (_) => _cancelHolding(),
          onLongPressCancel: _cancelHolding,
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(
              minHeight: 92,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              color: theme.colorScheme.primaryContainer,
              border: Border.all(
                color: theme.colorScheme.primary,
                width: 2,
              ),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progress,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: theme.colorScheme.primary
                            .withValues(alpha: 0.22),
                      ),
                    ),
                  ),
                ),

                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    child: Row(
                      mainAxisAlignment:
                      MainAxisAlignment.center,
                      children: [
                        if (_isProcessing)
                          const SizedBox(
                            width: 30,
                            height: 30,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                            ),
                          )
                        else
                          Icon(
                            Icons.check_circle_rounded,
                            size: 38,
                            color: theme.colorScheme.primary,
                          ),

                        const SizedBox(width: 14),

                        Flexible(
                          child: Column(
                            mainAxisAlignment:
                            MainAxisAlignment.center,
                            children: [
                              Text(
                                'Ya tomé mi medicamento',
                                textAlign: TextAlign.center,
                                style: theme
                                    .textTheme.titleMedium
                                    ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _isHolding
                                    ? 'Continúa presionando...'
                                    : 'Mantén presionado 2 segundos',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium,
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

  Widget _buildSnoozeButton() {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: OutlinedButton.icon(
        onPressed:
        _isProcessing ? null : _snoozeMedication,
        icon: const Icon(
          Icons.snooze_rounded,
        ),
        label: const Text(
          'Recordarme en 5 minutos',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildHelpButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: TextButton.icon(
        onPressed: _isProcessing ? null : _requestHelp,
        icon: const Icon(
          Icons.support_agent_rounded,
        ),
        label: const Text(
          'Necesito ayuda',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}