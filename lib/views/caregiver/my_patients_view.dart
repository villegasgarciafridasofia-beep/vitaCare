import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/user_model.dart';
import '../../services/firestore_service.dart';

class MyPatientsView extends StatefulWidget {
  const MyPatientsView({super.key});

  @override
  State<MyPatientsView> createState() => _MyPatientsViewState();
}

class _MyPatientsViewState extends State<MyPatientsView> {
  final FirestoreService firestoreService = FirestoreService();

  Future<List<UserModel>> loadPatients() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final caregiver =
    await firestoreService.getUser(uid);

    if (caregiver == null) {
      return [];
    }

    return firestoreService.getPatients(
      caregiver.patients,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Pacientes'),
        backgroundColor: Colors.teal,
      ),
      body: FutureBuilder<List<UserModel>>(
        future: loadPatients(),
        builder: (context, snapshot) {

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final patients = snapshot.data ?? [];

          if (patients.isEmpty) {
            return const Center(
              child: Text(
                'No tienes pacientes vinculados',
              ),
            );
          }

          return ListView.builder(
            itemCount: patients.length,
            itemBuilder: (context, index) {

              final patient = patients[index];

              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(
                      patient.name.isNotEmpty
                          ? patient.name[0]
                          : '?',
                    ),
                  ),

                  title: Text(
                    '${patient.name} ${patient.paternalLastName}',
                  ),

                  subtitle: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [

                      Text(
                        'Edad mayor: ${patient.isOlderAdult ? "Sí" : "No"}',
                      ),

                      Text(
                        'Enfermedades: ${patient.diseases.join(", ")}',
                      ),
                    ],
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