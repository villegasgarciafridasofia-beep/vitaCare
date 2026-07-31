import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/medication_model.dart';
import '../../services/medication_service.dart';
import 'add_medication_view.dart';

enum MedicationFilter {
  all,
  active,
  paused,
}

class MedicationsView extends StatefulWidget {
  const MedicationsView({super.key});

  @override
  State<MedicationsView> createState() => _MedicationsViewState();
}

class _MedicationsViewState extends State<MedicationsView> {
  final MedicationService medicationService = MedicationService();
  final TextEditingController searchController = TextEditingController();

  List<MedicationModel> medications = [];

  bool isLoading = true;
  bool isProcessing = false;
  String? errorMessage;

  MedicationFilter selectedFilter = MedicationFilter.all;
  String searchText = '';

  static const Color primaryColor = Color(0xFF2F6B5B);
  static const Color primaryLight = Color(0xFFE7F3ED);
  static const Color backgroundColor = Color(0xFFF5F8F6);
  static const Color textPrimary = Color(0xFF1F3D35);
  static const Color textSecondary = Color(0xFF66756F);

  @override
  void initState() {
    super.initState();
    loadMedications();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  List<MedicationModel> get filteredMedications {
    return medications.where((medication) {
      final normalizedSearch = searchText.trim().toLowerCase();

      final matchesSearch =
          normalizedSearch.isEmpty ||
              medication.name.toLowerCase().contains(normalizedSearch) ||
              medication.category.toLowerCase().contains(normalizedSearch) ||
              medication.medicineForm.toLowerCase().contains(normalizedSearch);

      final matchesFilter = switch (selectedFilter) {
        MedicationFilter.all => true,
        MedicationFilter.active => medication.active,
        MedicationFilter.paused => !medication.active,
      };

      return matchesSearch && matchesFilter;
    }).toList();
  }

  int get activeCount {
    return medications.where((medication) => medication.active).length;
  }

  int get pausedCount {
    return medications.where((medication) => !medication.active).length;
  }

  Future<void> openEditMedication(
      MedicationModel medication,
      ) async {
    final bool? result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddMedicationView(
          medication: medication,
        ),
      ),
    );

    if (result == true) {
      await loadMedications();
    }
  }

  Future<void> openAddMedication() async {
    final bool? result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const AddMedicationView(),
      ),
    );

    if (result == true) {
      await loadMedications();
    }
  }

  Future<void> loadMedications() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;

    if (firebaseUser == null) {
      if (!mounted) return;

      setState(() {
        medications = [];
        isLoading = false;
        errorMessage = 'No hay un usuario autenticado.';
      });

      return;
    }

    try {
      if (mounted) {
        setState(() {
          isLoading = true;
          errorMessage = null;
        });
      }

      final result = await medicationService.getPatientMedications(
        firebaseUser.uid,
      );

      result.sort((a, b) {
        if (a.active != b.active) {
          return a.active ? -1 : 1;
        }

        return b.createdAt.compareTo(a.createdAt);
      });

      if (!mounted) return;

      setState(() {
        medications = result;
        isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = 'No se pudieron cargar los medicamentos.';
      });

      showMessage(
        'Error al cargar medicamentos: $error',
        isError: true,
      );
    }
  }

  Future<void> refreshMedications() async {
    await loadMedications();
  }

  void showMessage(
      String message, {
        bool isError = false,
      }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        backgroundColor: isError
            ? const Color(0xFF8B2D2D)
            : primaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_outline_rounded,
              color: Colors.white,
            ),
            const SizedBox(width: 10),
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

  String formatDate(DateTime? date) {
    if (date == null) {
      return 'Sin fecha';
    }

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String formatTime12Hours(String time) {
    final parts = time.split(':');

    if (parts.length != 2) {
      return time;
    }

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);

    if (hour == null || minute == null) {
      return time;
    }

    final period = hour >= 12 ? 'p. m.' : 'a. m.';
    final hour12 = hour % 12 == 0 ? 12 : hour % 12;

    return '$hour12:${minute.toString().padLeft(2, '0')} $period';
  }

  DateTime? getNextDoseDateTime(MedicationModel medication) {
    if (!medication.active || medication.times.isEmpty) {
      return null;
    }

    final now = DateTime.now();
    final sortedTimes = List<String>.from(medication.times)..sort();

    for (final time in sortedTimes) {
      final parts = time.split(':');

      if (parts.length != 2) continue;

      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);

      if (hour == null || minute == null) continue;

      final candidate = DateTime(
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      if (candidate.isAfter(now)) {
        return candidate;
      }
    }

    final firstTime = sortedTimes.first.split(':');

    if (firstTime.length != 2) {
      return null;
    }

    final firstHour = int.tryParse(firstTime[0]);
    final firstMinute = int.tryParse(firstTime[1]);

    if (firstHour == null || firstMinute == null) {
      return null;
    }

    return DateTime(
      now.year,
      now.month,
      now.day + 1,
      firstHour,
      firstMinute,
    );
  }

  String getNextDoseLabel(MedicationModel medication) {
    if (!medication.active) {
      return 'Tratamiento pausado';
    }

    final nextDose = getNextDoseDateTime(medication);

    if (nextDose == null) {
      return 'Sin horario próximo';
    }

    final now = DateTime.now();
    final isToday =
        nextDose.year == now.year &&
            nextDose.month == now.month &&
            nextDose.day == now.day;

    final time =
        '${nextDose.hour.toString().padLeft(2, '0')}:'
        '${nextDose.minute.toString().padLeft(2, '0')}';

    return isToday
        ? 'Próxima toma: ${formatTime12Hours(time)}'
        : 'Próxima toma: mañana, ${formatTime12Hours(time)}';
  }

  Color getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'alta':
        return const Color(0xFFB54444);
      case 'media':
        return const Color(0xFFB87A21);
      case 'baja':
        return const Color(0xFF3F7D5A);
      default:
        return Colors.blueGrey;
    }
  }

  IconData getMedicineIcon(String medicineForm) {
    switch (medicineForm.toLowerCase()) {
      case 'jarabe':
      case 'solución oral':
        return Icons.local_drink_outlined;
      case 'gotas':
        return Icons.water_drop_outlined;
      case 'inyección':
        return Icons.vaccines_outlined;
      case 'inhalador':
        return Icons.air_outlined;
      case 'crema':
      case 'pomada':
        return Icons.spa_outlined;
      default:
        return Icons.medication_outlined;
    }
  }

  Future<void> toggleMedicationStatus(
      MedicationModel medication,
      ) async {
    if (isProcessing) return;

    final newStatus = !medication.active;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          icon: Icon(
            newStatus
                ? Icons.play_circle_outline_rounded
                : Icons.pause_circle_outline_rounded,
            color: primaryColor,
            size: 42,
          ),
          title: Text(
            newStatus
                ? 'Reactivar medicamento'
                : 'Pausar medicamento',
          ),
          content: Text(
            newStatus
                ? '¿Deseas reactivar el tratamiento de ${medication.name}?'
                : '¿Deseas pausar temporalmente el tratamiento de ${medication.name}?',
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: Text(
                newStatus ? 'Reactivar' : 'Pausar',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      setState(() {
        isProcessing = true;
      });

      if (newStatus) {
        await medicationService.activateMedication(
          medication.id,
        );
      } else {
        await medicationService.deactivateMedication(
          medication.id,
        );
      }

      if (!mounted) return;

      showMessage(
        newStatus
            ? 'Medicamento reactivado correctamente.'
            : 'Medicamento pausado correctamente.',
      );

      await loadMedications();
    } catch (error) {
      if (!mounted) return;

      showMessage(
        'No se pudo actualizar el medicamento: $error',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          isProcessing = false;
        });
      }
    }
  }

  Future<void> confirmDeleteMedication(
      MedicationModel medication,
      ) async {
    if (isProcessing) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          icon: const Icon(
            Icons.warning_amber_rounded,
            color: Color(0xFFB54444),
            size: 44,
          ),
          title: const Text('Eliminar medicamento'),
          content: Text(
            '¿Estás seguro de eliminar ${medication.name}?\n\n'
                'Esta acción no se puede deshacer.',
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancelar'),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFB54444),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              icon: const Icon(Icons.delete_outline_rounded),
              label: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      setState(() {
        isProcessing = true;
      });

      await medicationService.deleteMedication(
        medication.id,
      );

      if (!mounted) return;

      showMessage(
        'Medicamento eliminado correctamente.',
      );

      await loadMedications();
    } catch (error) {
      if (!mounted) return;

      showMessage(
        'No se pudo eliminar el medicamento: $error',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          isProcessing = false;
        });
      }
    }
  }

  Future<void> showMedicationDetails(
      MedicationModel medication,
      ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.88,
          minChildSize: 0.58,
          maxChildSize: 0.96,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 48,
                    height: 5,
                    margin: const EdgeInsets.only(
                      top: 12,
                      bottom: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFCCD6D1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(
                        20,
                        6,
                        20,
                        32,
                      ),
                      children: [
                        _buildDetailsHeader(medication),
                        const SizedBox(height: 18),
                        _buildNextDosePanel(medication),
                        const SizedBox(height: 16),
                        _detailSection(
                          title: 'Tratamiento',
                          icon: Icons.assignment_outlined,
                          children: [
                            _detailRow(
                              'Categoría',
                              medication.category,
                            ),
                            _detailRow(
                              'Prioridad',
                              medication.priority,
                            ),
                            _detailRow(
                              'Motivo',
                              medication.treatmentReason.trim().isEmpty
                                  ? 'No especificado'
                                  : medication.treatmentReason,
                            ),
                            _detailRow(
                              'Médico tratante',
                              medication.doctorName.trim().isEmpty
                                  ? 'No especificado'
                                  : medication.doctorName,
                            ),
                          ],
                        ),
                        _detailSection(
                          title: 'Frecuencia y horarios',
                          icon: Icons.schedule_outlined,
                          children: [
                            _detailRow(
                              'Frecuencia',
                              medication.frequency,
                            ),
                            _detailRow(
                              'Instrucciones',
                              medication.instructions,
                            ),
                            _detailRow(
                              'Horarios',
                              medication.times.isEmpty
                                  ? 'Sin horarios'
                                  : medication.times
                                  .map(formatTime12Hours)
                                  .join(', '),
                            ),
                          ],
                        ),
                        _detailSection(
                          title: 'Vigencia',
                          icon: Icons.calendar_month_outlined,
                          children: [
                            _detailRow(
                              'Fecha de inicio',
                              formatDate(medication.startDate),
                            ),
                            _detailRow(
                              'Fecha de finalización',
                              medication.endDate == null
                                  ? 'Sin fecha definida'
                                  : formatDate(medication.endDate),
                            ),
                          ],
                        ),
                        _detailSection(
                          title: 'Control y seguridad',
                          icon: Icons.health_and_safety_outlined,
                          children: [
                            _detailRow(
                              'Medicamento controlado',
                              medication.isControlled ? 'Sí' : 'No',
                            ),
                            _detailRow(
                              'Requiere receta',
                              medication.requiresPrescription
                                  ? 'Sí'
                                  : 'No',
                            ),
                            _detailRow(
                              'Supervisión del cuidador',
                              medication.requiresCaregiverSupervision
                                  ? 'Sí'
                                  : 'No',
                            ),
                          ],
                        ),
                        _detailSection(
                          title: 'Observaciones',
                          icon: Icons.notes_outlined,
                          children: [
                            Text(
                              medication.observations.trim().isEmpty
                                  ? 'No se agregaron observaciones.'
                                  : medication.observations,
                              style: const TextStyle(
                                color: textSecondary,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: FilledButton.icon(
                            onPressed: isProcessing
                                ? null
                                : () async {
                              Navigator.pop(sheetContext);
                              await openEditMedication(
                                medication,
                              );
                            },
                            icon: const Icon(
                              Icons.edit_outlined,
                            ),
                            label: const Text(
                              'Editar medicamento',
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: OutlinedButton.icon(
                            onPressed: isProcessing
                                ? null
                                : () async {
                              Navigator.pop(sheetContext);
                              await toggleMedicationStatus(
                                medication,
                              );
                            },
                            icon: Icon(
                              medication.active
                                  ? Icons.pause_circle_outline
                                  : Icons.play_circle_outline,
                            ),
                            label: Text(
                              medication.active
                                  ? 'Pausar tratamiento'
                                  : 'Reactivar tratamiento',
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor:
                              const Color(0xFFB54444),
                              side: const BorderSide(
                                color: Color(0xFFB54444),
                              ),
                            ),
                            onPressed: isProcessing
                                ? null
                                : () async {
                              Navigator.pop(sheetContext);
                              await confirmDeleteMedication(
                                medication,
                              );
                            },
                            icon: const Icon(
                              Icons.delete_outline,
                            ),
                            label: const Text(
                              'Eliminar medicamento',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailsHeader(
      MedicationModel medication,
      ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: medication.active
                ? primaryLight
                : const Color(0xFFE6EAE8),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            getMedicineIcon(medication.medicineForm),
            color: medication.active
                ? primaryColor
                : textSecondary,
            size: 32,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                medication.name,
                style: const TextStyle(
                  color: textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '${medication.doseQuantity} '
                    '${medication.doseUnit} · '
                    '${medication.medicineForm}',
                style: const TextStyle(
                  color: textSecondary,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 9),
              buildStatusBadge(medication),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNextDosePanel(
      MedicationModel medication,
      ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: medication.active
            ? primaryLight
            : const Color(0xFFE8ECEA),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: medication.active
              ? const Color(0xFFC7DFD2)
              : const Color(0xFFD6DDDA),
        ),
      ),
      child: Row(
        children: [
          Icon(
            medication.active
                ? Icons.alarm_rounded
                : Icons.notifications_off_outlined,
            color: medication.active
                ? primaryColor
                : textSecondary,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              getNextDoseLabel(medication),
              style: TextStyle(
                color: medication.active
                    ? textPrimary
                    : textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFE3EAE6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: primaryColor,
                  size: 21,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          ...children,
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 125,
            child: Text(
              label,
              style: const TextStyle(
                color: textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildStatusBadge(
      MedicationModel medication,
      ) {
    final active = medication.active;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: active
            ? const Color(0xFFE3F4E9)
            : const Color(0xFFE6EAE8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        active ? 'Activo' : 'Pausado',
        style: TextStyle(
          color: active
              ? const Color(0xFF34714E)
              : textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget buildSummarySection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16,
        18,
        16,
        14,
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.circular(26),
            ),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: const Icon(
                    Icons.medication_liquid_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Control de medicamentos',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '$activeCount activos · '
                            '$pausedCount pausados',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.86),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: 'Agregar medicamento',
                  onPressed: openAddMedication,
                  icon: const Icon(Icons.add_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: primaryColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: searchController,
            onChanged: (value) {
              setState(() {
                searchText = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'Buscar medicamento...',
              prefixIcon: const Icon(
                Icons.search_rounded,
              ),
              suffixIcon: searchText.isEmpty
                  ? null
                  : IconButton(
                tooltip: 'Limpiar búsqueda',
                onPressed: () {
                  searchController.clear();

                  setState(() {
                    searchText = '';
                  });
                },
                icon: const Icon(
                  Icons.close_rounded,
                ),
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(
                  color: Color(0xFFE1E9E5),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(
                  color: primaryColor,
                  width: 1.6,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildFilterButton(
                  label: 'Todos',
                  count: medications.length,
                  filter: MedicationFilter.all,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildFilterButton(
                  label: 'Activos',
                  count: activeCount,
                  filter: MedicationFilter.active,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildFilterButton(
                  label: 'Pausados',
                  count: pausedCount,
                  filter: MedicationFilter.paused,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton({
    required String label,
    required int count,
    required MedicationFilter filter,
  }) {
    final selected = selectedFilter == filter;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        setState(() {
          selectedFilter = filter;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 11,
        ),
        decoration: BoxDecoration(
          color: selected ? primaryLight : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? primaryColor
                : const Color(0xFFE1E9E5),
          ),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                color: selected
                    ? primaryColor
                    : textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: selected
                    ? primaryColor
                    : textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildMedicationCard(
      MedicationModel medication,
      ) {
    final priorityColor =
    getPriorityColor(medication.priority);

    return Container(
      margin: const EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: 14,
      ),
      decoration: BoxDecoration(
        color: medication.active
            ? Colors.white
            : const Color(0xFFF0F2F1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: medication.active
              ? const Color(0xFFE2EAE6)
              : const Color(0xFFDDE2DF),
        ),
        boxShadow: medication.active
            ? [
          BoxShadow(
            color: primaryColor.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ]
            : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            showMedicationDetails(medication);
          },
          child: Padding(
            padding: const EdgeInsets.all(17),
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: medication.active
                            ? primaryLight
                            : const Color(0xFFE0E5E2),
                        borderRadius:
                        BorderRadius.circular(17),
                      ),
                      child: Icon(
                        getMedicineIcon(
                          medication.medicineForm,
                        ),
                        color: medication.active
                            ? primaryColor
                            : textSecondary,
                        size: 27,
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Text(
                            medication.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: medication.active
                                  ? textPrimary
                                  : textSecondary,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '${medication.doseQuantity} '
                                '${medication.doseUnit} · '
                                '${medication.medicineForm}',
                            style: const TextStyle(
                              color: textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    PopupMenuButton<String>(
                      enabled: !isProcessing,
                      tooltip: 'Opciones',
                      shape: RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(18),
                      ),
                      onSelected: (value) async {
                        if (value == 'edit') {
                          await openEditMedication(
                            medication,
                          );
                          return;
                        }

                        if (value == 'status') {
                          await toggleMedicationStatus(
                            medication,
                          );
                          return;
                        }

                        if (value == 'delete') {
                          await confirmDeleteMedication(
                            medication,
                          );
                        }
                      },
                      itemBuilder: (context) {
                        return [
                          const PopupMenuItem<String>(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.edit_outlined,
                                  color: primaryColor,
                                ),
                                SizedBox(width: 10),
                                Text('Editar'),
                              ],
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'status',
                            child: Row(
                              children: [
                                Icon(
                                  medication.active
                                      ? Icons
                                      .pause_circle_outline
                                      : Icons
                                      .play_circle_outline,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  medication.active
                                      ? 'Pausar'
                                      : 'Reactivar',
                                ),
                              ],
                            ),
                          ),
                          const PopupMenuDivider(),
                          const PopupMenuItem<String>(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.delete_outline,
                                  color: Color(0xFFB54444),
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'Eliminar',
                                  style: TextStyle(
                                    color:
                                    Color(0xFFB54444),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ];
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: medication.active
                        ? primaryLight
                        : const Color(0xFFE4E8E6),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        medication.active
                            ? Icons.alarm_rounded
                            : Icons
                            .notifications_off_outlined,
                        color: medication.active
                            ? primaryColor
                            : textSecondary,
                        size: 20,
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          getNextDoseLabel(medication),
                          style: TextStyle(
                            color: medication.active
                                ? textPrimary
                                : textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.repeat_rounded,
                      size: 18,
                      color: textSecondary,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        medication.frequency,
                        style: const TextStyle(
                          color: textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                Row(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      size: 18,
                      color: textSecondary,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        medication.times.isEmpty
                            ? 'Sin horarios'
                            : medication.times
                            .map(formatTime12Hours)
                            .join(' · '),
                        style: const TextStyle(
                          color: textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 13),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildLabelChip(
                      label:
                      'Prioridad ${medication.priority}',
                      foreground: priorityColor,
                      background:
                      priorityColor.withOpacity(0.11),
                    ),
                    buildStatusBadge(medication),
                    if (medication.isControlled)
                      _buildLabelChip(
                        label: 'Controlado',
                        foreground:
                        const Color(0xFF9B3E3E),
                        background:
                        const Color(0xFFF9E5E5),
                      ),
                    if (medication
                        .requiresCaregiverSupervision)
                      _buildLabelChip(
                        label: 'Con supervisión',
                        foreground:
                        const Color(0xFF3E668B),
                        background:
                        const Color(0xFFE6EFF7),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabelChip({
    required String label,
    required Color foreground,
    required Color background,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget buildLoadingState() {
    return const SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: CircularProgressIndicator(
          color: primaryColor,
        ),
      ),
    );
  }

  Widget buildErrorState() {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: const Color(0xFFFCE8E8),
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                size: 44,
                color: Color(0xFFB54444),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No pudimos cargar tus medicamentos',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textPrimary,
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage ??
                  'Revisa tu conexión e inténtalo nuevamente.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: loadMedications,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Intentar nuevamente'),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildEmptyState({
    required bool isSearchResult,
  }) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          28,
          30,
          28,
          70,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 98,
              height: 98,
              decoration: BoxDecoration(
                color: primaryLight,
                borderRadius: BorderRadius.circular(32),
              ),
              child: Icon(
                isSearchResult
                    ? Icons.search_off_rounded
                    : Icons.medication_outlined,
                size: 48,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 22),
            Text(
              isSearchResult
                  ? 'No encontramos resultados'
                  : 'Aún no tienes medicamentos',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 9),
            Text(
              isSearchResult
                  ? 'Prueba con otro nombre o cambia el filtro seleccionado.'
                  : 'Registra tu primer medicamento para organizar tus horarios y tratamientos.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: textSecondary,
                height: 1.45,
              ),
            ),
            if (!isSearchResult) ...[
              const SizedBox(height: 22),
              FilledButton.icon(
                onPressed: openAddMedication,
                icon: const Icon(Icons.add_rounded),
                label: const Text(
                  'Agregar medicamento',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleMedications = filteredMedications;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Mis medicamentos',
          style: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: primaryColor,
        surfaceTintColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed:
            isProcessing ? null : refreshMedications,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 5),
        ],
      ),
      floatingActionButton: medications.isEmpty
          ? null
          : FloatingActionButton.extended(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        onPressed:
        isProcessing ? null : openAddMedication,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Agregar',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: RefreshIndicator(
        color: primaryColor,
        onRefresh: refreshMedications,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            if (!isLoading &&
                errorMessage == null &&
                medications.isNotEmpty)
              SliverToBoxAdapter(
                child: buildSummarySection(),
              ),
            if (isLoading)
              buildLoadingState()
            else if (errorMessage != null)
              buildErrorState()
            else if (medications.isEmpty)
                buildEmptyState(
                  isSearchResult: false,
                )
              else if (visibleMedications.isEmpty)
                  buildEmptyState(
                    isSearchResult: true,
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (context, index) {
                        return buildMedicationCard(
                          visibleMedications[index],
                        );
                      },
                      childCount: visibleMedications.length,
                    ),
                  ),
            const SliverToBoxAdapter(
              child: SizedBox(height: 95),
            ),
          ],
        ),
      ),
    );
  }
}