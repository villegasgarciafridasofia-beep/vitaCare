import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/location_model.dart';
import '../../services/location_service.dart';

class LocationView extends StatefulWidget {
  const LocationView({super.key});

  @override
  State<LocationView> createState() => _LocationViewState();
}

class _LocationViewState extends State<LocationView> {
  static const Color primaryDark = Color(0xFF285F50);
  static const Color primary = Color(0xFF3E806B);
  static const Color primaryLight = Color(0xFFE4F1EA);
  static const Color background = Color(0xFFF4F8F5);
  static const Color textDark = Color(0xFF24463E);
  static const Color textSoft = Color(0xFF64756E);

  final LocationService _locationService = LocationService();

  bool _isBusy = false;
  String? _errorMessage;

  String get _uid =>
      FirebaseAuth.instance.currentUser?.uid ?? '';

  Future<void> _setSharing(bool value) async {
    if (_isBusy || _uid.isEmpty) return;

    setState(() {
      _isBusy = true;
      _errorMessage = null;
    });

    try {
      await _locationService.setSharing(
        patientUid: _uid,
        isSharing: value,
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage =
            error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  Future<void> _refreshLocation() async {
    if (_isBusy || _uid.isEmpty) return;

    setState(() {
      _isBusy = true;
      _errorMessage = null;
    });

    try {
      final LocationModel? current =
          await _locationService.getPatientLocation(_uid);

      await _locationService.updateCurrentLocation(
        patientUid: _uid,
        isSharing: current?.isSharing ?? true,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: primaryDark,
          content: Text(
            'Ubicación actualizada correctamente.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage =
            error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_uid.isEmpty) {
      return const Scaffold(
        body: Center(
          child: Text('No existe una sesión activa.'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text(
          'Mi ubicación',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: Colors.white,
        foregroundColor: primaryDark,
        surfaceTintColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<LocationModel?>(
        stream: _locationService.watchPatientLocation(_uid),
        builder: (context, snapshot) {
          final LocationModel? location = snapshot.data;
          final bool sharing = location?.isSharing ?? false;

          return RefreshIndicator(
            onRefresh: _refreshLocation,
            color: primaryDark,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
              children: [
                _buildHero(sharing),
                const SizedBox(height: 18),
                if (_errorMessage != null) ...[
                  _buildError(),
                  const SizedBox(height: 18),
                ],
                _buildMapPlaceholder(location),
                const SizedBox(height: 18),
                _buildInformation(location),
                const SizedBox(height: 20),
                SizedBox(
                  height: 54,
                  child: FilledButton.icon(
                    onPressed: _isBusy
                        ? null
                        : _refreshLocation,
                    icon: _isBusy
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.3,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.my_location_rounded),
                    label: const Text(
                      'Actualizar ubicación',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: primaryDark,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(17),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHero(bool sharing) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF4B927B),
            Color(0xFF285F50),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: primaryDark.withValues(alpha: 0.20),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  color: Colors.white,
                  size: 31,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sharing
                          ? 'Ubicación compartida'
                          : 'Ubicación privada',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      sharing
                          ? 'Tus familiares autorizados pueden consultar tu última ubicación.'
                          : 'Activa esta opción para compartir tu ubicación con tus familiares.',
                      style: const TextStyle(
                        color: Color(0xFFE6F3ED),
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(18),
            ),
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Compartir con familiares',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              subtitle: Text(
                sharing ? 'Activo' : 'Inactivo',
                style: const TextStyle(
                  color: Color(0xFFE6F3ED),
                ),
              ),
              value: sharing,
              activeThumbColor: Colors.white,
              activeTrackColor:
                  Colors.white.withValues(alpha: 0.42),
              onChanged: _isBusy ? null : _setSharing,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapPlaceholder(LocationModel? location) {
    return Container(
      height: 230,
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
            child: _MapPattern(),
          ),
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: primaryDark.withValues(alpha: 0.18),
                  blurRadius: 18,
                ),
              ],
            ),
            child: const Icon(
              Icons.person_pin_circle_rounded,
              color: primaryDark,
              size: 44,
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 13,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                location == null
                    ? 'Aún no hay una ubicación registrada'
                    : '${location.latitude.toStringAsFixed(6)}, '
                        '${location.longitude.toStringAsFixed(6)}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: textDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInformation(LocationModel? location) {
    return Container(
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
          _InfoRow(
            icon: Icons.schedule_rounded,
            title: 'Última actualización',
            value: location == null
                ? 'Sin información'
                : _formatDate(location.updatedAt),
          ),
          const Divider(height: 24),
          _InfoRow(
            icon: Icons.gps_fixed_rounded,
            title: 'Precisión aproximada',
            value: location == null
                ? 'Sin información'
                : '${location.accuracy.toStringAsFixed(1)} metros',
          ),
          const Divider(height: 24),
          _InfoRow(
            icon: Icons.speed_rounded,
            title: 'Velocidad',
            value: location == null
                ? 'Sin información'
                : '${location.speed.toStringAsFixed(1)} m/s',
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEEEE),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFF0CACA),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFB94747),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(
                color: Color(0xFF7A3F3F),
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime value) {
    final String day = value.day.toString().padLeft(2, '0');
    final String month = value.month.toString().padLeft(2, '0');
    final String hour = value.hour.toString().padLeft(2, '0');
    final String minute = value.minute.toString().padLeft(2, '0');

    return '$day/$month/${value.year} • $hour:$minute';
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
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
            color: _LocationViewState.primaryLight,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            icon,
            color: _LocationViewState.primaryDark,
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
                  color: _LocationViewState.textSoft,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  color: _LocationViewState.textDark,
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

class _MapPattern extends StatelessWidget {
  const _MapPattern();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _MapPatternPainter(),
    );
  }
}

class _MapPatternPainter extends CustomPainter {
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
    canvas.drawCircle(
      Offset(size.width * 0.18, size.height * 0.72),
      32,
      paint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.84, size.height * 0.30),
      24,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
