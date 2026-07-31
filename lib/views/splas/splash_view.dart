import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Para cargar imagen con AssetImage

import '../auth/auth_wrapper.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView>
    with TickerProviderStateMixin {
  // Controladores principales
  late final AnimationController _entranceController;
  late final AnimationController _pulseController;
  late final AnimationController _waveController;
  late final AnimationController _progressController;
  late final AnimationController _backgroundController;
  late final AnimationController _particlesController;
  late final AnimationController _glowController;
  late final AnimationController _breathController;

  // Animaciones de entrada
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  late final Animation<Offset> _slide;
  late final Animation<double> _pulse;

  // Animación de ondas (3 capas)
  late final Animation<double> _wave1;
  late final Animation<double> _wave2;
  late final Animation<double> _wave3;

  // Progreso de carga
  late final Animation<double> _progress;

  // Partículas (posición y tamaño)
  late final List<_Particle> _particles;
  late final Animation<double> _particleOpacity;

  // Brillo del logo
  late final Animation<double> _glow;

  // Respiración global
  late final Animation<double> _breath;

  // Control para movimiento del fondo
  Timer? _backgroundTimer;
  double _bgOffsetX = 0.0;
  double _bgOffsetY = 0.0;

  Timer? _navigationTimer;

  // Colores mejorados con más variedad
  static const Color primaryColor = Color(0xFF2F6B5B);
  static const Color primaryDark = Color(0xFF173F36);
  static const Color primaryLight = Color(0xFFDDEFE7);
  static const Color accentColor = Color(0xFF4CAF8A);
  static const Color warmColor = Color(0xFFFF8A65);
  static const Color backgroundColor = Color(0xFFF4F8F6);

  @override
  void initState() {
    super.initState();

    // Inicializar partículas
    _particles = List.generate(25, (index) => _Particle.random());

    // --- Controladores ---
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );

    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _particlesController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);

    // --- Animaciones ---
    _fade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    );

    _scale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: Curves.elasticOut,
      ),
    );

    _slide = Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero)
        .animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _pulse = Tween<double>(begin: 0.96, end: 1.06).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    // 3 capas de ondas con diferentes retardos
    _wave1 = Tween<double>(begin: 0.7, end: 1.9).animate(
      CurvedAnimation(
        parent: _waveController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
      ),
    );

    _wave2 = Tween<double>(begin: 0.7, end: 2.0).animate(
      CurvedAnimation(
        parent: _waveController,
        curve: const Interval(0.15, 1.0, curve: Curves.easeOut),
      ),
    );

    _wave3 = Tween<double>(begin: 0.7, end: 2.1).animate(
      CurvedAnimation(
        parent: _waveController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    _progress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _progressController,
        curve: Curves.easeInOut,
      ),
    );

    _particleOpacity = Tween<double>(begin: 0.0, end: 0.6).animate(
      CurvedAnimation(
        parent: _particlesController,
        curve: Curves.easeInOut,
      ),
    );

    _glow = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _glowController,
        curve: Curves.easeInOut,
      ),
    );

    _breath = Tween<double>(begin: 0.99, end: 1.01).animate(
      CurvedAnimation(
        parent: _breathController,
        curve: Curves.easeInOut,
      ),
    );

    // Iniciar animaciones
    _entranceController.forward();
    _progressController.forward();

    // Movimiento del fondo (parallax)
    _backgroundTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _bgOffsetX = 16 * math.sin(_backgroundController.value * 2 * math.pi);
        _bgOffsetY = 12 * math.cos(_backgroundController.value * 2 * math.pi * 0.6);
      });
    });

    // Navegación
    _navigationTimer = Timer(
      const Duration(milliseconds: 3000),
      _goToNextScreen,
    );
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _backgroundTimer?.cancel();
    _entranceController.dispose();
    _pulseController.dispose();
    _waveController.dispose();
    _progressController.dispose();
    _backgroundController.dispose();
    _particlesController.dispose();
    _glowController.dispose();
    _breathController.dispose();
    super.dispose();
  }

  void _goToNextScreen() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 800),
        pageBuilder: (_, __, ___) =>  AuthWrapper(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 1.08, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOut),
              ),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // Fondo animado
          _buildAnimatedBackground(),

          // Capa de partículas
          _buildParticlesLayer(),

          // Capa de ondas (detrás del logo)
          _buildWaveLayer(),

          // Contenido principal
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: Column(
                children: [
                  const Spacer(flex: 2),

                  // Logo con animaciones múltiples
                  ScaleTransition(
                    scale: _scale,
                    child: FadeTransition(
                      opacity: _fade,
                      child: ScaleTransition(
                        scale: _pulse,
                        child: _buildLogoWithGlow(),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Texto con entrada escalonada mejorada
                  _buildStaggeredText(),

                  const Spacer(flex: 3),

                  // Barra de progreso mejorada
                  FadeTransition(
                    opacity: _fade,
                    child: _buildProgressBar(),
                  ),

                  const SizedBox(height: 24),

                  // Texto inferior con respiración
                  ScaleTransition(
                    scale: _breath,
                    child: FadeTransition(
                      opacity: _fade,
                      child: Text(
                        'Cuidando cada momento',
                        style: TextStyle(
                          color: primaryDark.withOpacity(0.58),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---- FONDO CON MOVIMIENTO Y DEGRADADO DINÁMICO ----
  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _backgroundController,
      builder: (context, child) {
        return Stack(
          children: [
            // Degradado de fondo con ángulo variable
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(
                      math.sin(_backgroundController.value * 2 * math.pi) * 0.3,
                      math.cos(_backgroundController.value * 2 * math.pi * 0.7) *
                          0.3,
                    ),
                    end: Alignment(
                      -math.sin(_backgroundController.value * 2 * math.pi) * 0.3,
                      -math.cos(_backgroundController.value * 2 * math.pi * 0.7) *
                          0.3,
                    ),
                    colors: const [
                      Color(0xFFE8F5E9),
                      Color(0xFFF4F8F6),
                      Colors.white,
                    ],
                    stops: const [0, 0.45, 1],
                  ),
                ),
                child: const SizedBox.expand(),
              ),
            ),

            // Círculos decorativos con movimiento parallax mejorado
            Transform.translate(
              offset: Offset(_bgOffsetX * 0.4, _bgOffsetY * 0.3),
              child: Positioned(
                top: -130,
                right: -95,
                child: Container(
                  width: 320,
                  height: 320,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        primaryColor.withOpacity(0.12),
                        primaryColor.withOpacity(0.02),
                      ],
                      stops: const [0, 1],
                    ),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),

            Transform.translate(
              offset: Offset(-_bgOffsetX * 0.6, _bgOffsetY * 0.5),
              child: Positioned(
                top: 130,
                left: -120,
                child: Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        warmColor.withOpacity(0.08),
                        Colors.transparent,
                      ],
                      stops: const [0, 1],
                    ),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),

            Transform.translate(
              offset: Offset(_bgOffsetX * 0.7, -_bgOffsetY * 0.4),
              child: Positioned(
                bottom: -150,
                right: -55,
                child: Container(
                  width: 340,
                  height: 340,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        primaryLight.withOpacity(0.7),
                        Colors.transparent,
                      ],
                      stops: const [0, 1],
                    ),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ---- CAPA DE PARTÍCULAS ----
  Widget _buildParticlesLayer() {
    return AnimatedBuilder(
      animation: _particlesController,
      builder: (context, child) {
        return CustomPaint(
          painter: _ParticlesPainter(
            particles: _particles,
            progress: _particlesController.value,
            opacity: _particleOpacity.value,
            primaryColor: primaryColor,
            accentColor: accentColor,
          ),
          size: Size.infinite,
        );
      },
    );
  }

  // ---- CAPA DE ONDAS EXPANSIVAS (3 capas) ----
  Widget _buildWaveLayer() {
    return Center(
      child: AnimatedBuilder(
        animation: _waveController,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Onda 1
              _buildWave(
                scale: _wave1.value,
                color: primaryColor.withOpacity(0.08),
                borderColor: primaryColor.withOpacity(0.15),
                size: 160,
              ),
              // Onda 2
              _buildWave(
                scale: _wave2.value,
                color: accentColor.withOpacity(0.06),
                borderColor: accentColor.withOpacity(0.12),
                size: 170,
              ),
              // Onda 3
              _buildWave(
                scale: _wave3.value,
                color: warmColor.withOpacity(0.05),
                borderColor: warmColor.withOpacity(0.10),
                size: 180,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildWave({
    required double scale,
    required Color color,
    required Color borderColor,
    required double size,
  }) {
    final double diameter = size * scale;
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(
          color: borderColor,
          width: 1.5,
        ),
      ),
    );
  }

  // ---- LOGO CON RESPLANDOR Y ANIMACIÓN ----
  Widget _buildLogoWithGlow() {
    return AnimatedBuilder(
      animation: _glow,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Resplandor exterior (glow)
            Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primaryColor.withOpacity(0.08 * _glow.value),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.35 * _glow.value),
                    blurRadius: 50,
                    spreadRadius: 15,
                  ),
                ],
              ),
            ),
            // Logo circular con tu imagen
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.95),
                    Colors.white.withOpacity(0.85),
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withOpacity(0.9),
                  width: 4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.25),
                    blurRadius: 30,
                    spreadRadius: 5,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/logo2.png',
                  width: 150,
                  height: 150,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback en caso de que no encuentre la imagen
                    return Container(
                      color: primaryColor,
                      child: const Icon(
                        Icons.medical_services,
                        size: 80,
                        color: Colors.white,
                      ),
                    );
                  },
                ),
              ),
            ),
            // Sutil anillo giratorio alrededor del logo (opcional)
            RotationTransition(
              turns: _backgroundController,
              child: Container(
                width: 165,
                height: 165,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: primaryColor.withOpacity(0.15),
                    width: 1.5,
                    strokeAlign: BorderSide.strokeAlignOutside,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ---- TEXTO CON ENTRADA ESCALONADA MEJORADA ----
  Widget _buildStaggeredText() {
    return Column(
      children: [
        // Título "VitaCare AI"
        SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.3),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(
              parent: _entranceController,
              curve: const Interval(0.2, 0.6, curve: Curves.easeOutCubic),
            ),
          ),
          child: FadeTransition(
            opacity: CurvedAnimation(
              parent: _entranceController,
              curve: const Interval(0.2, 0.6, curve: Curves.easeOut),
            ),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                CurvedAnimation(
                  parent: _entranceController,
                  curve: const Interval(0.2, 0.6, curve: Curves.easeOut),
                ),
              ),
              child: const Text(
                'VitaCare AI',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: primaryDark,
                  fontSize: 40,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.5,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Subtítulo "Tecnología que cuida de ti"
        SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.3),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(
              parent: _entranceController,
              curve: const Interval(0.35, 0.75, curve: Curves.easeOutCubic),
            ),
          ),
          child: FadeTransition(
            opacity: CurvedAnimation(
              parent: _entranceController,
              curve: const Interval(0.35, 0.75, curve: Curves.easeOut),
            ),
            child: const Text(
              'Tecnología que cuida de ti',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: primaryColor,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Descripción
        SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.3),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(
              parent: _entranceController,
              curve: const Interval(0.5, 0.9, curve: Curves.easeOutCubic),
            ),
          ),
          child: FadeTransition(
            opacity: CurvedAnimation(
              parent: _entranceController,
              curve: const Interval(0.5, 0.9, curve: Curves.easeOut),
            ),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 18),
              child: Text(
                'Tu salud, tus medicamentos y tus seres queridos en un solo lugar.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF66756F),
                  fontSize: 14,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ---- BARRA DE PROGRESO CON DEGRADADO ANIMADO ----
  Widget _buildProgressBar() {
    return AnimatedBuilder(
      animation: _progress,
      builder: (context, child) {
        return Column(
          children: [
            SizedBox(
              width: 140,
              child: ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(20)),
                child: LinearProgressIndicator(
                  minHeight: 6,
                  value: _progress.value,
                  backgroundColor: primaryLight,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Color.lerp(primaryColor, accentColor, _progress.value)!,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Preparando tu experiencia... ${(_progress.value * 100).toInt()}%',
              style: const TextStyle(
                color: Color(0xFF66756F),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );
      },
    );
  }
}

// ---- CLASE PARA PARTÍCULAS ----
class _Particle {
  final double x;
  final double y;
  final double size;
  final double speed;
  final double amplitude;
  final Color color;

  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.amplitude,
    required this.color,
  });

  factory _Particle.random() {
    final random = math.Random();
    return _Particle(
      x: random.nextDouble() * 2 - 1, // -1 a 1
      y: random.nextDouble() * 2 - 1,
      size: 2 + random.nextDouble() * 6,
      speed: 0.5 + random.nextDouble() * 1.5,
      amplitude: 0.01 + random.nextDouble() * 0.03,
      color: (random.nextBool()
          ? _SplashViewState.primaryColor
          : _SplashViewState.accentColor)
          .withOpacity(0.3 + random.nextDouble() * 0.4),
    );
  }
}

// ---- PAINTER DE PARTÍCULAS ----
class _ParticlesPainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;
  final double opacity;
  final Color primaryColor;
  final Color accentColor;

  _ParticlesPainter({
    required this.particles,
    required this.progress,
    required this.opacity,
    required this.primaryColor,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (final particle in particles) {
      final dx = (particle.x + math.sin(progress * particle.speed * 2 * math.pi) *
          particle.amplitude * 0.1) *
          size.width /
          2;
      final dy = (particle.y + math.cos(progress * particle.speed * 1.7 * 2 * math.pi) *
          particle.amplitude * 0.1) *
          size.height /
          2;

      final center = Offset(size.width / 2 + dx, size.height / 2 + dy);
      paint.color = particle.color.withOpacity(opacity * particle.color.opacity);

      canvas.drawCircle(center, particle.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlesPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.opacity != opacity;
  }
}