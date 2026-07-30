import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../routes/app_routes.dart';
import '../../services/notification_service.dart';
import '../medications/medications_view.dart';
import 'my_caregivers_view.dart';

class PatientDashboardView extends StatefulWidget {
  const PatientDashboardView({super.key});

  @override
  State<PatientDashboardView> createState() =>
      _PatientDashboardViewState();
}

class _PatientDashboardViewState extends State<PatientDashboardView> {
  int _selectedIndex = 0;
  bool _isLoggingOut = false;

  static const Color primaryDark = Color(0xFF285F50);
  static const Color primary = Color(0xFF3E806B);
  static const Color primaryLight = Color(0xFFE4F1EA);
  static const Color background = Color(0xFFF4F8F5);
  static const Color textDark = Color(0xFF24463E);
  static const Color textSoft = Color(0xFF64756E);

  final List<String> _titles = const [
    'Inicio',
    'Medicamentos',
    'Notificaciones',
    'Mi perfil',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: _buildAppBar(),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildHomeView(),
          const MedicationsView(),
          _buildNotificationsView(),
          _buildProfileView(),
        ],
      ),
      bottomNavigationBar: _buildNavigationBar(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      centerTitle: false,
      backgroundColor: Colors.white,
      foregroundColor: textDark,
      surfaceTintColor: Colors.white,
      titleSpacing: 20,
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: primaryLight,
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.health_and_safety_rounded,
              color: primaryDark,
              size: 24,
            ),
          ),
          const SizedBox(width: 11),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'VitaCare AI',
                style: TextStyle(
                  color: textDark,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                _titles[_selectedIndex],
                style: const TextStyle(
                  color: textSoft,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Notificaciones',
          onPressed: () {
            setState(() {
              _selectedIndex = 2;
            });
          },
          icon: Badge(
            smallSize: 8,
            backgroundColor: const Color(0xFFE15C5C),
            child: Icon(
              _selectedIndex == 2
                  ? Icons.notifications_rounded
                  : Icons.notifications_none_rounded,
              color: primaryDark,
            ),
          ),
        ),
        const SizedBox(width: 4),
        Padding(
          padding: const EdgeInsets.only(right: 14),
          child: InkWell(
            borderRadius: BorderRadius.circular(30),
            onTap: () {
              setState(() {
                _selectedIndex = 3;
              });
            },
            child: CircleAvatar(
              radius: 19,
              backgroundColor: primaryDark,
              child: Text(
                _getUserInitial(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationBar() {
    return NavigationBar(
      selectedIndex: _selectedIndex,
      height: 72,
      backgroundColor: Colors.white,
      indicatorColor: primaryLight,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      onDestinationSelected: (int index) {
        setState(() {
          _selectedIndex = index;
        });
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(
            Icons.home_rounded,
            color: primaryDark,
          ),
          label: 'Inicio',
        ),
        NavigationDestination(
          icon: Icon(Icons.medication_outlined),
          selectedIcon: Icon(
            Icons.medication_rounded,
            color: primaryDark,
          ),
          label: 'Medicinas',
        ),
        NavigationDestination(
          icon: Icon(Icons.notifications_none_rounded),
          selectedIcon: Icon(
            Icons.notifications_rounded,
            color: primaryDark,
          ),
          label: 'Avisos',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline_rounded),
          selectedIcon: Icon(
            Icons.person_rounded,
            color: primaryDark,
          ),
          label: 'Perfil',
        ),
      ],
    );
  }

  Widget _buildHomeView() {
    return SafeArea(
      top: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        children: [
          _buildWelcomeCard(),
          const SizedBox(height: 24),
          const Text(
            'Accesos rápidos',
            style: TextStyle(
              color: textDark,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 1.02,
            children: [
              _DashboardMenuCard(
                icon: Icons.medication_rounded,
                title: 'Medicamentos',
                subtitle: 'Tratamientos y horarios',
                iconBackground: const Color(0xFFE4F1EA),
                iconColor: primaryDark,
                onTap: () {
                  setState(() {
                    _selectedIndex = 1;
                  });
                },
              ),
              _DashboardMenuCard(
                icon: Icons.calendar_month_rounded,
                title: 'Citas médicas',
                subtitle: 'Próximas consultas',
                iconBackground: const Color(0xFFE7EEFA),
                iconColor: const Color(0xFF456FA8),
                onTap: () {
                  _showComingSoon('Citas médicas');
                },
              ),
              _DashboardMenuCard(
                icon: Icons.location_on_rounded,
                title: 'Ubicación',
                subtitle: 'Zonas y monitoreo',
                iconBackground: const Color(0xFFFFEFE1),
                iconColor: const Color(0xFFB66A2D),
                onTap: () {
                  _showComingSoon('Ubicación');
                },
              ),
              _DashboardMenuCard(
                icon: Icons.family_restroom_rounded,
                title: 'Familiares',
                subtitle: 'Cuidadores vinculados',
                iconBackground: const Color(0xFFF0EAF8),
                iconColor: const Color(0xFF73539B),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MyCaregiversView(),
                    ),
                  );
                },
              ),
              _DashboardMenuCard(
                icon: Icons.sos_rounded,
                title: 'Emergencia',
                subtitle: 'Enviar alerta SOS',
                iconBackground: const Color(0xFFFFE8E8),
                iconColor: const Color(0xFFB94747),
                onTap: () {
                  _showComingSoon('Alerta de emergencia');
                },
              ),
              _DashboardMenuCard(
                icon: Icons.smart_toy_rounded,
                title: 'VitaCare AI',
                subtitle: 'Asistente de salud',
                iconBackground: const Color(0xFFE6F3F3),
                iconColor: const Color(0xFF31787A),
                onTap: () {
                  _showComingSoon('Asistente VitaCare AI');
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildTodaySummary(),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard() {
    final User? user = FirebaseAuth.instance.currentUser;
    final String name = _getDisplayName(user);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF3E806B),
            Color(0xFF285F50),
          ],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: primaryDark.withOpacity(0.22),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hola, $name',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tu bienestar es nuestra prioridad.',
                  style: TextStyle(
                    color: Color(0xFFE4F1EA),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFFBDE8C8),
                        size: 18,
                      ),
                      SizedBox(width: 7),
                      Text(
                        'Estado estable',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.13),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.favorite_rounded,
              color: Colors.white,
              size: 45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodaySummary() {
    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFE1EAE5),
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumen de hoy',
            style: TextStyle(
              color: textDark,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 16),
          _SummaryRow(
            icon: Icons.medication_rounded,
            title: 'Medicamentos',
            value: 'Revisa tus horarios',
          ),
          SizedBox(height: 12),
          _SummaryRow(
            icon: Icons.calendar_today_rounded,
            title: 'Próxima cita',
            value: 'Sin citas pendientes',
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsView() {
    return SafeArea(
      top: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: const Color(0xFFE1EAE5),
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: const BoxDecoration(
                    color: primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.notifications_active_rounded,
                    color: primaryDark,
                    size: 35,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Centro de notificaciones',
                  style: TextStyle(
                    color: textDark,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 7),
                const Text(
                  'Aquí aparecerán tus recordatorios de medicamentos, '
                      'citas y alertas importantes.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textSoft,
                    fontSize: 14,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _sendTestNotification,
                    icon: const Icon(
                      Icons.notifications_active_outlined,
                    ),
                    label: const Text(
                      'Probar notificación',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryDark,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'Recientes',
            style: TextStyle(
              color: textDark,
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          const _NotificationCard(
            icon: Icons.medication_rounded,
            title: 'Recordatorios de medicamentos',
            subtitle:
            'Tus próximos avisos aparecerán aquí cuando estén programados.',
          ),
        ],
      ),
    );
  }

  Widget _buildProfileView() {
    final User? user = FirebaseAuth.instance.currentUser;
    final String email = user?.email ?? 'Correo no disponible';
    final String name = _getDisplayName(user);

    return SafeArea(
      top: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0xFFE1EAE5),
              ),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: primaryLight,
                  backgroundImage: user?.photoURL != null
                      ? NetworkImage(user!.photoURL!)
                      : null,
                  child: user?.photoURL == null
                      ? Text(
                    _getUserInitial(),
                    style: const TextStyle(
                      color: primaryDark,
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                      : null,
                ),
                const SizedBox(height: 14),
                Text(
                  name,
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  email,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: textSoft,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _ProfileOption(
            icon: Icons.person_outline_rounded,
            title: 'Información personal',
            subtitle: 'Consulta y actualiza tus datos',
            onTap: () {
              _showComingSoon('Información personal');
            },
          ),
          _ProfileOption(
            icon: Icons.family_restroom_rounded,
            title: 'Mis cuidadores',
            subtitle: 'Gestiona tus familiares vinculados',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const MyCaregiversView(),
                ),
              );
            },
          ),
          _ProfileOption(
            icon: Icons.settings_outlined,
            title: 'Configuración',
            subtitle: 'Preferencias de la aplicación',
            onTap: () {
              _showComingSoon('Configuración');
            },
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: OutlinedButton.icon(
              onPressed: _isLoggingOut ? null : _confirmLogout,
              icon: _isLoggingOut
                  ? const SizedBox(
                width: 21,
                height: 21,
                child: CircularProgressIndicator(
                  strokeWidth: 2.3,
                ),
              )
                  : const Icon(Icons.logout_rounded),
              label: Text(
                _isLoggingOut
                    ? 'Cerrando sesión...'
                    : 'Cerrar sesión',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFB94747),
                side: const BorderSide(
                  color: Color(0xFFEABBBB),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendTestNotification() async {
    try {
      await NotificationService.instance.showTestNotification();

      if (!mounted) return;

      _showSnackBar(
        message: 'Notificación de prueba enviada.',
        icon: Icons.check_circle_outline_rounded,
        backgroundColor: const Color(0xFFEAF7EF),
        foregroundColor: primaryDark,
      );
    } catch (error, stackTrace) {
      debugPrint('Error al enviar la notificación: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      _showSnackBar(
        message: 'No fue posible enviar la notificación.',
        icon: Icons.error_outline_rounded,
        backgroundColor: const Color(0xFFFFF1F1),
        foregroundColor: const Color(0xFF9B3434),
      );
    }
  }

  Future<void> _confirmLogout() async {
    final bool? shouldLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          icon: const CircleAvatar(
            radius: 28,
            backgroundColor: Color(0xFFFFE8E8),
            child: Icon(
              Icons.logout_rounded,
              color: Color(0xFFB94747),
            ),
          ),
          title: const Text(
            '¿Cerrar sesión?',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textDark,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: const Text(
            'Tendrás que iniciar sesión nuevamente para entrar a VitaCare AI.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textSoft,
              height: 1.4,
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB94747),
                foregroundColor: Colors.white,
              ),
              child: const Text('Cerrar sesión'),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true) {
      await _logout();
    }
  }

  Future<void> _logout() async {
    try {
      setState(() {
        _isLoggingOut = true;
      });

      await FirebaseAuth.instance.signOut();

      if (!mounted) return;

      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.login,
            (Route<dynamic> route) => false,
      );
    } catch (error, stackTrace) {
      debugPrint('Error al cerrar sesión: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      _showSnackBar(
        message: 'No fue posible cerrar la sesión.',
        icon: Icons.error_outline_rounded,
        backgroundColor: const Color(0xFFFFF1F1),
        foregroundColor: const Color(0xFF9B3434),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoggingOut = false;
        });
      }
    }
  }

  String _getUserInitial() {
    final User? user = FirebaseAuth.instance.currentUser;
    final String source =
    user?.displayName?.trim().isNotEmpty == true
        ? user!.displayName!
        : user?.email ?? 'P';

    return source.trim().isEmpty
        ? 'P'
        : source.trim().substring(0, 1).toUpperCase();
  }

  String _getDisplayName(User? user) {
    final String? displayName = user?.displayName?.trim();

    if (displayName != null && displayName.isNotEmpty) {
      return displayName.split(' ').first;
    }

    final String? email = user?.email;

    if (email != null && email.contains('@')) {
      final String emailName = email.split('@').first;

      if (emailName.isNotEmpty) {
        return emailName[0].toUpperCase() + emailName.substring(1);
      }
    }

    return 'Paciente';
  }

  void _showComingSoon(String feature) {
    _showSnackBar(
      message: '$feature estará disponible próximamente.',
      icon: Icons.construction_rounded,
      backgroundColor: const Color(0xFFFFF3E8),
      foregroundColor: const Color(0xFF8A571C),
    );
  }

  void _showSnackBar({
    required String message,
    required IconData icon,
    required Color backgroundColor,
    required Color foregroundColor,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: backgroundColor,
        elevation: 6,
        margin: const EdgeInsets.all(18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: Row(
          children: [
            Icon(
              icon,
              color: foregroundColor,
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: foregroundColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardMenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconBackground;
  final Color iconColor;
  final VoidCallback onTap;

  const _DashboardMenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconBackground,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: const Color(0xFFE1EAE5),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 27,
                ),
              ),
              const Spacer(),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _PatientDashboardViewState.textDark,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _PatientDashboardViewState.textSoft,
                  fontSize: 12,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _SummaryRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFE4F1EA),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF285F50),
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: _PatientDashboardViewState.textDark,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: _PatientDashboardViewState.textSoft,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _NotificationCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: const Color(0xFFE1EAE5),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFE4F1EA),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF285F50),
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
                    color: _PatientDashboardViewState.textDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: _PatientDashboardViewState.textSoft,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ProfileOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 11),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(
          color: Color(0xFFE1EAE5),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 6,
        ),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFE4F1EA),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF285F50),
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: _PatientDashboardViewState.textDark,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            color: _PatientDashboardViewState.textSoft,
            fontSize: 12,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: Color(0xFF71817A),
        ),
        onTap: onTap,
      ),
    );
  }
}