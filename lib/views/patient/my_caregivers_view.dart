import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/user_model.dart';
import '../../services/firestore_service.dart';

class MyCaregiversView extends StatefulWidget {
  const MyCaregiversView({super.key});

  @override
  State<MyCaregiversView> createState() => _MyCaregiversViewState();
}

class _MyCaregiversViewState extends State<MyCaregiversView> {
  final FirestoreService firestoreService = FirestoreService();

  Future<List<UserModel>> loadCaregivers() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final patient = await firestoreService.getUser(uid);

    if (patient == null) {
      return [];
    }

    return firestoreService.getCaregivers(
      patient.caregivers,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Cuidadores'),
        backgroundColor: Colors.teal,
      ),
      body: FutureBuilder<List<UserModel>>(
        future: loadCaregivers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final caregivers = snapshot.data ?? [];

          if (caregivers.isEmpty) {
            return const Center(
              child: Text(
                'No tienes cuidadores vinculados',
              ),
            );
          }

          return ListView.builder(
            itemCount: caregivers.length,
            itemBuilder: (context, index) {
              final caregiver = caregivers[index];

              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(
                      caregiver.name.isNotEmpty
                          ? caregiver.name[0]
                          : '?',
                    ),
                  ),
                  title: Text(
                    '${caregiver.name} ${caregiver.paternalLastName}',
                  ),
                  subtitle: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Correo: ${caregiver.email}',
                      ),
                      Text(
                        'Teléfono: ${caregiver.phoneNumber}',
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