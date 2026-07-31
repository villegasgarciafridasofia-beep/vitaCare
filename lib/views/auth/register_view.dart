import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../routes/app_routes.dart';
import '../../services/auth_service.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final AuthService _authService = AuthService();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
  TextEditingController();

  bool isLoading = false;
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;

  String? emailError;
  String? passwordError;
  String? confirmPasswordError;

  static const Color primaryDark = Color(0xFF285F50);
  static const Color primary = Color(0xFF3E806B);
  static const Color background = Color(0xFFE8F3E8);
  static const Color textDark = Color(0xFF24463E);

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  bool _validateRegisterFields() {
    final String email = emailController.text.trim();
    final String password = passwordController.text.trim();
    final String confirmPassword = confirmPasswordController.text.trim();

    setState(() {
      emailError = null;
      passwordError = null;
      confirmPasswordError = null;

      if (email.isEmpty) {
        emailError = 'Ingresa tu correo electrónico';
      } else if (!RegExp(
        r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,}$',
      ).hasMatch(email)) {
        emailError = 'Ingresa un correo electrónico válido';
      }

      if (password.isEmpty) {
        passwordError = 'Ingresa una contraseña';
      } else if (password.length < 6) {
        passwordError =
        'La contraseña debe tener al menos 6 caracteres';
      }

      if (confirmPassword.isEmpty) {
        confirmPasswordError = 'Confirma tu contraseña';
      } else if (password != confirmPassword) {
        confirmPasswordError = 'Las contraseñas no coinciden';
      }
    });

    return emailError == null &&
        passwordError == null &&
        confirmPasswordError == null;
  }

  Future<void> _registerWithEmail() async {
    if (!_validateRegisterFields()) {
      _showValidationMessage('Revisa los campos marcados.');
      return;
    }

    final String email = emailController.text.trim();
    final String password = passwordController.text.trim();

    try {
      setState(() {
        isLoading = true;
      });

      await _authService.registerWithEmail(
        email: email,
        password: password,
      );

      if (!mounted) return;

      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.auth,
        (route) => false,
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;

      final String message = switch (error.code) {
        'email-already-in-use' =>
          'Este correo ya está registrado. Inicia sesión o recupera tu contraseña.',
        'invalid-email' => 'El correo electrónico no es válido.',
        'weak-password' =>
          'La contraseña es muy débil. Usa al menos 6 caracteres.',
        'operation-not-allowed' =>
          'El registro con correo no está habilitado.',
        _ => 'No pudimos crear la cuenta. Inténtalo nuevamente.',
      };

      setState(() {
        if (error.code == 'email-already-in-use' ||
            error.code == 'invalid-email') {
          emailError = message;
        }
      });
      _showErrorMessage(message);
    } catch (error) {
      if (!mounted) return;
      _showErrorMessage('No pudimos crear la cuenta. Inténtalo nuevamente.');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _registerWithGoogle() async {
    try {
      setState(() {
        isLoading = true;
      });

      await _authService.loginWithGoogle();

      if (!mounted) return;

      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.auth,
        (route) => false,
      );
    } catch (error) {
      if (!mounted) return;

      _showErrorMessage(
        'No pudimos continuar con Google.',
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
                          const Positioned(
                            top: 205,
                            left: 0,
                            right: 0,
                            child: Text(
                              'Crear cuenta',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: textDark,
                                fontSize: 31,
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
                            child: _buildRegisterCardFixed(),
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

  Widget _buildRegisterCardFixed() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
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
          _buildEmailField(),
          const SizedBox(height: 14),
          _buildPasswordField(),
          const SizedBox(height: 14),
          _buildConfirmPasswordField(),
          const SizedBox(height: 22),
          _buildRegisterButton(),
          const SizedBox(height: 21),
          _buildSeparator(),
          const SizedBox(height: 18),
          _buildGoogleButton(),
          const SizedBox(height: 19),
          const Divider(
            color: Color(0xFFDCE3DE),
            thickness: 1,
            height: 1,
          ),
          const SizedBox(height: 15),
          _buildLoginLink(),
        ],
      ),
    );
  }

  Widget _buildEmailField() {
    final bool hasError = emailError != null;

    return _buildFieldWithError(
      hasError: hasError,
      errorMessage: emailError,
      child: TextField(
        controller: emailController,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.next,
        autofillHints: const [
          AutofillHints.email,
          AutofillHints.newUsername,
        ],
        onChanged: (_) {
          if (emailError != null) {
            setState(() {
              emailError = null;
            });
          }
        },
        style: const TextStyle(
          color: textDark,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        cursorColor: primary,
        decoration: _fieldDecoration(
          hintText: 'Correo electrónico',
          icon: hasError
              ? Icons.error_outline_rounded
              : Icons.email_outlined,
          hasError: hasError,
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    final bool hasError = passwordError != null;

    return _buildFieldWithError(
      hasError: hasError,
      errorMessage: passwordError,
      child: TextField(
        controller: passwordController,
        obscureText: obscurePassword,
        textInputAction: TextInputAction.next,
        autofillHints: const [
          AutofillHints.newPassword,
        ],
        onChanged: (_) {
          if (passwordError != null) {
            setState(() {
              passwordError = null;
            });
          }

          if (confirmPasswordError != null &&
              confirmPasswordController.text.isNotEmpty) {
            setState(() {
              confirmPasswordError = null;
            });
          }
        },
        style: const TextStyle(
          color: textDark,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        cursorColor: primary,
        decoration: _fieldDecoration(
          hintText: 'Contraseña',
          icon: hasError
              ? Icons.error_outline_rounded
              : Icons.lock_outline_rounded,
          hasError: hasError,
          suffixIcon: IconButton(
            tooltip: obscurePassword
                ? 'Mostrar contraseña'
                : 'Ocultar contraseña',
            onPressed: () {
              setState(() {
                obscurePassword = !obscurePassword;
              });
            },
            icon: Icon(
              obscurePassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: hasError
                  ? const Color(0xFFC94F4F)
                  : const Color(0xFF4E8A75),
              size: 27,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmPasswordField() {
    final bool hasError = confirmPasswordError != null;

    return _buildFieldWithError(
      hasError: hasError,
      errorMessage: confirmPasswordError,
      child: TextField(
        controller: confirmPasswordController,
        obscureText: obscureConfirmPassword,
        textInputAction: TextInputAction.done,
        autofillHints: const [
          AutofillHints.newPassword,
        ],
        onChanged: (_) {
          if (confirmPasswordError != null) {
            setState(() {
              confirmPasswordError = null;
            });
          }
        },
        onSubmitted: (_) {
          if (!isLoading) {
            _registerWithEmail();
          }
        },
        style: const TextStyle(
          color: textDark,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        cursorColor: primary,
        decoration: _fieldDecoration(
          hintText: 'Confirmar contraseña',
          icon: hasError
              ? Icons.error_outline_rounded
              : Icons.lock_reset_rounded,
          hasError: hasError,
          suffixIcon: IconButton(
            tooltip: obscureConfirmPassword
                ? 'Mostrar contraseña'
                : 'Ocultar contraseña',
            onPressed: () {
              setState(() {
                obscureConfirmPassword = !obscureConfirmPassword;
              });
            },
            icon: Icon(
              obscureConfirmPassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: hasError
                  ? const Color(0xFFC94F4F)
                  : const Color(0xFF4E8A75),
              size: 27,
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration({
    required String hintText,
    required IconData icon,
    required bool hasError,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(
        color: Color(0xFF58786C),
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      prefixIcon: Icon(
        icon,
        color: hasError
            ? const Color(0xFFC94F4F)
            : const Color(0xFF396F5E),
        size: 28,
      ),
      prefixIconConstraints: const BoxConstraints(
        minWidth: 54,
      ),
      suffixIcon: suffixIcon,
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
    );
  }

  Widget _buildFieldWithError({
    required bool hasError,
    required String? errorMessage,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        child,
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: hasError
              ? Padding(
            key: ValueKey(errorMessage),
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
                    errorMessage!,
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

  Widget _buildRegisterButton() {
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
          onPressed: isLoading ? null : _registerWithEmail,
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
                  'Crear cuenta',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_rounded,
                size: 29,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeparator() {
    return const Row(
      children: [
        Expanded(
          child: Divider(
            color: Color(0xFFDCE3DE),
            thickness: 1,
            height: 1,
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 13,
          ),
          child: Text(
            'o continúa con',
            style: TextStyle(
              color: Color(0xFF64756E),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: Color(0xFFDCE3DE),
            thickness: 1,
            height: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildGoogleButton() {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: OutlinedButton(
        onPressed: isLoading ? null : _registerWithGoogle,
        style: OutlinedButton.styleFrom(
          backgroundColor: const Color(0xFFFDFEFC),
          foregroundColor: const Color(0xFF1D2421),
          disabledForegroundColor:
          const Color(0xFF1D2421).withOpacity(0.45),
          side: const BorderSide(
            color: Color(0xFFE4E9E5),
          ),
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/google_logo.png',
              width: 26,
              height: 26,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) {
                return const Text(
                  'G',
                  style: TextStyle(
                    color: Color(0xFF4285F4),
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                  ),
                );
              },
            ),
            const SizedBox(width: 10),
            const Flexible(
              child: Text(
                'Continuar con Google',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Color(0xFF1D2421),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          '¿Ya tienes una cuenta?',
          style: TextStyle(
            color: Color(0xFF64756E),
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(width: 4),
        TextButton(
          onPressed: isLoading
              ? null
              : () {
            Navigator.pop(context);
          },
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(
              horizontal: 4,
              vertical: 2,
            ),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Iniciar sesión',
                style: TextStyle(
                  color: primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(width: 1),
              Icon(
                Icons.chevron_right_rounded,
                size: 21,
                color: primary,
              ),
            ],
          ),
        ),
      ],
    );
  }
}