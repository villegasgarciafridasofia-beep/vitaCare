import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import '../linking/generate_qr_view.dart';

class MyCaregiversView extends StatefulWidget {
  const MyCaregiversView({super.key});

  @override
  State<MyCaregiversView> createState() => _MyCaregiversViewState();
}

class _MyCaregiversViewState extends State<MyCaregiversView> {
  final FirestoreService _firestoreService = FirestoreService();

  late Future<List<UserModel>> _caregiversFuture;

  static const Color primaryColor = Color(0xFF168C7E);
  static const Color backgroundColor = Color(0xFFF4F8F7);
  static const Color textColor = Color(0xFF253238);
  static const Color secondaryTextColor = Color(0xFF687A78);

  @override
  void initState() {
    super.initState();
    _caregiversFuture = _loadCaregivers();
  }

  Future<List<UserModel>> _loadCaregivers() async {
    final User? authUser = FirebaseAuth.instance.currentUser;

    if (authUser == null) {
      throw Exception('No existe una sesión activa.');
    }

    final UserModel? patient = await _firestoreService.getUser(authUser.uid);

    if (patient == null) {
      throw Exception('No fue posible encontrar la información del paciente.');
    }

    if (patient.caregivers.isEmpty) {
      return [];
    }

    return _firestoreService.getCaregivers(patient.caregivers);
  }

  Future<void> _refreshCaregivers() async {
    setState(() {
      _caregiversFuture = _loadCaregivers();
    });

    await _caregiversFuture;
  }

  Future<void> _openGenerateQr() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const GenerateQrView(),
      ),
    );

    if (!mounted) return;

    await _refreshCaregivers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        elevation: 0,
        centerTitle: false,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        title: const Text(
          'Mis familiares',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Generar código QR',
            onPressed: _openGenerateQr,
            icon: const Icon(Icons.qr_code_rounded),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: FutureBuilder<List<UserModel>>(
        future: _caregiversFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _LoadingView();
          }

          if (snapshot.hasError) {
            return _ErrorView(
              message: snapshot.error.toString().replaceFirst(
                'Exception: ',
                '',
              ),
              onRetry: _refreshCaregivers,
            );
          }

          final List<UserModel> caregivers = snapshot.data ?? [];

          if (caregivers.isEmpty) {
            return _EmptyCaregiversView(
              onGenerateQr: _openGenerateQr,
            );
          }

          return RefreshIndicator(
            onRefresh: _refreshCaregivers,
            color: primaryColor,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 30),
              children: [
                _CaregiversHeader(
                  caregiversCount: caregivers.length,
                  onGenerateQr: _openGenerateQr,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Familiares vinculados',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                ...caregivers.map(
                      (caregiver) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _CaregiverCard(
                      caregiver: caregiver,
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
}

class _CaregiversHeader extends StatelessWidget {
  final int caregiversCount;
  final VoidCallback onGenerateQr;

  const _CaregiversHeader({
    required this.caregiversCount,
    required this.onGenerateQr,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF168C7E),
            Color(0xFF42AFA0),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF168C7E).withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.white24,
                child: Icon(
                  Icons.family_restroom_rounded,
                  color: Colors.white,
                  size: 27,
                ),
              ),
              SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Red de cuidado',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            caregiversCount == 1
                ? 'Tienes 1 familiar vinculado'
                : 'Tienes $caregiversCount familiares vinculados',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: onGenerateQr,
              icon: const Icon(Icons.qr_code_2_rounded),
              label: const Text(
                'Vincular otro familiar',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF168C7E),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CaregiverCard extends StatelessWidget {
  final UserModel caregiver;

  const _CaregiverCard({
    required this.caregiver,
  });

  String get _fullName {
    return [
      caregiver.name,
      caregiver.paternalLastName,
      caregiver.maternalLastName,
    ].where((value) => value.trim().isNotEmpty).join(' ');
  }

  String get _initial {
    final String name = caregiver.name.trim();

    if (name.isEmpty) {
      return '?';
    }

    return name.substring(0, 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE4EEEC),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 29,
              backgroundColor: const Color(0xFFE0F2EF),
              child: Text(
                _initial,
                style: const TextStyle(
                  color: Color(0xFF168C7E),
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _fullName.isEmpty ? 'Familiar' : _fullName,
                    style: const TextStyle(
                      color: Color(0xFF253238),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 7),
                  if (caregiver.email.trim().isNotEmpty)
                    _InformationRow(
                      icon: Icons.email_outlined,
                      text: caregiver.email,
                    ),
                  if (caregiver.phoneNumber.trim().isNotEmpty) ...[
                    const SizedBox(height: 5),
                    _InformationRow(
                      icon: Icons.phone_outlined,
                      text: caregiver.phoneNumber,
                    ),
                  ],
                ],
              ),
            ),
            Container(
              width: 37,
              height: 37,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F8F6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.verified_user_outlined,
                color: Color(0xFF168C7E),
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InformationRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InformationRow({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: const Color(0xFF7A8C89),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF687A78),
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyCaregiversView extends StatelessWidget {
  final VoidCallback onGenerateQr;

  const _EmptyCaregiversView({
    required this.onGenerateQr,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 30, 24, 26),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: const Color(0xFFE4EEEC),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 18,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 86,
                height: 86,
                decoration: const BoxDecoration(
                  color: Color(0xFFE6F5F2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.family_restroom_rounded,
                  size: 43,
                  color: Color(0xFF168C7E),
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                'Aún no tienes familiares vinculados',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF253238),
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Genera tu código QR para que un familiar pueda escanearlo desde su cuenta de cuidador.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF687A78),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: onGenerateQr,
                  icon: const Icon(Icons.qr_code_2_rounded),
                  label: const Text(
                    'Generar código QR',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF168C7E),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorView({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Color(0xFFE16B68),
              size: 58,
            ),
            const SizedBox(height: 15),
            const Text(
              'No fue posible cargar los familiares',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF253238),
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF687A78),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Intentar nuevamente'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF168C7E),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        color: Color(0xFF168C7E),
      ),
    );
  }
}