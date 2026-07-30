import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/medication_model.dart';
import '../../services/medication_service.dart';
import 'add_medication_view.dart';

class MedicationsView extends StatefulWidget {
  const MedicationsView({super.key});

  @override
  State<MedicationsView> createState() => _MedicationsViewState();
}

class _MedicationsViewState extends State<MedicationsView> {
  final MedicationService medicationService = MedicationService();

  List<MedicationModel> medications = [];

  bool isLoading = true;
  bool isProcessing = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadMedications();
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
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = 'No se pudieron cargar los medicamentos.';
      });

      showMessage('Error al cargar medicamentos: $e');
    }
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String formatDate(DateTime? date) {
    if (date == null) {
      return 'Sin fecha';
    }

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  Color getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'alta':
        return Colors.red;

      case 'media':
        return Colors.orange;

      case 'baja':
        return Colors.green;

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

  Future<void> openAddMedication() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddMedicationView()),
    );

    if (result == true) {
      await loadMedications();
    }
  }

  Future<void> refreshMedications() async {
    await loadMedications();
  }

  Future<void> toggleMedicationStatus(MedicationModel medication) async {
    if (isProcessing) return;

    final newStatus = !medication.active;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            newStatus ? 'Reactivar medicamento' : 'Pausar medicamento',
          ),
          content: Text(
            newStatus
                ? '¿Deseas reactivar el tratamiento de ${medication.name}?'
                : '¿Deseas pausar el tratamiento de ${medication.name}?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: Text(newStatus ? 'Reactivar' : 'Pausar'),
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
        await medicationService.activateMedication(medication.id);
      } else {
        await medicationService.deactivateMedication(medication.id);
      }

      if (!mounted) return;

      showMessage(
        newStatus
            ? 'Medicamento reactivado correctamente.'
            : 'Medicamento pausado correctamente.',
      );

      await loadMedications();
    } catch (e) {
      if (!mounted) return;

      showMessage('No se pudo actualizar el medicamento: $e');
    } finally {
      if (mounted) {
        setState(() {
          isProcessing = false;
        });
      }
    }
  }

  Future<void> confirmDeleteMedication(MedicationModel medication) async {
    if (isProcessing) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: const Icon(
            Icons.warning_amber_rounded,
            color: Colors.red,
            size: 42,
          ),
          title: const Text('Eliminar medicamento'),
          content: Text(
            '¿Estás seguro de eliminar ${medication.name}?\n\n'
                'Esta acción no se puede deshacer.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              icon: const Icon(Icons.delete_outline),
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

      await medicationService.deleteMedication(medication.id);

      if (!mounted) return;

      showMessage('Medicamento eliminado correctamente.');

      await loadMedications();
    } catch (e) {
      if (!mounted) return;

      showMessage('No se pudo eliminar el medicamento: $e');
    } finally {
      if (mounted) {
        setState(() {
          isProcessing = false;
        });
      }
    }
  }

  Future<void> showMedicationDetails(MedicationModel medication) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.86,
          minChildSize: 0.55,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF4F8FB),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 46,
                    height: 5,
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: medication.active
                                  ? Colors.teal.shade100
                                  : Colors.grey.shade300,
                              child: Icon(
                                getMedicineIcon(medication.medicineForm),
                                color: medication.active
                                    ? Colors.teal
                                    : Colors.grey.shade700,
                                size: 30,
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
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${medication.doseQuantity} '
                                        '${medication.doseUnit} • '
                                        '${medication.medicineForm}',
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: medication.active
                                    ? Colors.green.shade100
                                    : Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                medication.active ? 'Activo' : 'Pausado',
                                style: TextStyle(
                                  color: medication.active
                                      ? Colors.green.shade800
                                      : Colors.grey.shade800,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        _detailSection(
                          title: 'Tratamiento',
                          icon: Icons.assignment_outlined,
                          children: [
                            _detailRow('Categoría', medication.category),
                            _detailRow('Prioridad', medication.priority),
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
                            _detailRow('Frecuencia', medication.frequency),
                            _detailRow(
                              'Instrucciones',
                              medication.instructions,
                            ),
                            _detailRow(
                              'Horarios',
                              medication.times.isEmpty
                                  ? 'Sin horarios'
                                  : medication.times.join(', '),
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
                              medication.requiresPrescription ? 'Sí' : 'No',
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
                              style: TextStyle(
                                color: Colors.grey.shade800,
                                height: 1.45,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: isProcessing
                                ? null
                                : () async {
                              Navigator.pop(sheetContext);

                              await toggleMedicationStatus(medication);
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
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                            ),
                            onPressed: isProcessing
                                ? null
                                : () async {
                              Navigator.pop(sheetContext);

                              await confirmDeleteMedication(medication);
                            },
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('Eliminar medicamento'),
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

  Widget _detailSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.teal),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 135,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildStatusBadge(MedicationModel medication) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: medication.active ? Colors.green.shade100 : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        medication.active ? 'Activo' : 'Pausado',
        style: TextStyle(
          color: medication.active
              ? Colors.green.shade800
              : Colors.grey.shade800,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget buildMedicationCard(MedicationModel medication) {
    final priorityColor = getPriorityColor(medication.priority);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: medication.active ? 2 : 0,
      color: medication.active ? Colors.white : Colors.grey.shade100,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          showMedicationDetails(medication);
        },
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: medication.active
                        ? Colors.teal.shade100
                        : Colors.grey.shade300,
                    child: Icon(
                      getMedicineIcon(medication.medicineForm),
                      color: medication.active
                          ? Colors.teal
                          : Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                medication.name,
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: medication.active
                                      ? Colors.black87
                                      : Colors.grey.shade700,
                                ),
                              ),
                            ),
                            buildStatusBadge(medication),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '${medication.doseQuantity} '
                              '${medication.doseUnit} • '
                              '${medication.medicineForm}',
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    enabled: !isProcessing,
                    onSelected: (value) async {
                      if (value == 'edit') {
                        await openEditMedication(medication);
                        return;
                      }

                      if (value == 'status') {
                        await toggleMedicationStatus(medication);
                        return;
                      }

                      if (value == 'delete') {
                        await confirmDeleteMedication(medication);
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
                                color: Color(0xFF285F50),
                              ),
                              SizedBox(width: 10),
                              Text('Editar medicamento'),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(),
                        PopupMenuItem<String>(
                          value: 'status',
                          child: Row(
                            children: [
                              Icon(
                                medication.active
                                    ? Icons.pause_circle_outline
                                    : Icons.play_circle_outline,
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
                                color: Colors.red,
                              ),
                              SizedBox(width: 10),
                              Text(
                                'Eliminar',
                                style: TextStyle(
                                  color: Colors.red,
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
              const SizedBox(height: 14),
              Row(
                children: [
                  Icon(Icons.repeat, size: 18, color: Colors.grey.shade700),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      medication.frequency,
                      style: TextStyle(color: Colors.grey.shade800),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.access_time,
                    size: 18,
                    color: Colors.grey.shade700,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      medication.times.isEmpty
                          ? 'Sin horarios'
                          : medication.times.join(', '),
                      style: TextStyle(color: Colors.grey.shade800),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: priorityColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      'Prioridad ${medication.priority}',
                      style: TextStyle(
                        color: priorityColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (medication.isControlled)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(
                        'Controlado',
                        style: TextStyle(
                          color: Colors.red.shade800,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  if (medication.requiresCaregiverSupervision)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(
                        'Con supervisión',
                        style: TextStyle(
                          color: Colors.blue.shade800,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FB),
      appBar: AppBar(
        title: const Text('Medicamentos'),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: refreshMedications,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.teal,
        onPressed: openAddMedication,
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: refreshMedications,
        child: Builder(
          builder: (context) {
            if (isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (errorMessage != null) {
              return ListView(
                children: [
                  const SizedBox(height: 120),
                  Icon(
                    Icons.error_outline,
                    size: 70,
                    color: Colors.red.shade300,
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: loadMedications,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Intentar nuevamente'),
                    ),
                  ),
                ],
              );
            }

            if (medications.isEmpty) {
              return ListView(
                children: [
                  const SizedBox(height: 90),
                  Icon(
                    Icons.medication_outlined,
                    size: 85,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 20),
                  const Center(
                    child: Text(
                      'Todavía no tienes medicamentos registrados.',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 35),
                      child: Text(
                        'Presiona el botón + para registrar el primer medicamento.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: medications.length,
              itemBuilder: (context, index) {
                return buildMedicationCard(medications[index]);
              },
            );
          },
        ),
      ),
    );
  }
}