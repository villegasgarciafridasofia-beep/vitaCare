import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/user_model.dart';
import '../../routes/app_routes.dart';
import '../../services/firestore_service.dart';
import '../../utils/user_utils.dart';

class CompleteProfileView extends StatefulWidget {
  const CompleteProfileView({super.key});

  @override
  State<CompleteProfileView> createState() => _CompleteProfileViewState();
}

class _CompleteProfileViewState extends State<CompleteProfileView> {
  final FirestoreService _firestoreService = FirestoreService();

  final nameController = TextEditingController();
  final paternalLastNameController = TextEditingController();
  final maternalLastNameController = TextEditingController();
  final phoneController = TextEditingController();
  final emergencyContactController = TextEditingController();
  final diseaseNameController = TextEditingController();

  DateTime? selectedBirthDate;

  bool hasDisease = false;
  bool isLoading = false;
  String selectedRole = "patient";

  @override
  void dispose() {
    nameController.dispose();
    paternalLastNameController.dispose();
    maternalLastNameController.dispose();
    phoneController.dispose();
    emergencyContactController.dispose();
    diseaseNameController.dispose();
    super.dispose();
  }

  Future<void> saveProfile() async {
    if (nameController.text.trim().isEmpty ||
        paternalLastNameController.text.trim().isEmpty ||
        maternalLastNameController.text.trim().isEmpty ||
        phoneController.text.trim().isEmpty ||
        emergencyContactController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Completa todos los campos obligatorios"),
        ),
      );
      return;
    }

    if (selectedBirthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Selecciona tu fecha de nacimiento"),
        ),
      );
      return;
    }

    if (hasDisease && diseaseNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Escribe el nombre de la enfermedad"),
        ),
      );
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No hay usuario autenticado"),
        ),
      );
      return;
    }

    final isOlderAdult = UserUtils.isOlderAdult(selectedBirthDate!);

    final user = UserModel(
      uid: currentUser.uid,
      email: currentUser.email ?? "",
      name: nameController.text.trim(),
      paternalLastName: paternalLastNameController.text.trim(),
      maternalLastName: maternalLastNameController.text.trim(),
      birthDate: selectedBirthDate!,
      phoneNumber: phoneController.text.trim(),
      emergencyContact: emergencyContactController.text.trim(),
      hasDisease: hasDisease,
      diseases:
      hasDisease ? [diseaseNameController.text.trim()] : <String>[],
      role: selectedRole,
      isProfileComplete: true,
      isOlderAdult: isOlderAdult,
      authProvider: "email",
      profileImage: currentUser.photoURL ?? "",
      isActive: true,
      linkCode: isOlderAdult ? UserUtils.generateLinkCode() : null,
      caregivers: [],
      patients: [],
      createdAt: DateTime.now(),
    );

    try {
      setState(() => isLoading = true);

      await _firestoreService.saveUser(user);
      await _firestoreService.markProfileAsComplete(currentUser.uid);

      if (!mounted) return;

      switch (selectedRole) {
        case "caregiver":
          Navigator.pushReplacementNamed(
              context, AppRoutes.caregiverDashboard);
          break;

        case "both":
        case "patient":
        default:
          Navigator.pushReplacementNamed(
              context, AppRoutes.patientDashboard);
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> selectBirthDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      initialDate: DateTime(2000),
    );

    if (pickedDate != null) {
      setState(() {
        selectedBirthDate = pickedDate;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FB),
      appBar: AppBar(
        title: const Text("Completar perfil"),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: "Nombre",
              ),
            ),
            TextField(
              controller: paternalLastNameController,
              decoration: const InputDecoration(
                labelText: "Apellido paterno",
              ),
            ),
            TextField(
              controller: maternalLastNameController,
              decoration: const InputDecoration(
                labelText: "Apellido materno",
              ),
            ),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: "Teléfono",
              ),
            ),
            TextField(
              controller: emergencyContactController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: "Contacto de emergencia",
              ),
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: selectBirthDate,
              child: Text(
                selectedBirthDate == null
                    ? "Seleccionar fecha de nacimiento"
                    : "${selectedBirthDate!.day}/${selectedBirthDate!.month}/${selectedBirthDate!.year}",
              ),
            ),

            const SizedBox(height: 20),

            SwitchListTile(
              title: const Text("¿Padece alguna enfermedad?"),
              value: hasDisease,
              onChanged: (value) {
                setState(() {
                  hasDisease = value;
                });
              },
            ),

            if (hasDisease)
              TextField(
                controller: diseaseNameController,
                decoration: const InputDecoration(
                  labelText: "Nombre de la enfermedad",
                ),
              ),

            const SizedBox(height: 20),

            DropdownButtonFormField<String>(
              value: selectedRole,
              decoration: const InputDecoration(
                labelText: "Rol",
              ),
              items: const [
                DropdownMenuItem(
                  value: "patient",
                  child: Text("Paciente"),
                ),
                DropdownMenuItem(
                  value: "caregiver",
                  child: Text("Cuidador"),
                ),
                DropdownMenuItem(
                  value: "both",
                  child: Text("Ambos"),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => selectedRole = value);
                }
              },
            ),

            const SizedBox(height: 30),

            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: isLoading ? null : saveProfile,
                child: isLoading
                    ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Text("Guardar perfil"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}