import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/medication_registration_service.dart';
import '../../models/medication_model.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import '../../services/medication_service.dart';
import '../../services/smart_schedule_service.dart';

class AddMedicationView extends StatefulWidget {
  final MedicationModel? medication;

  const AddMedicationView({
    super.key,
    this.medication,
  });

  bool get isEditing => medication != null;

  @override
  State<AddMedicationView> createState() =>
      _AddMedicationViewState();
}

class _AddMedicationViewState extends State<AddMedicationView> {
  final MedicationService medicationService = MedicationService();
  final FirestoreService firestoreService = FirestoreService();
  final SmartScheduleService smartScheduleService = SmartScheduleService();

  final formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final treatmentReasonController = TextEditingController();
  final doctorNameController = TextEditingController();
  final observationsController = TextEditingController();

  UserModel? currentUser;

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
  bool isLoadingUser = true;
  bool schedulesGeneratedAutomatically = false;
  bool firstDoseTakenNow = false;
  bool useRegistrationTime = true;

  DateTime? scheduleAnchorTime;
  DateTime? startDate;
  DateTime? endDate;

  List<String> selectedTimes = [];

  @override
  void initState() {
    super.initState();

    if (widget.medication != null) {
      loadMedicationData();
    }

    loadCurrentUser();
  }

  void loadMedicationData() {
    final MedicationModel medication = widget.medication!;

    nameController.text = medication.name;
    treatmentReasonController.text = medication.treatmentReason;
    doctorNameController.text = medication.doctorName;
    observationsController.text = medication.observations;

    selectedCategory = medication.category;
    selectedMedicineForm = medication.medicineForm;
    selectedDoseQuantity = medication.doseQuantity;
    selectedDoseUnit = medication.doseUnit;
    selectedPriority = medication.priority;
    selectedFrequency = medication.frequency;
    selectedInstruction = medication.instructions;

    isControlled = medication.isControlled;
    requiresPrescription = medication.requiresPrescription;
    requiresCaregiverSupervision =
        medication.requiresCaregiverSupervision;

    startDate = medication.startDate;
    endDate = medication.endDate;

    selectedTimes = List<String>.from(medication.times)..sort();
    firstDoseTakenNow = medication.firstDoseTaken;
    scheduleAnchorTime = medication.scheduleAnchorTime;
  }

  @override
  void dispose() {
    nameController.dispose();
    treatmentReasonController.dispose();
    doctorNameController.dispose();
    observationsController.dispose();
    super.dispose();
  }

  Future<void> loadCurrentUser() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;

    if (firebaseUser == null) {
      if (mounted) {
        setState(() {
          isLoadingUser = false;
        });
      }
      return;
    }

    try {
      final user = await firestoreService.getUser(firebaseUser.uid);

      if (!mounted) return;

      setState(() {
        currentUser = user;
        isLoadingUser = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoadingUser = false;
      });

      showMessage('No se pudo cargar la rutina del usuario.');
    }
  }

  List<int> getDoseQuantitiesByForm(String? form) {
    final List<int> quantities;

    switch (form) {
      case 'Jarabe':
      case 'Solución oral':
        quantities = [2, 5, 10, 15, 20];
        break;

      case 'Gotas':
        quantities = [1, 2, 3, 5, 10, 15, 20];
        break;

      case 'Inyección':
        quantities = [1, 2, 5, 10];
        break;

      default:
        quantities = [1, 2, 3, 4, 5];
    }

    if (selectedDoseQuantity != null &&
        !quantities.contains(selectedDoseQuantity)) {
      quantities.add(selectedDoseQuantity!);
      quantities.sort();
    }

    return quantities;
  }
  List<String> getDoseUnitsByForm(String? form) {
    final List<String> units;

    switch (form) {
      case 'Tableta':
        units = ['tableta', 'mg', 'g'];
        break;

      case 'Cápsula':
        units = ['cápsula', 'mg', 'g'];
        break;

      case 'Jarabe':
      case 'Solución oral':
        units = [
          'ml',
          'cucharada',
          'cucharadita',
        ];
        break;

      case 'Gotas':
        units = ['gotas', 'ml'];
        break;

      case 'Inyección':
        units = ['ml', 'mg'];
        break;

      case 'Inhalador':
        units = ['puff', 'aplicación'];
        break;

      case 'Crema':
      case 'Pomada':
        units = ['aplicación', 'g'];
        break;

      default:
        units = ['mg', 'ml'];
    }

    if (selectedDoseUnit != null &&
        selectedDoseUnit!.isNotEmpty &&
        !units.contains(selectedDoseUnit)) {
      units.add(selectedDoseUnit!);
    }

    return units;
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String formatDate(DateTime? date) {
    if (date == null) {
      return 'Seleccionar fecha';
    }

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  Future<void> pickStartDate() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: startDate ?? DateTime.now(),
    );

    if (date == null) return;

    setState(() {
      startDate = date;

      if (endDate != null && endDate!.isBefore(date)) {
        endDate = null;
      }
    });
  }

  Future<void> pickEndDate() async {
    final minimumDate = startDate ?? DateTime.now();

    final date = await showDatePicker(
      context: context,
      firstDate: minimumDate,
      lastDate: DateTime(2100),
      initialDate: endDate ?? minimumDate,
    );

    if (date == null) return;

    setState(() {
      endDate = date;
    });
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

    if (selectedTimes.contains(formattedTime)) {
      showMessage('Ese horario ya fue agregado.');
      return;
    }

    setState(() {
      selectedTimes.add(formattedTime);
      selectedTimes.sort();
      schedulesGeneratedAutomatically = false;
    });
  }

  void removeTime(String time) {
    setState(() {
      selectedTimes.remove(time);
      schedulesGeneratedAutomatically = false;
    });
  }


  int? _intervalHoursForFrequency(String? frequency) {
    switch (frequency) {
      case 'Cada 6 horas':
        return 6;
      case 'Cada 8 horas':
        return 8;
      case 'Cada 12 horas':
        return 12;
      case 'Cada 24 horas':
      case 'Una vez al día':
        return 24;
      default:
        return null;
    }
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  void generateTimesFromRegistration() {
    final intervalHours = _intervalHoursForFrequency(selectedFrequency);

    if (intervalHours == null) {
      showMessage(
        'Esta frecuencia necesita horarios manuales o basados en tu rutina.',
      );
      return;
    }

    final now = DateTime.now();
    scheduleAnchorTime = now;

    DateTime firstDose = now;

    if (firstDoseTakenNow) {
      firstDose = now.add(Duration(hours: intervalHours));
    }

    final int dosesPerDay = intervalHours >= 24 ? 1 : 24 ~/ intervalHours;
    final List<String> generatedTimes = [];

    for (int index = 0; index < dosesPerDay; index++) {
      final doseTime = firstDose.add(
        Duration(hours: intervalHours * index),
      );

      final formattedTime = _formatTime(doseTime);

      if (!generatedTimes.contains(formattedTime)) {
        generatedTimes.add(formattedTime);
      }
    }

    generatedTimes.sort();

    setState(() {
      selectedTimes = generatedTimes;
      schedulesGeneratedAutomatically = true;
      useRegistrationTime = true;
      startDate ??= DateTime(
        now.year,
        now.month,
        now.day,
      );
    });
  }

  void generateSmartTimes(String? frequency) {
    if (frequency == null) {
      setState(() {
        selectedTimes = [];
        schedulesGeneratedAutomatically = false;
      });

      return;
    }

    if (currentUser == null) {
      setState(() {
        selectedTimes = [];
        schedulesGeneratedAutomatically = false;
      });

      showMessage('No se encontró la rutina del usuario.');

      return;
    }

    final generatedTimes = smartScheduleService.generateMedicationTimes(
      frequency: frequency,
      wakeUpTime: currentUser!.wakeUpTime,
      breakfastTime: currentUser!.breakfastTime,
      lunchTime: currentUser!.lunchTime,
      dinnerTime: currentUser!.dinnerTime,
      sleepTime: currentUser!.sleepTime,
      allowNightReminders: currentUser!.allowNightReminders,
    );

    setState(() {
      selectedTimes = generatedTimes;
      schedulesGeneratedAutomatically = generatedTimes.isNotEmpty;
    });

    if (generatedTimes.isEmpty) {
      showMessage('Agrega manualmente los horarios para esta frecuencia.');
    }
  }

  Future<void> saveMedication() async {
    final isFormValid = formKey.currentState?.validate() ?? false;

    if (!isFormValid) return;

    if (selectedCategory == null ||
        selectedMedicineForm == null ||
        selectedDoseQuantity == null ||
        selectedDoseUnit == null ||
        selectedPriority == null ||
        selectedFrequency == null ||
        selectedInstruction == null) {
      showMessage('Completa todos los campos obligatorios.');
      return;
    }

    if (selectedTimes.isEmpty) {
      showMessage('Agrega al menos un horario.');
      return;
    }

    if (startDate == null) {
      showMessage('Selecciona la fecha de inicio.');
      return;
    }

    if (endDate != null && endDate!.isBefore(startDate!)) {
      showMessage('La fecha final no puede ser anterior a la fecha de inicio.');
      return;
    }

    final firebaseUser = FirebaseAuth.instance.currentUser;

    if (firebaseUser == null) {
      showMessage('No hay un usuario autenticado.');
      return;
    }

    final now = DateTime.now();
    final MedicationModel? originalMedication =
        widget.medication;

    final medication = MedicationModel(
      id: originalMedication?.id ??
          now.microsecondsSinceEpoch.toString(),

      patientUid: originalMedication?.patientUid ??
          firebaseUser.uid,

      name: nameController.text.trim(),
      category: selectedCategory!,
      medicineForm: selectedMedicineForm!,
      doseQuantity: selectedDoseQuantity!,
      doseUnit: selectedDoseUnit!,

      isControlled: isControlled,
      requiresPrescription: requiresPrescription,
      requiresCaregiverSupervision:
      requiresCaregiverSupervision,

      priority: selectedPriority!,
      treatmentReason:
      treatmentReasonController.text.trim(),
      doctorName: doctorNameController.text.trim(),

      frequency: selectedFrequency!,
      instructions: selectedInstruction!,
      times: List<String>.from(selectedTimes),

      startDate: startDate!,
      endDate: endDate,

      observations:
      observationsController.text.trim(),

      active: originalMedication?.active ?? true,

      createdAt: originalMedication?.createdAt ?? now,
      updatedAt: now,
      firstDoseTaken: firstDoseTakenNow,
      scheduleAnchorTime: scheduleAnchorTime,
    );

    try {
      setState(() {
        isLoading = true;
      });

      if (widget.isEditing) {
        await medicationService.updateMedication(
          medication,
        );
      } else {
        await MedicationRegistrationService()
            .registerMedication(
          medication: medication,
        );
      }
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEditing
                ? 'Medicamento actualizado correctamente.'
                : 'Medicamento guardado correctamente.',
          ),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      showMessage('No se pudo guardar el medicamento: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Widget sectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE1EAE5)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF285F50).withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
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
                    color: Colors.teal,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget yesNoSelector({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: Text(value ? 'Sí' : 'No'),
      value: value,
      activeColor: Colors.teal,
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    final doseQuantities = getDoseQuantitiesByForm(selectedMedicineForm);

    final doseUnits = getDoseUnitsByForm(selectedMedicineForm);

    if (isLoadingUser) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF285F50),
        surfaceTintColor: Colors.white,
        title: Text(
          widget.isEditing
              ? 'Editar medicamento'
              : 'Nuevo medicamento',
          style: const TextStyle(
            color: Color(0xFF24463E),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Form(
        key: formKey,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 18),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF3E806B), Color(0xFF285F50)],
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.16),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(
                          Icons.medication_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.isEditing
                                  ? 'Actualiza el tratamiento'
                                  : 'Registra tu tratamiento',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 19,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 5),
                            const Text(
                              'Completa los datos y define desde cuándo deben comenzar los recordatorios.',
                              style: TextStyle(
                                color: Color(0xFFE4F1EA),
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                sectionCard(
                  title: 'Información general',
                  icon: Icons.medication,
                  children: [
                    TextFormField(
                      controller: nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del medicamento',
                        hintText: 'Ejemplo: Paracetamol',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.medication_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Escribe el nombre del medicamento';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Categoría',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      items: categories.map((item) {
                        return DropdownMenuItem<String>(
                          value: item,
                          child: Text(item),
                        );
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
                      validator: (value) {
                        if (value == null) {
                          return 'Selecciona una categoría';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: selectedMedicineForm,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Presentación',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.inventory_2_outlined),
                      ),
                      items: medicineForms.map((item) {
                        return DropdownMenuItem<String>(
                          value: item,
                          child: Text(item),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedMedicineForm = value;
                          selectedDoseQuantity = null;
                          selectedDoseUnit = null;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Selecciona una presentación';
                        }

                        return null;
                      },
                    ),
                  ],
                ),

                sectionCard(
                  title: 'Dosis',
                  icon: Icons.straighten,
                  children: [
                    DropdownButtonFormField<int>(
                      value: selectedDoseQuantity,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: selectedMedicineForm == null
                            ? 'Selecciona primero la presentación'
                            : 'Cantidad',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.numbers),
                      ),
                      items: doseQuantities.map((item) {
                        return DropdownMenuItem<int>(
                          value: item,
                          child: Text('$item'),
                        );
                      }).toList(),
                      onChanged: selectedMedicineForm == null
                          ? null
                          : (value) {
                        setState(() {
                          selectedDoseQuantity = value;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Selecciona la cantidad';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: selectedDoseUnit,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: selectedMedicineForm == null
                            ? 'Selecciona primero la presentación'
                            : 'Unidad',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.scale_outlined),
                      ),
                      items: doseUnits.map((item) {
                        return DropdownMenuItem<String>(
                          value: item,
                          child: Text(item),
                        );
                      }).toList(),
                      onChanged: selectedMedicineForm == null
                          ? null
                          : (value) {
                        setState(() {
                          selectedDoseUnit = value;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Selecciona la unidad';
                        }

                        return null;
                      },
                    ),
                  ],
                ),

                sectionCard(
                  title: 'Control médico',
                  icon: Icons.health_and_safety_outlined,
                  children: [
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
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.red,
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Este medicamento requiere supervisión médica y debe utilizarse únicamente bajo indicación profesional.',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
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
                  ],
                ),

                sectionCard(
                  title: 'Tratamiento',
                  icon: Icons.assignment_outlined,
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedPriority,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Prioridad',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.flag_outlined),
                      ),
                      items: priorities.map((item) {
                        return DropdownMenuItem<String>(
                          value: item,
                          child: Text(item),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedPriority = value;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Selecciona la prioridad';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: treatmentReasonController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Motivo del tratamiento',
                        hintText: 'Ejemplo: hipertensión, diabetes o dolor',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: doctorNameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Médico tratante',
                        hintText: 'Opcional',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                  ],
                ),
                sectionCard(
                  title: 'Frecuencia e instrucciones',
                  icon: Icons.schedule_outlined,
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedFrequency,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Frecuencia',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.repeat_outlined),
                      ),
                      items: frequencies.map((item) {
                        return DropdownMenuItem<String>(
                          value: item,
                          child: Text(item),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedFrequency = value;
                        });

                        if (useRegistrationTime) {
                          generateTimesFromRegistration();
                        } else {
                          generateSmartTimes(value);
                        }
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Selecciona la frecuencia';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: selectedInstruction,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Instrucciones',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.info_outline),
                      ),
                      items: instructionsOptions.map((item) {
                        return DropdownMenuItem<String>(
                          value: item,
                          child: Text(item),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedInstruction = value;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Selecciona una instrucción';
                        }

                        return null;
                      },
                    ),
                  ],
                ),

                sectionCard(
                  title: 'Inicio y horarios',
                  icon: Icons.access_time_rounded,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F8F4),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFD5E8DC),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '¿Ya tomaste la primera dosis?',
                            style: TextStyle(
                              color: Color(0xFF24463E),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 7),
                          const Text(
                            'Esto permite calcular el siguiente horario a partir del momento del registro.',
                            style: TextStyle(
                              color: Color(0xFF64756E),
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ChoiceChip(
                                  label: const Text('Sí, ya la tomé'),
                                  selected: firstDoseTakenNow,
                                  onSelected: (_) {
                                    setState(() {
                                      firstDoseTakenNow = true;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ChoiceChip(
                                  label: const Text('No, será ahora'),
                                  selected: !firstDoseTakenNow,
                                  onSelected: (_) {
                                    setState(() {
                                      firstDoseTakenNow = false;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: selectedFrequency == null
                                  ? null
                                  : generateTimesFromRegistration,
                              icon: const Icon(Icons.schedule_send_rounded),
                              label: const Text(
                                'Calcular desde este momento',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF285F50),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                            ),
                          ),
                          if (scheduleAnchorTime != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Text(
                                'Horario calculado desde ${_formatTime(scheduleAnchorTime!)}.',
                                style: const TextStyle(
                                  color: Color(0xFF285F50),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (schedulesGeneratedAutomatically)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.teal.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.teal.shade200),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.auto_awesome, color: Colors.teal),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Se generaron automáticamente '
                                    '${selectedTimes.length} horario(s) '
                                    'según tu rutina diaria. Puedes '
                                    'modificarlos si es necesario.',
                              ),
                            ),
                          ],
                        ),
                      ),

                    if (selectedTimes.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: Text(
                          'No hay horarios agregados.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: selectedTimes.map((time) {
                        return Chip(
                          avatar: const Icon(Icons.alarm, size: 18),
                          label: Text(time),
                          deleteIcon: const Icon(Icons.close),
                          onDeleted: () {
                            removeTime(time);
                          },
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 14),

                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: addTime,
                        icon: const Icon(Icons.add_alarm_outlined),
                        label: const Text('Agregar horario manualmente'),
                      ),
                    ),

                    if (selectedFrequency != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: SizedBox(
                          width: double.infinity,
                          child: TextButton.icon(
                            onPressed: () {
                              generateSmartTimes(selectedFrequency);
                            },
                            icon: const Icon(Icons.auto_fix_high),
                            label: const Text('Volver a generar horarios'),
                          ),
                        ),
                      ),
                  ],
                ),

                sectionCard(
                  title: 'Vigencia',
                  icon: Icons.calendar_month_outlined,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: pickStartDate,
                        icon: const Icon(Icons.calendar_today),
                        label: Text(
                          startDate == null
                              ? 'Seleccionar fecha de inicio'
                              : 'Inicio: ${formatDate(startDate)}',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: pickEndDate,
                        icon: const Icon(Icons.event_outlined),
                        label: Text(
                          endDate == null
                              ? 'Sin fecha de finalización'
                              : 'Fin: ${formatDate(endDate)}',
                        ),
                      ),
                    ),
                    if (endDate != null)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () {
                            setState(() {
                              endDate = null;
                            });
                          },
                          icon: const Icon(Icons.close),
                          label: const Text('Quitar fecha final'),
                        ),
                      ),
                  ],
                ),

                sectionCard(
                  title: 'Observaciones',
                  icon: Icons.notes_outlined,
                  children: [
                    TextFormField(
                      controller: observationsController,
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Observaciones',
                        hintText:
                        'Ejemplo: conservar en refrigeración o tomar con abundante agua',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                SizedBox(
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: isLoading ? null : saveMedication,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF285F50),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(17),
                      ),
                    ),
                    icon: isLoading
                        ? const SizedBox(
                      width: 21,
                      height: 21,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : Icon(
                      widget.isEditing
                          ? Icons.save_as_outlined
                          : Icons.save_outlined,
                    ),
                    label: Text(
                      isLoading
                          ? widget.isEditing
                          ? 'Guardando cambios...'
                          : 'Guardando...'
                          : widget.isEditing
                          ? 'Guardar cambios'
                          : 'Guardar medicamento',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}