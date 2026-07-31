import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import './recuperarcontraseña_view.dart';
import '../../routes/app_routes.dart';
import '../../services/auth_service.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final AuthService _authService = AuthService();

  bool isLoading = false;
  bool rememberMe = true;
  bool obscurePassword = true;

  String? emailError;
  String? passwordError;

  static const Color primaryDark = Color(0xFF285F50);
  static const Color primary = Color(0xFF3E806B);
  static const Color primaryLight = Color(0xFF8EBEAC);
  static const Color background = Color(0xFFE8F3E8);
  static const Color textDark = Color(0xFF24463E);

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  bool _validateLoginFields() {
    final String email = emailController.text.trim();
    final String password = passwordController.text.trim();

    setState(() {
      emailError = null;
      passwordError = null;

      if (email.isEmpty) {
        emailError = 'Ingresa tu correo electrónico';
      } else if (!RegExp(
        r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,}$',
      ).hasMatch(email)) {
        emailError = 'Ingresa un correo electrónico válido';
      }

      if (password.isEmpty) {
        passwordError = 'Ingresa tu contraseña';
      } else if (password.length < 6) {
        passwordError =
        'La contraseña debe tener al menos 6 caracteres';
      }
    });

    return emailError == null && passwordError == null;
  }

  Future<void> _loginWithEmail() async {
    if (!_validateLoginFields()) {
      _showValidationMessage('Revisa los campos marcados.');
      return;
    }

    final String email = emailController.text.trim();
    final String password = passwordController.text.trim();

    try {
      setState(() {
        isLoading = true;
      });

      await _authService.loginWithEmail(
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
      final message = switch (error.code) {
        'user-not-found' => 'No existe una cuenta con este correo.',
        'wrong-password' || 'invalid-credential' =>
          'El correo o la contraseña son incorrectos.',
        'user-disabled' => 'Esta cuenta fue deshabilitada.',
        'too-many-requests' =>
          'Demasiados intentos. Espera unos minutos e inténtalo de nuevo.',
        _ => 'No pudimos iniciar sesión. Revisa tus datos.',
      };
      _showErrorMessage(message);
    } catch (e) {
      if (!mounted) return;
      _showErrorMessage('No pudimos iniciar sesión. Inténtalo nuevamente.');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _loginWithGoogle() async {
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
    } catch (e) {
      if (!mounted) return;

      _showErrorMessage(
        'No pudimos iniciar sesión con Google.',
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
                              'Bienvenido',
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
                            child: _buildLoginCardFixed(),
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

  Widget _buildLoginCardFixed() {
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
          const SizedBox(height: 8),

          _buildForgotPassword(),

          const SizedBox(height: 22),

          _buildLoginButton(),
          const SizedBox(height: 21),
          _buildSeparator(),
          const SizedBox(height: 18),
          _buildSocialButtons(),
          const SizedBox(height: 19),
          const Divider(
            color: Color(0xFFDCE3DE),
            thickness: 1,
            height: 1,
          ),
          const SizedBox(height: 15),
          _buildCreateAccount(),
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
          textInputAction: TextInputAction.next,
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
                  : Icons.person_outline_rounded,
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

  Widget _buildPasswordField() {
    final bool hasError = passwordError != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: passwordController,
          obscureText: obscurePassword,
          textInputAction: TextInputAction.done,
          autofillHints: const [
            AutofillHints.password,
          ],
          onChanged: (_) {
            if (passwordError != null) {
              setState(() {
                passwordError = null;
              });
            }
          },
          onSubmitted: (_) {
            if (!isLoading) {
              _loginWithEmail();
            }
          },
          style: const TextStyle(
            color: textDark,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          cursorColor: primary,
          decoration: InputDecoration(
            hintText: 'Contraseña',
            hintStyle: const TextStyle(
              color: Color(0xFF58786C),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: Icon(
              hasError
                  ? Icons.error_outline_rounded
                  : Icons.lock_outline_rounded,
              color: hasError
                  ? const Color(0xFFC94F4F)
                  : const Color(0xFF396F5E),
              size: 28,
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 54,
            ),
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
            key: ValueKey(passwordError),
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
                    passwordError!,
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

  Widget _buildForgotPassword() {
    return Center(
      child: TextButton.icon(
        onPressed: () {
          Navigator.pushNamed(
            context,
            AppRoutes.recuperarContrasena,
          );
        },
        icon: const Icon(
          Icons.lock_reset_rounded,
          color: primary,
          size: 18,
        ),
        label: const Text(
          '¿Olvidaste tu contraseña?',
          style: TextStyle(
            color: primary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
  Widget _buildLoginButton() {
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
          onPressed: isLoading ? null : _loginWithEmail,
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
                  'Iniciar sesión',
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

  Widget _buildSocialButtons() {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: _SocialButton(
        label: 'Continuar con Google',
        onPressed: isLoading ? null : _loginWithGoogle,
        icon: Image.asset(
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
      ),
    );
  }

  Widget _buildCreateAccount() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          '¿No tienes una cuenta?',
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
            Navigator.pushNamed(
              context,
              AppRoutes.register,
            );
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
                'Crear cuenta',
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

class _SocialButton extends StatelessWidget {
  final String label;
  final Widget icon;
  final VoidCallback? onPressed;

  const _SocialButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: OutlinedButton(
        onPressed: onPressed,
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
            icon,
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
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
}