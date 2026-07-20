import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/firestore_service.dart';
import '../../routes/app_routes.dart';

class RoutineSetupView extends StatefulWidget {
  const RoutineSetupView({super.key});

  @override
  State<RoutineSetupView> createState() => _RoutineSetupViewState();
}

class _RoutineSetupViewState extends State<RoutineSetupView> {
  final FirestoreService firestoreService = FirestoreService();

  TimeOfDay? wakeUpTime;
  TimeOfDay? breakfastTime;
  TimeOfDay? lunchTime;
  TimeOfDay? dinnerTime;
  TimeOfDay? sleepTime;

  bool allowNightReminders = false;
  int reminderMinutesBefore = 10;
  bool isLoading = false;

  String formatTime(TimeOfDay? time) {
    if (time == null) return 'Seleccionar hora';

    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  Future<void> pickTime({
    required Function(TimeOfDay) onSelected,
  }) async {
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (selected != null) {
      onSelected(selected);
    }
  }

  Future<void> saveRoutine() async {
    if (wakeUpTime == null ||
        breakfastTime == null ||
        lunchTime == null ||
        dinnerTime == null ||
        sleepTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Completa todos los horarios de rutina'),
        ),
      );
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay un usuario autenticado'),
        ),
      );
      return;
    }

    try {
      setState(() {
        isLoading = true;
      });

      await firestoreService.updateUserRoutine(
        uid: currentUser.uid,
        wakeUpTime: formatTime(wakeUpTime),
        breakfastTime: formatTime(breakfastTime),
        lunchTime: formatTime(lunchTime),
        dinnerTime: formatTime(dinnerTime),
        sleepTime: formatTime(sleepTime),
        allowNightReminders: allowNightReminders,
        reminderMinutesBefore: reminderMinutesBefore,
      );

      final user = await firestoreService.getUser(currentUser.uid);

      if (!mounted) return;

      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se encontró el perfil del usuario'),
          ),
        );
        return;
      }

      if (user.role == 'caregiver') {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.caregiverDashboard,
              (route) => false,
        );
      } else {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.patientDashboard,
              (route) => false,
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar la rutina: $e'),
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

  Widget timeButton({
    required String title,
    required TimeOfDay? time,
    required Function(TimeOfDay) onSelected,
  }) {
    return Card(
      child: ListTile(
        title: Text(title),
        subtitle: Text(formatTime(time)),
        trailing: const Icon(Icons.access_time),
        onTap: () {
          pickTime(onSelected: onSelected);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rutina diaria'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            const Text(
              'Configura tu rutina una sola vez',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'VitaCare AI usará estos horarios para calcular recordatorios inteligentes.',
            ),
            const SizedBox(height: 20),

            timeButton(
              title: 'Hora de despertar',
              time: wakeUpTime,
              onSelected: (value) {
                setState(() {
                  wakeUpTime = value;
                });
              },
            ),

            timeButton(
              title: 'Hora de desayuno',
              time: breakfastTime,
              onSelected: (value) {
                setState(() {
                  breakfastTime = value;
                });
              },
            ),

            timeButton(
              title: 'Hora de comida',
              time: lunchTime,
              onSelected: (value) {
                setState(() {
                  lunchTime = value;
                });
              },
            ),

            timeButton(
              title: 'Hora de cena',
              time: dinnerTime,
              onSelected: (value) {
                setState(() {
                  dinnerTime = value;
                });
              },
            ),

            timeButton(
              title: 'Hora de dormir',
              time: sleepTime,
              onSelected: (value) {
                setState(() {
                  sleepTime = value;
                });
              },
            ),

            const SizedBox(height: 12),

            SwitchListTile(
              title: const Text('Permitir recordatorios nocturnos'),
              subtitle: const Text(
                'Solo para medicamentos que deban tomarse durante la noche.',
              ),
              value: allowNightReminders,
              onChanged: (value) {
                setState(() {
                  allowNightReminders = value;
                });
              },
            ),

            const SizedBox(height: 12),

            DropdownButtonFormField<int>(
              value: reminderMinutesBefore,
              decoration: const InputDecoration(
                labelText: 'Avisar antes de la toma',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 5,
                  child: Text('5 minutos antes'),
                ),
                DropdownMenuItem(
                  value: 10,
                  child: Text('10 minutos antes'),
                ),
                DropdownMenuItem(
                  value: 15,
                  child: Text('15 minutos antes'),
                ),
                DropdownMenuItem(
                  value: 30,
                  child: Text('30 minutos antes'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    reminderMinutesBefore = value;
                  });
                }
              },
            ),

            const SizedBox(height: 30),

            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: isLoading ? null : saveRoutine,
                child: isLoading
                    ? const CircularProgressIndicator(
                  color: Colors.white,
                )
                    : const Text('Guardar rutina'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}