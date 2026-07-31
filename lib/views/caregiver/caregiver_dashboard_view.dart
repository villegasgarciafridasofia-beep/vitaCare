import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/user_model.dart';
import '../../routes/app_routes.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../linking/scan_qr_view.dart';
import 'my_patients_view.dart';

class CaregiverDashboardView extends StatefulWidget {
  const CaregiverDashboardView({super.key});

  @override
  State<CaregiverDashboardView> createState() =>
      _CaregiverDashboardViewState();
}

class _CaregiverDashboardViewState extends State<CaregiverDashboardView> {
  static const Color primaryDark = Color(0xFF285F50);
  static const Color primary = Color(0xFF3E806B);
  static const Color primaryLight = Color(0xFFE4F1EA);
  static const Color background = Color(0xFFF4F8F5);
  static const Color textDark = Color(0xFF24463E);
  static const Color textSoft = Color(0xFF64756E);
  static const Color borderColor = Color(0xFFE1EAE5);

  final FirestoreService _firestore = FirestoreService();
  final AuthService _auth = AuthService();

  int _selectedIndex = 0;
  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _isLoggingOut = false;
  String? _errorMessage;
  UserModel? _profile;

  final List<String> _titles = const [
    'Inicio',
    'Mis pacientes',
    'Notificaciones',
    'Mi perfil',
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile({bool refresh = false}) async {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.auth,
            (route) => false,
      );
      return;
    }

    setState(() {
      refresh ? _isRefreshing = true : _isLoading = true;
      _errorMessage = null;
    });

    try {
      final profile = await _firestore.getUser(user.uid);
      if (!mounted) return;
      setState(() => _profile = profile);
    } catch (error, stackTrace) {
      debugPrint('Error al cargar el panel familiar: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      setState(() {
        _errorMessage =
        'No fue posible cargar la información. Revisa tu conexión.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    }
  }

  Future<void> _openPage(Widget page) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
    if (mounted) await _loadProfile(refresh: true);
  }

  int get _patientCount => _profile?.patients.length ?? 0;

  String get _firstName {
    final String profileName = _profile?.name.trim() ?? '';
    if (profileName.isNotEmpty) return profileName;

    final String? firebaseName =
    FirebaseAuth.instance.currentUser?.displayName?.trim();
    if (firebaseName != null && firebaseName.isNotEmpty) {
      return firebaseName.split(' ').first;
    }

    final String email = FirebaseAuth.instance.currentUser?.email ?? '';
    if (email.contains('@')) {
      final value = email.split('@').first;
      if (value.isNotEmpty) {
        return '${value[0].toUpperCase()}${value.substring(1)}';
      }
    }
    return 'Familiar';
  }

  String get _fullName {
    if (_profile == null) return _firstName;
    final name = [
      _profile!.name,
      _profile!.paternalLastName,
      _profile!.maternalLastName,
    ].where((part) => part.trim().isNotEmpty).join(' ');
    return name.isEmpty ? _firstName : name;
  }

  String get _email {
    if (_profile?.email.trim().isNotEmpty == true) {
      return _profile!.email;
    }
    return FirebaseAuth.instance.currentUser?.email ??
        'Correo no disponible';
  }

  String get _initial =>
      _firstName.isEmpty ? 'F' : _firstName.substring(0, 1).toUpperCase();

  ImageProvider<Object>? get _profileImageProvider {
    final firestoreImage = _profile?.profileImage.trim() ?? '';
    if (firestoreImage.isNotEmpty) return NetworkImage(firestoreImage);

    final firebaseImage =
        FirebaseAuth.instance.currentUser?.photoURL?.trim() ?? '';
    if (firebaseImage.isNotEmpty) return NetworkImage(firebaseImage);

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: _buildAppBar(),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildHomeView(),
          _buildPatientsView(),
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
              Icons.family_restroom_rounded,
              color: primaryDark,
            ),
          ),
          const SizedBox(width: 11),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'VitaCare',
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
          tooltip: 'Actualizar',
          onPressed: _isRefreshing
              ? null
              : () => _loadProfile(refresh: true),
          icon: _isRefreshing
              ? const SizedBox(
            width: 21,
            height: 21,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
              : const Icon(Icons.refresh_rounded),
        ),
        IconButton(
          tooltip: 'Notificaciones',
          onPressed: () => setState(() => _selectedIndex = 2),
          icon: Badge(
            isLabelVisible: false,
            child: Icon(
              _selectedIndex == 2
                  ? Icons.notifications_rounded
                  : Icons.notifications_none_rounded,
              color: primaryDark,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 14),
          child: InkWell(
            borderRadius: BorderRadius.circular(30),
            onTap: () => setState(() => _selectedIndex = 3),
            child: CircleAvatar(
              radius: 19,
              backgroundColor: primaryDark,
              backgroundImage: _profileImageProvider,
              child: _profileImageProvider == null
                  ? Text(
                _initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              )
                  : null,
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
      onDestinationSelected: (index) {
        setState(() => _selectedIndex = index);
        if (index == 0) _loadProfile(refresh: true);
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded, color: primaryDark),
          label: 'Inicio',
        ),
        NavigationDestination(
          icon: Icon(Icons.people_alt_outlined),
          selectedIcon: Icon(Icons.people_alt_rounded, color: primaryDark),
          label: 'Pacientes',
        ),
        NavigationDestination(
          icon: Icon(Icons.notifications_none_rounded),
          selectedIcon: Icon(Icons.notifications_rounded, color: primaryDark),
          label: 'Avisos',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline_rounded),
          selectedIcon: Icon(Icons.person_rounded, color: primaryDark),
          label: 'Perfil',
        ),
      ],
    );
  }

  Widget _buildHomeView() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: primaryDark),
      );
    }
    if (_errorMessage != null) return _buildErrorState();

    return RefreshIndicator(
      color: primaryDark,
      onRefresh: () => _loadProfile(refresh: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
        children: [
          _buildWelcomeCard(),
          const SizedBox(height: 20),
          _buildSummaryCards(),
          const SizedBox(height: 24),
          _buildSectionHeader(
            title: 'Accesos rápidos',
            actionText: 'Actualizar',
            onTap: () => _loadProfile(refresh: true),
          ),
          const SizedBox(height: 14),
          _buildQuickAccessGrid(),
          const SizedBox(height: 24),
          _buildCareNetworkCard(),
          const SizedBox(height: 24),
          _buildTipCard(),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4B927B), Color(0xFF285F50)],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: primaryDark.withOpacity(0.20),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${_getGreeting()}, $_firstName',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.14),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.family_restroom_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _patientCount == 0
                ? 'Vincula a tu primer paciente para comenzar a acompañar su tratamiento.'
                : _patientCount == 1
                ? 'Tienes 1 paciente bajo tu cuidado.'
                : 'Tienes $_patientCount pacientes bajo tu cuidado.',
            style: const TextStyle(
              color: Color(0xFFE6F3ED),
              fontSize: 14,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.13),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _HeroMetric(
                    icon: Icons.people_alt_rounded,
                    label: 'Pacientes vinculados',
                    value: '$_patientCount',
                  ),
                ),
                const SizedBox(
                  height: 38,
                  child: VerticalDivider(color: Color(0x55FFFFFF)),
                ),
                const Expanded(
                  child: _HeroMetric(
                    icon: Icons.shield_outlined,
                    label: 'Acceso autorizado',
                    value: 'Seguro',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.people_alt_rounded,
            value: '$_patientCount',
            label: 'Pacientes',
            background: primaryLight,
            iconColor: primaryDark,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: _StatCard(
            icon: Icons.notifications_active_rounded,
            value: '0',
            label: 'Alertas',
            background: Color(0xFFFFF0DF),
            iconColor: Color(0xFFB66A2D),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.check_circle_rounded,
            value: _patientCount > 0 ? 'Activo' : 'Pendiente',
            label: 'Estado',
            background: const Color(0xFFE7F5E9),
            iconColor: const Color(0xFF43855A),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAccessGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.02,
      children: [
        _DashboardMenuCard(
          icon: Icons.qr_code_scanner_rounded,
          title: 'Vincular paciente',
          subtitle: 'Escanea un código QR de forma segura',
          iconBackground: primaryLight,
          iconColor: primaryDark,
          onTap: () => _openPage(const ScanQrView()),
        ),
        _DashboardMenuCard(
          icon: Icons.people_alt_rounded,
          title: 'Mis pacientes',
          subtitle: '$_patientCount personas vinculadas',
          iconBackground: const Color(0xFFF0EAF8),
          iconColor: const Color(0xFF73539B),
          onTap: () => _openPage(const MyPatientsView()),
        ),
        _DashboardMenuCard(
          icon: Icons.medication_rounded,
          title: 'Medicamentos',
          subtitle: 'Supervisa tratamientos y horarios',
          iconBackground: const Color(0xFFE7F3ED),
          iconColor: primaryDark,
          onTap: () => _showComingSoon('Medicamentos'),
        ),
        _DashboardMenuCard(
          icon: Icons.notifications_active_rounded,
          title: 'Alertas',
          subtitle: 'Revisa avisos importantes',
          iconBackground: const Color(0xFFFFF0DF),
          iconColor: const Color(0xFFB66A2D),
          onTap: () => setState(() => _selectedIndex = 2),
        ),
        _DashboardMenuCard(
          icon: Icons.location_on_rounded,
          title: 'Ubicación',
          subtitle: 'Consulta la ubicación autorizada',
          iconBackground: const Color(0xFFE6EFF7),
          iconColor: const Color(0xFF3E668B),
          onTap: () => _showComingSoon('Ubicación'),
        ),
        _DashboardMenuCard(
          icon: Icons.smart_toy_rounded,
          title: 'VitaCare AI',
          subtitle: 'Asistente para el cuidado familiar',
          iconBackground: const Color(0xFFE6F3F3),
          iconColor: const Color(0xFF31787A),
          onTap: () => _showComingSoon('Asistente VitaCare AI'),
        ),
      ],
    );
  }

  Widget _buildCareNetworkCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              _SquareIcon(
                icon: Icons.hub_rounded,
                background: primaryLight,
                color: primaryDark,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tu red de cuidado',
                      style: TextStyle(
                        color: textDark,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Gestiona a las personas vinculadas',
                      style: TextStyle(color: textSoft, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (_patientCount == 0)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FBF9),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.person_add_alt_1_rounded,
                    color: primaryDark,
                    size: 34,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Aún no tienes pacientes vinculados',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: textDark,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Escanea el código QR del paciente para comenzar.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: textSoft,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => _openPage(const ScanQrView()),
                      icon: const Icon(Icons.qr_code_scanner_rounded),
                      label: const Text('Vincular paciente'),
                      style: FilledButton.styleFrom(
                        backgroundColor: primaryDark,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const _SquareIcon(
                icon: Icons.people_alt_rounded,
                background: primaryLight,
                color: primaryDark,
              ),
              title: Text(
                _patientCount == 1
                    ? '1 paciente vinculado'
                    : '$_patientCount pacientes vinculados',
                style: const TextStyle(
                  color: textDark,
                  fontWeight: FontWeight.w800,
                ),
              ),
              subtitle: const Text(
                'Consulta sus perfiles y seguimiento',
                style: TextStyle(color: textSoft),
              ),
              trailing: const Icon(
                Icons.chevron_right_rounded,
                color: primaryDark,
              ),
              onTap: () => _openPage(const MyPatientsView()),
            ),
        ],
      ),
    );
  }

  Widget _buildTipCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE6F3F3), Color(0xFFEAF5EF)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFCDE3DE)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: Colors.white,
            child: Icon(
              Icons.tips_and_updates_rounded,
              color: Color(0xFF31787A),
            ),
          ),
          SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Consejo de cuidado',
                  style: TextStyle(
                    color: textDark,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 7),
                Text(
                  'Revisa con frecuencia las alertas y el cumplimiento de los tratamientos de tus pacientes.',
                  style: TextStyle(
                    color: textDark,
                    fontSize: 14,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientsView() {
    return _simpleSection(
      icon: Icons.people_alt_rounded,
      title: 'Mis pacientes',
      description: _patientCount == 0
          ? 'Aún no tienes pacientes vinculados.'
          : 'Tienes $_patientCount paciente${_patientCount == 1 ? '' : 's'} bajo tu cuidado.',
      buttonText: 'Ver mis pacientes',
      buttonIcon: Icons.visibility_outlined,
      onPressed: () => _openPage(const MyPatientsView()),
      extra: _ProfileOption(
        icon: Icons.qr_code_scanner_rounded,
        title: 'Vincular otro paciente',
        subtitle: 'Escanea un nuevo código QR',
        onTap: () => _openPage(const ScanQrView()),
      ),
    );
  }

  Widget _buildNotificationsView() {
    return _simpleSection(
      icon: Icons.notifications_active_rounded,
      title: 'Centro de alertas',
      description:
      'Aquí aparecerán alertas de medicamentos, actividad y situaciones importantes de tus pacientes.',
      buttonText: 'Actualizar alertas',
      buttonIcon: Icons.refresh_rounded,
      onPressed: () => _loadProfile(refresh: true),
      extra: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
        ),
        child: const Row(
          children: [
            Icon(
              Icons.notifications_none_rounded,
              color: textSoft,
              size: 30,
            ),
            SizedBox(width: 13),
            Expanded(
              child: Text(
                'No hay alertas nuevas en este momento.',
                style: TextStyle(color: textSoft, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _simpleSection({
    required IconData icon,
    required String title,
    required String description,
    required String buttonText,
    required IconData buttonIcon,
    required VoidCallback onPressed,
    required Widget extra,
  }) {
    return RefreshIndicator(
      color: primaryDark,
      onRefresh: () => _loadProfile(refresh: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: primaryDark, size: 37),
                ),
                const SizedBox(height: 14),
                Text(
                  title,
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: textSoft,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: onPressed,
                    icon: Icon(buttonIcon),
                    label: Text(buttonText),
                    style: FilledButton.styleFrom(
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
          const SizedBox(height: 16),
          extra,
        ],
      ),
    );
  }

  Widget _buildProfileView() {
    return RefreshIndicator(
      color: primaryDark,
      onRefresh: () => _loadProfile(refresh: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: primaryLight,
                  backgroundImage: _profileImageProvider,
                  child: _profileImageProvider == null
                      ? Text(
                    _initial,
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
                  _fullName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _email,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: textSoft, fontSize: 14),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _ProfileMetric(
                        value: '$_patientCount',
                        label: 'Pacientes',
                      ),
                    ),
                    const SizedBox(
                      height: 38,
                      child: VerticalDivider(color: borderColor),
                    ),
                    const Expanded(
                      child: _ProfileMetric(value: 'Familiar', label: 'Rol'),
                    ),
                    const SizedBox(
                      height: 38,
                      child: VerticalDivider(color: borderColor),
                    ),
                    const Expanded(
                      child: _ProfileMetric(value: 'Activo', label: 'Estado'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _ProfileOption(
            icon: Icons.person_outline_rounded,
            title: 'Información personal',
            subtitle: _profile?.phoneNumber.isNotEmpty == true
                ? _profile!.phoneNumber
                : 'Consulta tus datos personales',
            onTap: () => _showComingSoon('Información personal'),
          ),
          _ProfileOption(
            icon: Icons.people_alt_outlined,
            title: 'Mis pacientes',
            subtitle: '$_patientCount personas vinculadas',
            onTap: () => _openPage(const MyPatientsView()),
          ),
          _ProfileOption(
            icon: Icons.qr_code_scanner_rounded,
            title: 'Vincular paciente',
            subtitle: 'Escanea un código QR',
            onTap: () => _openPage(const ScanQrView()),
          ),
          _ProfileOption(
            icon: Icons.settings_outlined,
            title: 'Configuración',
            subtitle: 'Preferencias de la aplicación',
            onTap: () => _showComingSoon('Configuración'),
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
                child: CircularProgressIndicator(strokeWidth: 2.3),
              )
                  : const Icon(Icons.logout_rounded),
              label: Text(
                _isLoggingOut ? 'Cerrando sesión...' : 'Cerrar sesión',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFB94747),
                side: const BorderSide(color: Color(0xFFEABBBB)),
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

  Widget _buildErrorState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 100),
        const Icon(Icons.cloud_off_rounded, size: 70, color: textSoft),
        const SizedBox(height: 18),
        Text(
          _errorMessage ?? 'Ocurrió un error inesperado.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: textDark,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 18),
        ElevatedButton.icon(
          onPressed: _loadProfile,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Intentar nuevamente'),
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryDark,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String actionText,
    required VoidCallback onTap,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: textDark,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        TextButton(
          onPressed: onTap,
          child: Text(
            actionText,
            style: const TextStyle(
              color: primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmLogout() async {
    final bool? shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          icon: const CircleAvatar(
            radius: 28,
            backgroundColor: Color(0xFFFFE8E8),
            child: Icon(Icons.logout_rounded, color: Color(0xFFB94747)),
          ),
          title: const Text(
            '¿Cerrar sesión?',
            textAlign: TextAlign.center,
            style: TextStyle(color: textDark, fontWeight: FontWeight.w700),
          ),
          content: const Text(
            'Tendrás que iniciar sesión nuevamente para entrar a VitaCare AI.',
            textAlign: TextAlign.center,
            style: TextStyle(color: textSoft, height: 1.4),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
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

    if (shouldLogout == true) await _logout();
  }

  Future<void> _logout() async {
    try {
      setState(() => _isLoggingOut = true);
      await _auth.logout();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.auth,
            (route) => false,
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
      if (mounted) setState(() => _isLoggingOut = false);
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Buenos días';
    if (hour < 19) return 'Buenas tardes';
    return 'Buenas noches';
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
        margin: const EdgeInsets.all(18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: Row(
          children: [
            Icon(icon, color: foregroundColor),
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

class _HeroMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _HeroMetric({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 22),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFFDCEFE8),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color background;
  final Color iconColor;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.background,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _CaregiverDashboardViewState.borderColor,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _CaregiverDashboardViewState.textDark,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _CaregiverDashboardViewState.textSoft,
              fontSize: 11,
            ),
          ),
        ],
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
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: _CaregiverDashboardViewState.borderColor,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: iconColor, size: 26),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _CaregiverDashboardViewState.textDark,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _CaregiverDashboardViewState.textSoft,
                      fontSize: 11.5,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SquareIcon extends StatelessWidget {
  final IconData icon;
  final Color background;
  final Color color;

  const _SquareIcon({
    required this.icon,
    required this.background,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(icon, color: color, size: 27),
    );
  }
}

class _ProfileMetric extends StatelessWidget {
  final String value;
  final String label;

  const _ProfileMetric({
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: _CaregiverDashboardViewState.primaryDark,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _CaregiverDashboardViewState.textSoft,
            fontSize: 10,
          ),
        ),
      ],
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
          color: _CaregiverDashboardViewState.borderColor,
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
            color: _CaregiverDashboardViewState.primaryLight,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            icon,
            color: _CaregiverDashboardViewState.primaryDark,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: _CaregiverDashboardViewState.textDark,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            color: _CaregiverDashboardViewState.textSoft,
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