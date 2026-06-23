import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/medication_model.dart';
import '../../services/medication_service.dart';
import 'add_medication_view.dart';

class MedicationsView extends StatefulWidget {
  const MedicationsView({super.key});

  @override
  State<MedicationsView> createState() =>
      _MedicationsViewState();
}

class _MedicationsViewState
    extends State<MedicationsView> {

  final MedicationService medicationService =
  MedicationService();

  Future<List<MedicationModel>>
  loadMedications() async {

    final uid =
        FirebaseAuth.instance.currentUser!.uid;

    return medicationService
        .getPatientMedications(uid);
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medicamentos'),
        backgroundColor: Colors.teal,
      ),

      floatingActionButton:
      FloatingActionButton(
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add),
        onPressed: () async {

          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
              const AddMedicationView(),
            ),
          );

          setState(() {});
        },
      ),

      body: FutureBuilder<
          List<MedicationModel>>(
        future: loadMedications(),

        builder: (context, snapshot) {

          if (snapshot.connectionState ==
              ConnectionState.waiting) {

            return const Center(
              child:
              CircularProgressIndicator(),
            );
          }

          final medications =
              snapshot.data ?? [];

          if (medications.isEmpty) {

            return const Center(
              child: Text(
                'No hay medicamentos',
              ),
            );
          }

          return ListView.builder(
            itemCount:
            medications.length,

            itemBuilder:
                (context, index) {

              final med =
              medications[index];

              return Card(
                margin:
                const EdgeInsets.all(
                    10),

                child: ListTile(
                  leading: const Icon(
                    Icons.medication,
                    color: Colors.teal,
                  ),

                  title:
                  Text(med.name),

                  subtitle: Text(
                    '${med.dose}\n${med.frequency}\n${med.times.join(", ")}',
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}