import 'package:flutter/material.dart';

import '../../models/location_model.dart';
import '../../models/user_model.dart';
import '../../services/location_service.dart';

class PatientLocationView extends StatelessWidget {
  const PatientLocationView({
    super.key,
    required this.patient,
  });

  final UserModel patient;

  static const Color primaryDark = Color(0xFF285F50);
  static const Color primaryLight = Color(0xFFE4F1EA);
  static const Color background = Color(0xFFF4F8F5);
  static const Color textDark = Color(0xFF24463E);
  static const Color textSoft = Color(0xFF64756E);

  @override
  Widget build(BuildContext context) {
    final LocationService locationService = LocationService();

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text(
          'Ubicación del paciente',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: Colors.white,
        foregroundColor: primaryDark,
        surfaceTintColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<LocationModel?>(
        stream: locationService.watchPatientLocation(patient.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(
                color: primaryDark,
              ),
            );
          }

          final LocationModel? location = snapshot.data;

          if (location == null) {
            return const _NoLocationState(
              message:
                  'Este paciente todavía no ha compartido una ubicación.',
            );
          }

          if (!location.isSharing) {
            return const _NoLocationState(
              message:
                  'El paciente desactivó temporalmente el uso compartido de su ubicación.',
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF4B927B),
                      Color(0xFF285F50),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white24,
                      child: Text(
                        patient.name.trim().isEmpty
                            ? '?'
                            : patient.name[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 23,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${patient.name} ${patient.paternalLastName}'
                                .trim(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 21,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            'Ubicación compartida',
                            style: TextStyle(
                              color: Color(0xFFE6F3ED),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.verified_user_rounded,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Container(
                height: 250,
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F1EC),
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(
                    color: const Color(0xFFD2E2DB),
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Positioned.fill(
                      child: CustomPaint(
                        painter: _CaregiverMapPainter(),
                      ),
                    ),
                    const Icon(
                      Icons.person_pin_circle_rounded,
                      color: primaryDark,
                      size: 68,
                    ),
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 14,
                      child: Container(
                        padding: const EdgeInsets.all(11),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Text(
                          '${location.latitude.toStringAsFixed(6)}, '
                          '${location.longitude.toStringAsFixed(6)}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: textDark,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(0xFFE1EAE5),
                  ),
                ),
                child: Column(
                  children: [
                    _DetailRow(
                      icon: Icons.schedule_rounded,
                      title: 'Última actualización',
                      value: _formatDate(location.updatedAt),
                    ),
                    const Divider(height: 24),
                    _DetailRow(
                      icon: Icons.gps_fixed_rounded,
                      title: 'Precisión',
                      value:
                          '${location.accuracy.toStringAsFixed(1)} metros',
                    ),
                    const Divider(height: 24),
                    _DetailRow(
                      icon: Icons.alt_route_rounded,
                      title: 'Coordenadas',
                      value:
                          '${location.latitude.toStringAsFixed(5)}, '
                          '${location.longitude.toStringAsFixed(5)}',
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static String _formatDate(DateTime value) {
    final String day = value.day.toString().padLeft(2, '0');
    final String month = value.month.toString().padLeft(2, '0');
    final String hour = value.hour.toString().padLeft(2, '0');
    final String minute = value.minute.toString().padLeft(2, '0');

    return '$day/$month/${value.year} • $hour:$minute';
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: PatientLocationView.primaryLight,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            icon,
            color: PatientLocationView.primaryDark,
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: PatientLocationView.textSoft,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  color: PatientLocationView.textDark,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NoLocationState extends StatelessWidget {
  const _NoLocationState({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleAvatar(
              radius: 44,
              backgroundColor: PatientLocationView.primaryLight,
              child: Icon(
                Icons.location_off_outlined,
                color: PatientLocationView.primaryDark,
                size: 43,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Ubicación no disponible',
              style: TextStyle(
                color: PatientLocationView.textDark,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: PatientLocationView.textSoft,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CaregiverMapPainter extends CustomPainter {
  const _CaregiverMapPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = const Color(0xFFC9DDD4)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(0, size.height * 0.25),
      Offset(size.width, size.height * 0.65),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.20, 0),
      Offset(size.width * 0.55, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.80, 0),
      Offset(size.width * 0.35, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
