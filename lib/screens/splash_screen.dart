import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'home_screen.dart';
import 'onboarding_screen.dart';

// ─── Brand colours ───────────────────────────────────────────────────────────
const _kDeepNavy   = Color(0xFF050E1F);
const _kNavy       = Color(0xFF0A1628);
const _kBrightBlue = Color(0xFF2563EB);
const _kAccentBlue = Color(0xFF3B82F6);
const _kLightBlue  = Color(0xFF93C5FD);
const _kPaleBlue   = Color(0xFFBFDBFE);

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Controllers
  late final AnimationController _logoCtrl;
  late final AnimationController _contentCtrl;
  late final AnimationController _pulseCtrl;
  late final AnimationController _dotsCtrl;

  // Logo animations
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _logoGlow;

  // Content animations
  late final Animation<double> _contentOpacity;
  late final Animation<Offset> _nameSlide;
  late final Animation<double> _taglineOpacity;
  late final Animation<double> _bottomOpacity;

  @override
  void initState() {
    super.initState();

    _logoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _contentCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _dotsCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _logoScale = CurvedAnimation(
      parent: _logoCtrl,
      curve: Curves.elasticOut,
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoCtrl,
        curve: const Interval(0.0, 0.5),
      ),
    );
    _logoGlow = Tween<double>(begin: 0.35, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    _contentOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentCtrl,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
      ),
    );
    _nameSlide = Tween<Offset>(
      begin: const Offset(0, 0.45),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _contentCtrl,
      curve: const Interval(0.0, 0.75, curve: Curves.easeOutCubic),
    ));
    _taglineOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentCtrl,
        curve: const Interval(0.35, 1.0, curve: Curves.easeIn),
      ),
    );
    _bottomOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentCtrl,
        curve: const Interval(0.55, 1.0, curve: Curves.easeIn),
      ),
    );

    _runSequence();
  }

  Future<void> _runSequence() async {
    await Future.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;
    _logoCtrl.forward();

    await Future.delayed(const Duration(milliseconds: 550));
    if (!mounted) return;
    _contentCtrl.forward();

    await Future.delayed(const Duration(milliseconds: 2400));
    if (!mounted) return;
    _navigateToHome();
  }

  void _navigateToHome() {
    final user = FirebaseAuth.instance.currentUser;
    final destination = user != null
        ? const HomeScreen()
        : const OnboardingScreen();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => destination,
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: animation,
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _contentCtrl.dispose();
    _pulseCtrl.dispose();
    _dotsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kDeepNavy,
      body: Stack(
        children: [
          // ── Gradient background ──────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_kNavy, _kDeepNavy, Color(0xFF040A14)],
                stops: [0.0, 0.55, 1.0],
              ),
            ),
          ),

          // ── Decorative background shapes ─────────────────────────────────
          CustomPaint(
            painter: _BackgroundPainter(),
            child: const SizedBox.expand(),
          ),

          // ── Center group: logo + name + tagline ──────────────────────────
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Logo
                AnimatedBuilder(
                  animation: Listenable.merge([_logoCtrl, _pulseCtrl]),
                  builder: (context, child) => Opacity(
                    opacity: _logoOpacity.value,
                    child: Transform.scale(
                      scale: _logoScale.value,
                      child: _ClassoraLogo(glowIntensity: _logoGlow.value),
                    ),
                  ),
                ),

                const SizedBox(height: 48),

                // App name + tagline
                SlideTransition(
                  position: _nameSlide,
                  child: FadeTransition(
                    opacity: _contentOpacity,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // "Classora" with gradient text
                        ShaderMask(
                          shaderCallback: (bounds) =>
                              const LinearGradient(
                            colors: [Colors.white, _kPaleBlue],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ).createShader(bounds),
                          child: const Text(
                            'Classora',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 46,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 5.0,
                              height: 1.0,
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Hairline divider with gradient
                        FadeTransition(
                          opacity: _taglineOpacity,
                          child: Container(
                            width: 180,
                            height: 1.0,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  _kAccentBlue.withOpacity(0.85),
                                  Colors.transparent,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Tagline
                        FadeTransition(
                          opacity: _taglineOpacity,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 40),
                            child: const Text(
                              'Smart Coaching Management System',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _kLightBlue,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w300,
                                letterSpacing: 0.8,
                                height: 1.55,
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
          ),

          // ── Bottom — loading dots + version (pinned) ──────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 52,
            child: FadeTransition(
              opacity: _bottomOpacity,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _AnimatedDots(controller: _dotsCtrl),
                  const SizedBox(height: 18),
                  Text(
                    'VERSION  1.0.0',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _kLightBlue.withOpacity(0.28),
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 2.5,
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
}

// ─── Logo widget ──────────────────────────────────────────────────────────────

class _ClassoraLogo extends StatelessWidget {
  final double glowIntensity;

  const _ClassoraLogo({this.glowIntensity = 1.0});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2563EB), Color(0xFF0C3484)],
        ),
        boxShadow: [
          BoxShadow(
            color: _kBrightBlue.withOpacity(0.55 * glowIntensity),
            blurRadius: 32,
            spreadRadius: 4,
          ),
          BoxShadow(
            color: _kAccentBlue.withOpacity(0.25 * glowIntensity),
            blurRadius: 72,
            spreadRadius: 14,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Subtle inner ring
          Container(
            width: 118,
            height: 118,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.12),
                width: 1.0,
              ),
            ),
          ),
          // Custom logo painter
          CustomPaint(
            size: const Size(84, 84),
            painter: _GradCapPainter(),
          ),
        ],
      ),
    );
  }
}

// ─── Graduation-cap + "C" painter ────────────────────────────────────────────

class _GradCapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    // ── Board (diamond / mortarboard top) ───────────────────────────────────
    final boardCY = h * 0.36;
    final bHW    = w * 0.44;   // board half-width
    final bHH    = h * 0.13;   // board half-height

    final boardPath = Path()
      ..moveTo(cx,        boardCY - bHH)   // top
      ..lineTo(cx + bHW,  boardCY)          // right
      ..lineTo(cx,        boardCY + bHH)   // bottom
      ..lineTo(cx - bHW,  boardCY)          // left
      ..close();

    canvas.drawPath(boardPath, Paint()..color = Colors.white);

    // Highlight on upper half of board
    final highlightPath = Path()
      ..moveTo(cx, boardCY - bHH)
      ..lineTo(cx + bHW, boardCY)
      ..lineTo(cx, boardCY)
      ..lineTo(cx - bHW, boardCY)
      ..close();

    canvas.drawPath(
      highlightPath,
      Paint()..color = Colors.white.withOpacity(0.22),
    );

    // Top button / knob
    canvas.drawCircle(
      Offset(cx, boardCY - bHH - 5),
      3.5,
      Paint()..color = _kPaleBlue,
    );

    // ── Cap body (trapezoid hanging down) ────────────────────────────────────
    final sidesTop    = boardCY + bHH * 0.45;
    final sidesBottom = boardCY + h * 0.38;
    final sHW         = bHW * 0.52;

    final sidesPath = Path()
      ..moveTo(cx - sHW, sidesTop)
      ..lineTo(cx + sHW, sidesTop)
      ..lineTo(cx + sHW * 0.78, sidesBottom)
      ..quadraticBezierTo(cx, sidesBottom + h * 0.07, cx - sHW * 0.78, sidesBottom)
      ..close();

    canvas.drawPath(
      sidesPath,
      Paint()..color = Colors.white.withOpacity(0.88),
    );

    // ── Tassel ───────────────────────────────────────────────────────────────
    final tasselX = cx + bHW;
    final tasselY0 = boardCY;
    final tasselY1 = boardCY + h * 0.30;

    final tasselLinePaint = Paint()
      ..color = _kPaleBlue
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(tasselX, tasselY0),
      Offset(tasselX, tasselY1),
      tasselLinePaint,
    );

    // Tassel end tuft (two short crossed lines)
    final tufPaint = Paint()
      ..color = _kPaleBlue
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(tasselX - 5, tasselY1),
      Offset(tasselX + 3, tasselY1 + 7),
      tufPaint,
    );
    canvas.drawLine(
      Offset(tasselX + 3, tasselY1),
      Offset(tasselX - 5, tasselY1 + 7),
      tufPaint,
    );

    // ── Sparkle dots (academic / digital accent) ─────────────────────────────
    final sparklePaint = Paint()
      ..color = _kPaleBlue.withOpacity(0.7);

    for (final pos in [
      Offset(cx - bHW * 0.85, boardCY - bHH * 1.9),
      Offset(cx + bHW * 0.75, boardCY - bHH * 2.2),
      Offset(cx - bHW * 0.55, boardCY + h * 0.58),
    ]) {
      canvas.drawCircle(pos, 2.0, sparklePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Background abstract painter ─────────────────────────────────────────────

class _BackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final W = size.width;
    final H = size.height;

    final circlePaint = Paint();

    // ── Symmetric large corner circles ───────────────────────────────────────
    // Top-left
    canvas.drawCircle(
      Offset(W * 0.10, H * 0.06),
      W * 0.42,
      circlePaint..color = const Color(0xFF1A3A6B).withOpacity(0.32),
    );
    // Top-right (mirror)
    canvas.drawCircle(
      Offset(W * 0.90, H * 0.06),
      W * 0.42,
      circlePaint..color = const Color(0xFF1A3A6B).withOpacity(0.32),
    );
    // Bottom-left
    canvas.drawCircle(
      Offset(W * 0.10, H * 0.94),
      W * 0.44,
      circlePaint..color = const Color(0xFF1A3A6B).withOpacity(0.24),
    );
    // Bottom-right (mirror)
    canvas.drawCircle(
      Offset(W * 0.90, H * 0.94),
      W * 0.44,
      circlePaint..color = const Color(0xFF1A3A6B).withOpacity(0.24),
    );

    // ── Small accent circles (symmetric mid sides) ────────────────────────────
    canvas.drawCircle(
      Offset(W * 0.08, H * 0.48),
      W * 0.16,
      circlePaint..color = const Color(0xFF2563EB).withOpacity(0.065),
    );
    canvas.drawCircle(
      Offset(W * 0.92, H * 0.48),
      W * 0.16,
      circlePaint..color = const Color(0xFF2563EB).withOpacity(0.065),
    );

    // ── Center soft glow ──────────────────────────────────────────────────────
    canvas.drawCircle(
      Offset(W * 0.50, H * 0.42),
      W * 0.55,
      circlePaint..color = const Color(0xFF1E40AF).withOpacity(0.06),
    );

    // ── Dot grid (full, symmetric by nature) ─────────────────────────────────
    final dotPaint = Paint()
      ..color = const Color(0xFF3B82F6).withOpacity(0.10)
      ..style = PaintingStyle.fill;

    const spacing = 36.0;
    for (double x = spacing / 2; x < W; x += spacing) {
      for (double y = spacing / 2; y < H; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.3, dotPaint);
      }
    }

    // ── Concentric arcs — top-left AND top-right (mirrored) ──────────────────
    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.75
      ..color = const Color(0xFF2563EB).withOpacity(0.16);

    for (int i = 1; i <= 3; i++) {
      final r = W * (0.30 + i * 0.11);
      final rect = (center) => Rect.fromCenter(
            center: center,
            width: r * 2,
            height: r * 2,
          );
      // top-left arc
      canvas.drawArc(
        rect(Offset(W * 0.10, H * 0.06)),
        math.pi * 0.10,
        math.pi * 0.55,
        false,
        arcPaint,
      );
      // top-right arc (mirror)
      canvas.drawArc(
        rect(Offset(W * 0.90, H * 0.06)),
        math.pi * 0.35,
        math.pi * 0.55,
        false,
        arcPaint,
      );
    }

    // ── Diagonal accent lines — bottom-left AND bottom-right (mirrored) ───────
    final linePaint = Paint()
      ..color = const Color(0xFF3B82F6).withOpacity(0.10)
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;

    // bottom-left lines
    canvas.drawLine(Offset(0, H * 0.74), Offset(W * 0.30, H * 0.97), linePaint);
    canvas.drawLine(Offset(0, H * 0.80), Offset(W * 0.22, H * 0.97), linePaint);

    // bottom-right lines (mirrored)
    canvas.drawLine(Offset(W, H * 0.74), Offset(W * 0.70, H * 0.97), linePaint);
    canvas.drawLine(Offset(W, H * 0.80), Offset(W * 0.78, H * 0.97), linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Animated loading dots ────────────────────────────────────────────────────

class _AnimatedDots extends StatelessWidget {
  final AnimationController controller;

  const _AnimatedDots({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final t = ((controller.value - i / 3) % 1.0).clamp(0.0, 1.0);
            final opacity = math.sin(t * math.pi).clamp(0.0, 1.0);
            return Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _kAccentBlue.withOpacity(0.25 + opacity * 0.75),
              ),
            );
          }),
        );
      },
    );
  }
}
