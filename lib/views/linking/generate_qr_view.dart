import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../services/firestore_service.dart';

class GenerateQrView extends StatefulWidget {
  const GenerateQrView({super.key});

  @override
  State<GenerateQrView> createState() => _GenerateQrViewState();
}

class _GenerateQrViewState extends State<GenerateQrView> {
  final FirestoreService _firestoreService = FirestoreService();

  static const Color primaryColor = Color(0xFF168C7E);
  static const Color primaryDark = Color(0xFF0E6F65);
  static const Color mintColor = Color(0xFFE5F5F2);
  static const Color backgroundColor = Color(0xFFF7FBFA);
  static const Color textColor = Color(0xFF263936);
  static const Color secondaryTextColor = Color(0xFF687A78);

  String _qrData = '';
  String _linkCode = '';

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadQr();
  }

  Future<void> _loadQr() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final User? authUser = FirebaseAuth.instance.currentUser;

      if (authUser == null) {
        throw Exception('No existe una sesión activa.');
      }

      final user = await _firestoreService.getUser(authUser.uid);

      if (user == null) {
        throw Exception(
          'No fue posible encontrar la información del usuario.',
        );
      }

      final String code = user.linkCode?.trim() ?? '';

      final String qrJson = jsonEncode({
        'uid': authUser.uid,
        'code': code.isEmpty ? null : code,
      });

      if (!mounted) return;

      setState(() {
        _qrData = qrJson;
        _linkCode = code;
        _isLoading = false;
      });
    } catch (error, stackTrace) {
      debugPrint('Error al generar el código QR: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _copyLinkCode() async {
    if (_linkCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay un código de vinculación disponible.'),
        ),
      );
      return;
    }

    await Clipboard.setData(
      ClipboardData(text: _linkCode),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
              color: Colors.white,
            ),
            SizedBox(width: 10),
            Text('Código copiado correctamente'),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: primaryDark,
        duration: Duration(seconds: 2),
      ),
    );
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
          'Mi QR de Vinculación',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Stack(
        children: [
          const Positioned(
            top: -80,
            left: -85,
            child: _DecorativeCircle(
              size: 210,
              color: Color(0xFFDDF2EE),
            ),
          ),
          const Positioned(
            top: 110,
            right: -55,
            child: _DecorativeCircle(
              size: 135,
              color: Color(0xFFE9F7F4),
            ),
          ),
          const Positioned(
            bottom: -90,
            right: -75,
            child: _DecorativeCircle(
              size: 225,
              color: Color(0xFFDDF2EE),
            ),
          ),
          SafeArea(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const _LoadingView();
    }

    if (_errorMessage != null) {
      return _ErrorView(
        message: _errorMessage!,
        onRetry: _loadQr,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadQr,
      color: primaryColor,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(22, 26, 22, 38),
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildQrCard(),
            const SizedBox(height: 18),
            _buildLinkCodeCard(),
            const SizedBox(height: 22),
            _buildInstructionsCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 82,
          height: 82,
          decoration: BoxDecoration(
            color: mintColor,
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFFCAE9E3),
              width: 2,
            ),
          ),
          child: const Icon(
            Icons.family_restroom_rounded,
            color: primaryDark,
            size: 41,
          ),
        ),
        const SizedBox(height: 17),
        const Text(
          'Comparte este QR',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: primaryDark,
            fontSize: 25,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'con tu cuidador',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: textColor,
            fontSize: 21,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 10),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'Tu familiar podrá escanearlo para vincularse contigo y ayudarte con el cuidado de tu salud.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: secondaryTextColor,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQrCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(0xFFBFE3DD),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.14),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(13),
            child: AspectRatio(
              aspectRatio: 1,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(21),
                ),
                child: QrImageView(
                  data: _qrData,
                  version: QrVersions.auto,
                  backgroundColor: Colors.white,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Colors.black,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Colors.black,
                  ),
                  errorCorrectionLevel: QrErrorCorrectLevel.H,
                ),
              ),
            ),
          ),
          const Positioned(
            top: 0,
            left: 0,
            child: _QrCorner(
              quarterTurns: 0,
            ),
          ),
          const Positioned(
            top: 0,
            right: 0,
            child: _QrCorner(
              quarterTurns: 1,
            ),
          ),
          const Positioned(
            bottom: 0,
            right: 0,
            child: _QrCorner(
              quarterTurns: 2,
            ),
          ),
          const Positioned(
            bottom: 0,
            left: 0,
            child: _QrCorner(
              quarterTurns: 3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkCodeCard() {
    final bool hasCode = _linkCode.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 12, 16),
      decoration: BoxDecoration(
        color: mintColor,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(
          color: const Color(0xFFCBE9E4),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.link_rounded,
              color: primaryColor,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Código de vinculación',
                  style: TextStyle(
                    color: secondaryTextColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  hasCode ? _linkCode : 'No disponible',
                  style: TextStyle(
                    color: hasCode
                        ? primaryDark
                        : secondaryTextColor,
                    fontSize: hasCode ? 20 : 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: hasCode ? 1.5 : 0,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Copiar código',
            onPressed: hasCode ? _copyLinkCode : null,
            icon: const Icon(
              Icons.copy_rounded,
            ),
            color: primaryColor,
            disabledColor: Colors.grey.shade400,
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFDDEDEA),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: mintColor,
                child: Icon(
                  Icons.verified_user_outlined,
                  color: primaryDark,
                ),
              ),
              SizedBox(width: 12),
              Text(
                '¿Cómo funciona?',
                style: TextStyle(
                  color: primaryDark,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          SizedBox(height: 17),
          _InstructionStep(
            number: '1',
            text: 'El familiar inicia sesión en VitaCare AI.',
          ),
          SizedBox(height: 11),
          _InstructionStep(
            number: '2',
            text: 'Selecciona la opción “Vincular paciente”.',
          ),
          SizedBox(height: 11),
          _InstructionStep(
            number: '3',
            text: 'Escanea este código QR.',
          ),
        ],
      ),
    );
  }
}

class _InstructionStep extends StatelessWidget {
  final String number;
  final String text;

  const _InstructionStep({
    required this.number,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 25,
          height: 25,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: Color(0xFFE5F5F2),
            shape: BoxShape.circle,
          ),
          child: Text(
            number,
            style: const TextStyle(
              color: Color(0xFF0E6F65),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF5D706D),
                fontSize: 13.5,
                height: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _QrCorner extends StatelessWidget {
  final int quarterTurns;

  const _QrCorner({
    required this.quarterTurns,
  });

  @override
  Widget build(BuildContext context) {
    return RotatedBox(
      quarterTurns: quarterTurns,
      child: const SizedBox(
        width: 40,
        height: 40,
        child: CustomPaint(
          painter: _QrCornerPainter(),
        ),
      ),
    );
  }
}

class _QrCornerPainter extends CustomPainter {
  const _QrCornerPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = const Color(0xFF168C7E)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final Path path = Path()
      ..moveTo(4, size.height - 4)
      ..lineTo(4, 13)
      ..quadraticBezierTo(4, 4, 13, 4)
      ..lineTo(size.width - 4, 4);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

class _DecorativeCircle extends StatelessWidget {
  final double size;
  final Color color;

  const _DecorativeCircle({
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.8),
          shape: BoxShape.circle,
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
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFFE3EFED),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 75,
                height: 75,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFEEED),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.qr_code_2_rounded,
                  color: Color(0xFFD86763),
                  size: 38,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'No fue posible generar el QR',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF263936),
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 9),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF687A78),
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 21),
              SizedBox(
                width: double.infinity,
                height: 49,
                child: ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text(
                    'Intentar nuevamente',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF168C7E),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
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