import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RecuperarContrasenaView extends StatefulWidget {
  const RecuperarContrasenaView({super.key});

  @override
  State<RecuperarContrasenaView> createState() =>
      _RecuperarContrasenaViewState();
}

class _RecuperarContrasenaViewState
    extends State<RecuperarContrasenaView> {
  final TextEditingController emailController = TextEditingController();

  bool isLoading = false;
  String? emailError;

  static const Color primaryDark = Color(0xFF285F50);
  static const Color primary = Color(0xFF3E806B);
  static const Color background = Color(0xFFE8F3E8);
  static const Color textDark = Color(0xFF24463E);

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  bool _validateEmail() {
    final String email = emailController.text.trim();

    setState(() {
      emailError = null;

      if (email.isEmpty) {
        emailError = 'Ingresa tu correo electrónico';
      } else if (!RegExp(
        r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,}$',
      ).hasMatch(email)) {
        emailError = 'Ingresa un correo electrónico válido';
      }
    });

    return emailError == null;
  }

  Future<void> _sendRecoveryEmail() async {
    if (!_validateEmail()) {
      _showValidationMessage('Revisa el correo electrónico.');
      return;
    }

    try {
      setState(() {
        isLoading = true;
      });

      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: emailController.text.trim(),
      );

      if (!mounted) return;

      _showSuccessMessage(
        'Te enviamos un enlace para recuperar tu contraseña.',
      );

      emailController.clear();
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;

      String message =
          'No pudimos enviar el enlace de recuperación.';

      switch (error.code) {
        case 'invalid-email':
          message = 'El correo electrónico no es válido.';
          break;
        case 'user-not-found':
          message =
          'No encontramos una cuenta registrada con ese correo.';
          break;
        case 'too-many-requests':
          message =
          'Se realizaron demasiados intentos. Intenta más tarde.';
          break;
        case 'network-request-failed':
          message =
          'Revisa tu conexión a internet e intenta nuevamente.';
          break;
      }

      _showErrorMessage(message);
    } catch (_) {
      if (!mounted) return;

      _showErrorMessage(
        'Ocurrió un error inesperado. Intenta nuevamente.',
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _showValidationMessage(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFFFFF3E8),
        elevation: 6,
        margin: const EdgeInsets.all(18),
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(
            color: Color(0xFFFFC98B),
          ),
        ),
        content: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: Color(0xFFFFD9A8),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.info_outline_rounded,
                color: Color(0xFF9A5B11),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Color(0xFF6E4617),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFFEAF7EF),
        elevation: 6,
        margin: const EdgeInsets.all(18),
        duration: const Duration(seconds: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(
            color: Color(0xFF9BCFAF),
          ),
        ),
        content: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: Color(0xFFCFEBD9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.mark_email_read_outlined,
                color: Color(0xFF2F7652),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Color(0xFF285F50),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFFFFF1F1),
        elevation: 6,
        margin: const EdgeInsets.all(18),
        duration: const Duration(seconds: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(
            color: Color(0xFFF1B6B6),
          ),
        ),
        content: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: Color(0xFFFFDADA),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: Color(0xFFB33A3A),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Color(0xFF842D2D),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: background,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/login_background.png',
              fit: BoxFit.cover,
              alignment: Alignment.center,
              filterQuality: FilterQuality.high,
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Center(
                  child: FittedBox(
                    fit: BoxFit.contain,
                    alignment: Alignment.center,
                    child: SizedBox(
                      width: 390,
                      height: 844,
                      child: Stack(
                        children: [
                          Positioned(
                            top: 10,
                            left: 100,
                            child: _buildLogoFixed(),
                          ),
                          Positioned(
                            top: 14,
                            left: 14,
                            child: _buildBackButton(),
                          ),
                          const Positioned(
                            top: 205,
                            left: 0,
                            right: 0,
                            child: Text(
                              'Recuperar contraseña',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: textDark,
                                fontSize: 29,
                                height: 1,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.7,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 258,
                            left: 12,
                            right: 12,
                            child: _buildRecoveryCardFixed(),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton() {
    return Material(
      color: Colors.white.withOpacity(0.92),
      shape: const CircleBorder(),
      elevation: 4,
      shadowColor: primaryDark.withOpacity(0.18),
      child: IconButton(
        tooltip: 'Regresar',
        onPressed: isLoading
            ? null
            : () {
          Navigator.pop(context);
        },
        icon: const Icon(
          Icons.arrow_back_rounded,
          color: primaryDark,
          size: 25,
        ),
      ),
    );
  }

  Widget _buildLogoFixed() {
    const double size = 190;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF174A3F).withOpacity(0.28),
            blurRadius: 24,
            spreadRadius: 1,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/images/logo2.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.high,
          errorBuilder: (_, __, ___) {
            return Container(
              color: primaryDark,
              child: const Icon(
                Icons.health_and_safety_rounded,
                color: Colors.white,
                size: 105,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildRecoveryCardFixed() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 27, 22, 24),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBF6).withOpacity(0.98),
        borderRadius: BorderRadius.circular(34),
        border: Border.all(
          color: Colors.white.withOpacity(0.95),
          width: 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryDark.withOpacity(0.14),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: Color(0xFFE4F1EA),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock_reset_rounded,
              color: primary,
              size: 36,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '¿No recuerdas tu contraseña?',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textDark,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 9),
          const Text(
            'Ingresa el correo asociado a tu cuenta y te enviaremos '
                'un enlace para crear una nueva contraseña.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF64756E),
              fontSize: 14,
              height: 1.45,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 24),
          _buildEmailField(),
          const SizedBox(height: 24),
          _buildSendButton(),
          const SizedBox(height: 17),
          const Divider(
            color: Color(0xFFDCE3DE),
            thickness: 1,
            height: 1,
          ),
          const SizedBox(height: 14),
          _buildReturnToLogin(),
        ],
      ),
    );
  }

  Widget _buildEmailField() {
    final bool hasError = emailError != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          autofillHints: const [
            AutofillHints.email,
            AutofillHints.username,
          ],
          onChanged: (_) {
            if (emailError != null) {
              setState(() {
                emailError = null;
              });
            }
          },
          onSubmitted: (_) {
            if (!isLoading) {
              _sendRecoveryEmail();
            }
          },
          style: const TextStyle(
            color: textDark,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          cursorColor: primary,
          decoration: InputDecoration(
            hintText: 'Correo electrónico',
            hintStyle: const TextStyle(
              color: Color(0xFF58786C),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: Icon(
              hasError
                  ? Icons.error_outline_rounded
                  : Icons.email_outlined,
              color: hasError
                  ? const Color(0xFFC94F4F)
                  : const Color(0xFF396F5E),
              size: 28,
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 54,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 19,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(22),
              borderSide: const BorderSide(
                color: Color(0xFFDDE8E2),
                width: 1.1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(22),
              borderSide: BorderSide(
                color: hasError
                    ? const Color(0xFFE88787)
                    : const Color(0xFFDDE8E2),
                width: hasError ? 1.6 : 1.1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(22),
              borderSide: BorderSide(
                color: hasError
                    ? const Color(0xFFE88787)
                    : primary,
                width: 1.7,
              ),
            ),
          ),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: hasError
              ? Padding(
            key: ValueKey(emailError),
            padding: const EdgeInsets.only(
              left: 12,
              top: 7,
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: Color(0xFFC94F4F),
                  size: 15,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    emailError!,
                    style: const TextStyle(
                      color: Color(0xFFC94F4F),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildSendButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(17),
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Color(0xFF397763),
              Color(0xFF28604F),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: primaryDark.withOpacity(0.22),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: isLoading ? null : _sendRecoveryEmail,
          style: ElevatedButton.styleFrom(
            elevation: 0,
            shadowColor: Colors.transparent,
            backgroundColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            disabledForegroundColor: Colors.white70,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(17),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
            ),
          ),
          child: isLoading
              ? const SizedBox(
            width: 25,
            height: 25,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2.6,
            ),
          )
              : const Row(
            children: [
              Expanded(
                child: Text(
                  'Enviar enlace',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                Icons.send_rounded,
                size: 25,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReturnToLogin() {
    return Center(
      child: TextButton.icon(
        onPressed: isLoading
            ? null
            : () {
          Navigator.pop(context);
        },
        icon: const Icon(
          Icons.arrow_back_rounded,
          color: primary,
          size: 18,
        ),
        label: const Text(
          'Volver al inicio de sesión',
          style: TextStyle(
            color: primary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}