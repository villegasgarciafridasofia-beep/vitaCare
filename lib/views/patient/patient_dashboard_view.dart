import 'package:flutter/material.dart';
import '../medications/add_medication_view.dart';
import 'my_caregivers_view.dart';

class PatientDashboardView extends StatelessWidget {
  const PatientDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FB),
      appBar: AppBar(
        title: const Text('VitaCare AI'),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.teal,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hola, paciente',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Estado actual: Verde 🟢',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            DashboardCard(
              icon: Icons.medication,
              title: 'Medicamentos',
              subtitle: 'Gestiona tratamientos y recordatorios',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                    const AddMedicationView(),
                  ),
                );
              },
            ),

            DashboardCard(
              icon: Icons.calendar_month,
              title: 'Citas médicas',
              subtitle: 'Consulta próximas citas',
              onTap: () {},
            ),

            DashboardCard(
              icon: Icons.location_on,
              title: 'Ubicación',
              subtitle: 'Monitoreo y zonas seguras',
              onTap: () {},
            ),

            DashboardCard(
              icon: Icons.family_restroom,
              title: 'Familiares',
              subtitle: 'Ver cuidadores vinculados',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MyCaregiversView(),
                  ),
                );
              },
            ),

            DashboardCard(
              icon: Icons.sos,
              title: 'SOS',
              subtitle: 'Enviar alerta de emergencia',
              onTap: () {},
            ),

            DashboardCard(
              icon: Icons.smart_toy,
              title: 'VitaCare AI',
              subtitle: 'Asistente virtual de salud',
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const DashboardCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 3,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.teal.shade100,
          child: Icon(
            icon,
            color: Colors.teal,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
        ),
        onTap: onTap,
      ),
    );
  }
}