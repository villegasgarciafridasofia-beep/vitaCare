import 'package:flutter/material.dart';
import '../linking/scan_qr_view.dart';
import 'my_patients_view.dart';
class CaregiverDashboardView extends StatelessWidget {
  const CaregiverDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FB),
      appBar: AppBar(
        title: const Text('Panel Familiar'),
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
                    'Hola, cuidador',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Pacientes vinculados: 0',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            CaregiverCard(
              icon: Icons.qr_code_scanner,
              title: 'Vincular paciente',
              subtitle: 'Escanear QR o ingresar código',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ScanQrView(),
                  ),
                );
              },
            ),
            CaregiverCard(
              icon: Icons.people,
              title: 'Mis pacientes',
              subtitle: 'Ver usuarios bajo mi cuidado',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MyPatientsView(),
                  ),
                );
              },
            ),
            CaregiverCard(
              icon: Icons.location_on,
              title: 'Ubicación',
              subtitle: 'Consultar ubicación del paciente',
              onTap: () {},
            ),
            CaregiverCard(
              icon: Icons.medication,
              title: 'Medicamentos',
              subtitle: 'Revisar tomas y recordatorios',
              onTap: () {},
            ),
            CaregiverCard(
              icon: Icons.warning,
              title: 'Alertas',
              subtitle: 'Emergencias y riesgos detectados',
              onTap: () {},
            ),
            CaregiverCard(
              icon: Icons.history,
              title: 'Historial',
              subtitle: 'Consultar eventos recientes',
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}

class CaregiverCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const CaregiverCard({
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
          child: Icon(icon, color: Colors.teal),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}