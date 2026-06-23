import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/medication_model.dart';
import '../../services/medication_service.dart';

class AddMedicationView extends StatefulWidget {
  const AddMedicationView({super.key});

  @override
  State<AddMedicationView> createState() =>
      _AddMedicationViewState();
}

class _AddMedicationViewState
    extends State<AddMedicationView> {

  final MedicationService medicationService =
  MedicationService();

  final nameController = TextEditingController();
  final doseController = TextEditingController();
  final frequencyController = TextEditingController();
  final timeController = TextEditingController();

  bool isLoading = false;

  Future<void> saveMedication() async {

    final uid =
        FirebaseAuth.instance.currentUser!.uid;

    final medication = MedicationModel(
      id: DateTime.now()
          .millisecondsSinceEpoch
          .toString(),

      patientUid: uid,

      name: nameController.text.trim(),

      dose: doseController.text.trim(),

      frequency:
      frequencyController.text.trim(),

      times: [
        timeController.text.trim(),
      ],

      active: true,

      createdAt: DateTime.now(),
    );

    try {

      setState(() {
        isLoading = true;
      });

      await medicationService.addMedication(
        medication,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content:
          Text('Medicamento guardado'),
        ),
      );

      Navigator.pop(context);

    } catch (e) {

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(e.toString()),
        ),
      );

    } finally {

      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title:
        const Text('Agregar medicamento'),
        backgroundColor: Colors.teal,
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: ListView(
          children: [

            TextField(
              controller: nameController,
              decoration:
              const InputDecoration(
                labelText:
                'Nombre medicamento',
              ),
            ),

            TextField(
              controller: doseController,
              decoration:
              const InputDecoration(
                labelText: 'Dosis',
              ),
            ),

            TextField(
              controller:
              frequencyController,
              decoration:
              const InputDecoration(
                labelText:
                'Frecuencia',
              ),
            ),

            TextField(
              controller: timeController,
              decoration:
              const InputDecoration(
                labelText:
                'Hora (08:00)',
              ),
            ),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed:
              isLoading ? null : saveMedication,

              child: isLoading
                  ? const CircularProgressIndicator()
                  : const Text(
                'Guardar medicamento',
              ),
            ),
          ],
        ),
      ),
    );
  }
}