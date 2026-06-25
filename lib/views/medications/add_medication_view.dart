import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/medication_model.dart';
import '../../services/medication_service.dart';

class AddMedicationView extends StatefulWidget {
  const AddMedicationView({super.key});

  @override
  State<AddMedicationView> createState() => _AddMedicationViewState();
}

class _AddMedicationViewState extends State<AddMedicationView> {
  final MedicationService medicationService = MedicationService();

  final nameController = TextEditingController();
  final treatmentReasonController = TextEditingController();
  final doctorNameController = TextEditingController();
  final observationsController = TextEditingController();

  final categories = [
    'Analgésico',
    'Antibiótico',
    'Antiinflamatorio',
    'Antidiabético',
    'Antihipertensivo',
    'Controlado',
    'Psiquiátrico',
    'Cardiovascular',
    'Vitaminas',
    'Otro',
  ];

  final medicineForms = [
    'Tableta',
    'Cápsula',
    'Jarabe',
    'Gotas',
    'Inyección',
    'Inhalador',
    'Crema',
    'Pomada',
    'Solución oral',
  ];

  final doseQuantities = [1, 2, 3, 4, 5, 10, 15, 20];

  final priorities = ['Alta', 'Media', 'Baja'];

  final frequencies = [
    'Una vez al día',
    'Cada 6 horas',
    'Cada 8 horas',
    'Cada 12 horas',
    'Cada 24 horas',
    'Antes de dormir',
    'Según indicación médica',
    'Solo cuando sea necesario',
  ];

  final instructionsOptions = [
    'Tomar después de alimentos',
    'Tomar antes de alimentos',
    'Tomar con agua',
    'Tomar en ayunas',
    'No mezclar con alcohol',
    'Aplicar sobre piel limpia',
    'Según indicación médica',
  ];

  String? selectedCategory;
  String? selectedMedicineForm;
  int? selectedDoseQuantity;
  String? selectedDoseUnit;
  String? selectedPriority;
  String? selectedFrequency;
  String? selectedInstruction;

  bool isControlled = false;
  bool requiresPrescription = false;
  bool requiresCaregiverSupervision = false;
  bool isLoading = false;

  DateTime? startDate;
  DateTime? endDate;
  List<String> selectedTimes = [];

  List<String> getDoseUnitsByForm(String? form) {
    switch (form) {
      case 'Tableta':
        return ['tableta', 'mg', 'g'];
      case 'Cápsula':
        return ['cápsula', 'mg', 'g'];
      case 'Jarabe':
      case 'Solución oral':
        return ['ml', 'cucharada', 'cucharadita'];
      case 'Gotas':
        return ['gotas', 'ml'];
      case 'Inyección':
        return ['ml', 'mg'];
      case 'Inhalador':
        return ['puff', 'aplicación'];
      case 'Crema':
      case 'Pomada':
        return ['aplicación', 'g'];
      default:
        return ['mg', 'ml', 'tableta', 'cápsula'];
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    treatmentReasonController.dispose();
    doctorNameController.dispose();
    observationsController.dispose();
    super.dispose();
  }

  Future<void> pickStartDate() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: DateTime.now(),
    );

    if (date != null) {
      setState(() {
        startDate = date;
      });
    }
  }

  Future<void> pickEndDate() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      initialDate: DateTime.now(),
    );

    if (date != null) {
      setState(() {
        endDate = date;
      });
    }
  }

  Future<void> addTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime == null) return;

    final hour = pickedTime.hour.toString().padLeft(2, '0');
    final minute = pickedTime.minute.toString().padLeft(2, '0');
    final formattedTime = '$hour:$minute';

    if (!selectedTimes.contains(formattedTime)) {
      setState(() {
        selectedTimes.add(formattedTime);
        selectedTimes.sort();
      });
    }
  }

  void removeTime(String time) {
    setState(() {
      selectedTimes.remove(time);
    });
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String formatDate(DateTime? date) {
    if (date == null) return 'Seleccionar fecha';
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> saveMedication() async {
    if (nameController.text.trim().isEmpty) {
      showMessage('Escribe el nombre del medicamento');
      return;
    }

    if (selectedCategory == null) {
      showMessage('Selecciona la categoría');
      return;
    }

    if (selectedMedicineForm == null) {
      showMessage('Selecciona la presentación');
      return;
    }

    if (selectedDoseQuantity == null) {
      showMessage('Selecciona la cantidad de dosis');
      return;
    }

    if (selectedDoseUnit == null) {
      showMessage('Selecciona la unidad de dosis');
      return;
    }

    if (selectedPriority == null) {
      showMessage('Selecciona la prioridad');
      return;
    }

    if (selectedFrequency == null) {
      showMessage('Selecciona la frecuencia');
      return;
    }

    if (selectedInstruction == null) {
      showMessage('Selecciona las instrucciones');
      return;
    }

    if (selectedTimes.isEmpty) {
      showMessage('Agrega al menos un horario');
      return;
    }

    if (startDate == null) {
      showMessage('Selecciona la fecha de inicio');
      return;
    }

    final uid = FirebaseAuth.instance.currentUser!.uid;
    final now = DateTime.now();

    final medication = MedicationModel(
      id: now.millisecondsSinceEpoch.toString(),
      patientUid: uid,
      name: nameController.text.trim(),
      category: selectedCategory!,
      medicineForm: selectedMedicineForm!,
      doseQuantity: selectedDoseQuantity!,
      doseUnit: selectedDoseUnit!,
      isControlled: isControlled,
      requiresPrescription: requiresPrescription,
      requiresCaregiverSupervision: requiresCaregiverSupervision,
      priority: selectedPriority!,
      treatmentReason: treatmentReasonController.text.trim(),
      doctorName: doctorNameController.text.trim(),
      frequency: selectedFrequency!,
      instructions: selectedInstruction!,
      times: selectedTimes,
      startDate: startDate!,
      endDate: endDate,
      observations: observationsController.text.trim(),
      active: true,
      createdAt: now,
      updatedAt: now,
    );

    try {
      setState(() {
        isLoading = true;
      });

      await medicationService.addMedication(medication);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Medicamento guardado')),
      );

      Navigator.pop(context);
    } catch (e) {
      showMessage('Error: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Widget sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.bold,
          color: Colors.teal,
        ),
      ),
    );
  }

  Widget yesNoSelector({
    required String title,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Card(
      child: SwitchListTile(
        title: Text(title),
        subtitle: Text(value ? 'Sí' : 'No'),
        value: value,
        activeColor: Colors.teal,
        onChanged: onChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final doseUnits = getDoseUnitsByForm(selectedMedicineForm);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FB),
      appBar: AppBar(
        title: const Text('Agregar medicamento'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            sectionTitle('Información general'),

            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre del medicamento',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              value: selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Categoría',
                border: OutlineInputBorder(),
              ),
              items: categories.map((item) {
                return DropdownMenuItem(value: item, child: Text(item));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedCategory = value;

                  if (value == 'Controlado') {
                    isControlled = true;
                    requiresPrescription = true;
                    requiresCaregiverSupervision = true;
                  }
                });
              },
            ),

            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              value: selectedMedicineForm,
              decoration: const InputDecoration(
                labelText: 'Presentación',
                border: OutlineInputBorder(),
              ),
              items: medicineForms.map((item) {
                return DropdownMenuItem(value: item, child: Text(item));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedMedicineForm = value;
                  selectedDoseUnit = null;
                });
              },
            ),

            sectionTitle('Dosis'),

            DropdownButtonFormField<int>(
              value: selectedDoseQuantity,
              decoration: const InputDecoration(
                labelText: 'Cantidad',
                border: OutlineInputBorder(),
              ),
              items: doseQuantities.map((item) {
                return DropdownMenuItem(value: item, child: Text('$item'));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedDoseQuantity = value;
                });
              },
            ),

            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              value: selectedDoseUnit,
              decoration: const InputDecoration(
                labelText: selectedMedicineForm == null
                    ? 'Selecciona primero la presentación'
                    : 'Unidad',
                border: const OutlineInputBorder(),
              ),
              items: doseUnits.map((item) {
                return DropdownMenuItem(value: item, child: Text(item));
              }).toList(),
              onChanged: selectedMedicineForm == null
                  ? null
                  : (value) {
                setState(() {
                  selectedDoseUnit = value;
                });
              },
            ),

            sectionTitle('Control médico'),

            yesNoSelector(
              title: '¿Es medicamento controlado?',
              value: isControlled,
              onChanged: (value) {
                setState(() {
                  isControlled = value;

                  if (value) {
                    requiresPrescription = true;
                    requiresCaregiverSupervision = true;
                  }
                });
              },
            ),

            if (isControlled)
              const Padding(
                padding: EdgeInsets.only(top: 8, bottom: 8),
                child: Text(
                  '⚠️ Este medicamento requiere supervisión médica y debe usarse solo bajo indicación profesional.',
                  style: TextStyle(color: Colors.red),
                ),
              ),

            yesNoSelector(
              title: '¿Requiere receta médica?',
              value: requiresPrescription,
              onChanged: (value) {
                setState(() {
                  requiresPrescription = value;
                });
              },
            ),

            yesNoSelector(
              title: '¿Requiere supervisión del cuidador?',
              value: requiresCaregiverSupervision,
              onChanged: (value) {
                setState(() {
                  requiresCaregiverSupervision = value;
                });
              },
            ),

            sectionTitle('Tratamiento'),

            DropdownButtonFormField<String>(
              value: selectedPriority,
              decoration: const InputDecoration(
                labelText: 'Prioridad',
                border: OutlineInputBorder(),
              ),
              items: priorities.map((item) {
                return DropdownMenuItem(value: item, child: Text(item));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedPriority = value;
                });
              },
            ),

            const SizedBox(height: 16),

            TextField(
              controller: treatmentReasonController,
              decoration: const InputDecoration(
                labelText: 'Motivo del tratamiento',
                hintText: 'Ejemplo: hipertensión, diabetes, dolor',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: doctorNameController,
              decoration: const InputDecoration(
                labelText: 'Médico tratante',
                hintText: 'Opcional',
                border: OutlineInputBorder(),
              ),
            ),

            sectionTitle('Frecuencia e instrucciones'),

            DropdownButtonFormField<String>(
              value: selectedFrequency,
              decoration: const InputDecoration(
                labelText: 'Frecuencia',
                border: OutlineInputBorder(),
              ),
              items: frequencies.map((item) {
                return DropdownMenuItem(value: item, child: Text(item));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedFrequency = value;
                });
              },
            ),

            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              value: selectedInstruction,
              decoration: const InputDecoration(
                labelText: 'Instrucciones',
                border: OutlineInputBorder(),
              ),
              items: instructionsOptions.map((item) {
                return DropdownMenuItem(value: item, child: Text(item));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedInstruction = value;
                });
              },
            ),

            sectionTitle('Horarios'),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: selectedTimes.map((time) {
                return Chip(
                  label: Text(time),
                  deleteIcon: const Icon(Icons.close),
                  onDeleted: () => removeTime(time),
                );
              }).toList(),
            ),

            OutlinedButton.icon(
              onPressed: addTime,
              icon: const Icon(Icons.access_time),
              label: const Text('Agregar hora'),
            ),

            sectionTitle('Vigencia'),

            OutlinedButton.icon(
              onPressed: pickStartDate,
              icon: const Icon(Icons.calendar_month),
              label: Text('Fecha inicio: ${formatDate(startDate)}'),
            ),

            const SizedBox(height: 10),

            OutlinedButton.icon(
              onPressed: pickEndDate,
              icon: const Icon(Icons.event),
              label: Text('Fecha fin: ${formatDate(endDate)}'),
            ),

            sectionTitle('Observaciones'),

            TextField(
              controller: observationsController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Observaciones',
                hintText: 'Ejemplo: si presenta mareos, consultar al médico',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: isLoading ? null : saveMedication,
              child: isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Guardar medicamento'),
            ),
          ],
        ),
      ),
    );
  }
}