import 'package:flutter/material.dart';

import '../../models/user_model.dart';

class PersonalInformationView extends StatelessWidget {
  final UserModel? patient;

  const PersonalInformationView({
    super.key,
    required this.patient,
  });

  static const Color primaryDark = Color(0xFF285F50);
  static const Color primary = Color(0xFF3E806B);
  static const Color primaryLight = Color(0xFFE4F1EA);
  static const Color background = Color(0xFFF4F8F5);
  static const Color textDark = Color(0xFF24463E);
  static const Color textSoft = Color(0xFF64756E);
  static const Color borderColor = Color(0xFFE1EAE5);

  @override
  Widget build(BuildContext context) {
    final UserModel? user = patient;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text(
          'Información personal',
          style: TextStyle(
            color: textDark,
            fontWeight: FontWeight.w800,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: primaryDark,
        surfaceTintColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      body: user == null
          ? const _EmptyInformationState()
          : SafeArea(
        top: false,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            20,
            18,
            20,
            32,
          ),
          children: [
            _buildHeader(user),
            const SizedBox(height: 20),
            _buildSummary(user),
            const SizedBox(height: 24),
            const _SectionTitle(
              title: 'Datos personales',
              subtitle:
              'Información principal registrada en tu perfil',
            ),
            const SizedBox(height: 12),
            _InformationCard(
              children: [
                _InformationItem(
                  icon: Icons.person_outline_rounded,
                  label: 'Nombre completo',
                  value: _fullName(user),
                ),
                const _InformationDivider(),
                _InformationItem(
                  icon: Icons.email_outlined,
                  label: 'Correo electrónico',
                  value: _valueOrFallback(user.email),
                ),
                const _InformationDivider(),
                _InformationItem(
                  icon: Icons.phone_outlined,
                  label: 'Teléfono',
                  value: _valueOrFallback(
                    user.phoneNumber,
                  ),
                ),
                const _InformationDivider(),
                _InformationItem(
                  icon: Icons.cake_outlined,
                  label: 'Fecha de nacimiento',
                  value: _formatDate(
                    user.birthDate,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            const _SectionTitle(
              title: 'Salud y seguridad',
              subtitle:
              'Datos importantes para tu cuidado',
            ),
            const SizedBox(height: 12),
            _InformationCard(
              children: [
                _InformationItem(
                  icon:
                  Icons.contact_emergency_outlined,
                  label:
                  'Contacto de emergencia',
                  value: _valueOrFallback(
                    user.emergencyContact,
                  ),
                  iconBackground:
                  const Color(0xFFFFE8E8),
                  iconColor:
                  const Color(0xFFB94747),
                ),
                const _InformationDivider(),
                _InformationItem(
                  icon:
                  Icons.health_and_safety_outlined,
                  label:
                  'Enfermedades registradas',
                  value: user.diseases.isEmpty
                      ? 'Ninguna registrada'
                      : user.diseases.join(', '),
                  iconBackground:
                  const Color(0xFFE6EFF7),
                  iconColor:
                  const Color(0xFF3E668B),
                ),
              ],
            ),
            const SizedBox(height: 22),
            const _SectionTitle(
              title: 'Cuenta',
              subtitle:
              'Información de acceso y tipo de usuario',
            ),
            const SizedBox(height: 12),
            _InformationCard(
              children: [
                _InformationItem(
                  icon:
                  Icons.supervisor_account_outlined,
                  label: 'Rol',
                  value: _roleLabel(user.role),
                  iconBackground:
                  const Color(0xFFF0EAF8),
                  iconColor:
                  const Color(0xFF73539B),
                ),
                const _InformationDivider(),
                _InformationItem(
                  icon:
                  Icons.verified_user_outlined,
                  label: 'Estado del perfil',
                  value: user.isProfileComplete
                      ? 'Perfil completo'
                      : 'Perfil incompleto',
                  iconBackground:
                  user.isProfileComplete
                      ? const Color(0xFFE7F5E9)
                      : const Color(0xFFFFF0DF),
                  iconColor:
                  user.isProfileComplete
                      ? const Color(0xFF43855A)
                      : const Color(0xFFB66A2D),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildPrivacyNotice(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(UserModel user) {
    final String image = user.profileImage.trim();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF4B927B),
            Color(0xFF285F50),
          ],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: primaryDark.withOpacity(0.20),
            blurRadius: 24,
            offset: const Offset(0, 11),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 112,
                height: 112,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.18),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.85),
                    width: 4,
                  ),
                ),
                child: CircleAvatar(
                  backgroundColor:
                  Colors.white.withOpacity(0.18),
                  backgroundImage:
                  image.isNotEmpty
                      ? NetworkImage(image)
                      : null,
                  child: image.isEmpty
                      ? Text(
                    _initial(user),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 38,
                      fontWeight:
                      FontWeight.w900,
                    ),
                  )
                      : null,
                ),
              ),
              Positioned(
                right: -2,
                bottom: 2,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color:
                    const Color(0xFFBDE8C8),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 3,
                    ),
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: primaryDark,
                    size: 19,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _fullName(user),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _roleLabel(user.role),
            style: const TextStyle(
              color: Color(0xFFE6F3ED),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 13,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.13),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Row(
              mainAxisAlignment:
              MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.shield_outlined,
                  color: Colors.white,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'Datos protegidos por VitaCare AI',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(UserModel user) {
    return Row(
      children: [
        Expanded(
          child: _SummaryMetric(
            icon: Icons.phone_rounded,
            value: user.phoneNumber.trim().isEmpty
                ? 'Pendiente'
                : 'Registrado',
            label: 'Teléfono',
            background:
            const Color(0xFFE4F1EA),
            iconColor: primaryDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryMetric(
            icon: Icons.favorite_rounded,
            value: '${user.diseases.length}',
            label: user.diseases.length == 1
                ? 'Condición'
                : 'Condiciones',
            background:
            const Color(0xFFFFE8E8),
            iconColor:
            const Color(0xFFB94747),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryMetric(
            icon: Icons.verified_rounded,
            value: user.isProfileComplete
                ? 'Completo'
                : 'Pendiente',
            label: 'Perfil',
            background:
            const Color(0xFFE7F5E9),
            iconColor:
            const Color(0xFF43855A),
          ),
        ),
      ],
    );
  }

  Widget _buildPrivacyNotice() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFE6F3F3),
            Color(0xFFEAF5EF),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFCDE3DE),
        ),
      ),
      child: const Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.white,
            child: Icon(
              Icons.lock_outline_rounded,
              color: Color(0xFF31787A),
            ),
          ),
          SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  'Tu información está protegida',
                  style: TextStyle(
                    color: textDark,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Estos datos se utilizan únicamente para personalizar tu experiencia y mejorar tu cuidado dentro de VitaCare AI.',
                  style: TextStyle(
                    color: textSoft,
                    fontSize: 13,
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

  String _fullName(UserModel user) {
    final String name = [
      user.name,
      user.paternalLastName,
      user.maternalLastName,
    ].where(
          (value) => value.trim().isNotEmpty,
    ).join(' ');

    return name.isEmpty ? 'Paciente' : name;
  }

  String _initial(UserModel user) {
    final String name = user.name.trim();

    return name.isEmpty
        ? 'P'
        : name.substring(0, 1).toUpperCase();
  }

  String _valueOrFallback(String value) {
    return value.trim().isEmpty
        ? 'Sin registrar'
        : value.trim();
  }

  String _formatDate(DateTime date) {
    const months = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];

    return '${date.day} de '
        '${months[date.month - 1]} de '
        '${date.year}';
  }

  String _roleLabel(String role) {
    switch (role.toLowerCase()) {
      case 'caregiver':
        return 'Cuidador';
      case 'both':
        return 'Paciente y cuidador';
      case 'patient':
      default:
        return 'Paciente';
    }
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color:
            PersonalInformationView.textDark,
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            color:
            PersonalInformationView.textSoft,
            fontSize: 12,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _InformationCard extends StatelessWidget {
  final List<Widget> children;

  const _InformationCard({
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color:
          PersonalInformationView.borderColor,
        ),
        boxShadow: [
          BoxShadow(
            color: PersonalInformationView.primaryDark
                .withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }
}

class _InformationItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? iconBackground;
  final Color? iconColor;

  const _InformationItem({
    required this.icon,
    required this.label,
    required this.value,
    this.iconBackground,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: iconBackground ??
                  PersonalInformationView
                      .primaryLight,
              borderRadius:
              BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: iconColor ??
                  PersonalInformationView
                      .primaryDark,
              size: 23,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color:
                    PersonalInformationView
                        .textSoft,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  style: const TextStyle(
                    color:
                    PersonalInformationView
                        .textDark,
                    fontSize: 14,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
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

class _InformationDivider extends StatelessWidget {
  const _InformationDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      indent: 75,
      endIndent: 16,
      color: PersonalInformationView.borderColor,
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color background;
  final Color iconColor;

  const _SummaryMetric({
    required this.icon,
    required this.value,
    required this.label,
    required this.background,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color:
          PersonalInformationView.borderColor,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 41,
            height: 41,
            decoration: BoxDecoration(
              color: background,
              borderRadius:
              BorderRadius.circular(13),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 21,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color:
              PersonalInformationView.textDark,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color:
              PersonalInformationView.textSoft,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyInformationState extends StatelessWidget {
  const _EmptyInformationState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                color:
                PersonalInformationView
                    .primaryLight,
                borderRadius:
                BorderRadius.circular(30),
              ),
              child: const Icon(
                Icons.person_off_outlined,
                color:
                PersonalInformationView
                    .primaryDark,
                size: 46,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Información no disponible',
              textAlign: TextAlign.center,
              style: TextStyle(
                color:
                PersonalInformationView
                    .textDark,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'No fue posible cargar la información del paciente.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color:
                PersonalInformationView
                    .textSoft,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(context);
              },
              icon:
              const Icon(Icons.arrow_back_rounded),
              label: const Text('Regresar'),
              style: FilledButton.styleFrom(
                backgroundColor:
                PersonalInformationView
                    .primaryDark,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}