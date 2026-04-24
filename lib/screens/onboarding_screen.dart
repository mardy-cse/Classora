import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'home_screen.dart';

// ─── Brand palette ────────────────────────────────────────────────────────────
const _kPrimary   = Color(0xFF2563EB);
const _kAccent    = Color(0xFF3B82F6);
const _kLightBlue = Color(0xFF93C5FD);
const _kPaleBlue  = Color(0xFFBFDBFE);
const _kBg        = Color(0xFFF4F8FF);
const _kTextDark  = Color(0xFF0F172A);
const _kTextMuted = Color(0xFF64748B);
const _kGreen     = Color(0xFF10B981);
const _kAmber     = Color(0xFFF59E0B);
const _kRed       = Color(0xFFEF4444);

// ─── Onboarding page data ─────────────────────────────────────────────────────
class _PageData {
  final String title;
  final String desc;
  const _PageData(this.title, this.desc);
}

const _kPages = [
  _PageData(
    'Manage Coaching\nEasily',
    'Organise students, track attendance,\nand manage records in one place.',
  ),
  _PageData(
    'Track Payments\nSmartly',
    'Monitor fees, transactions, and\npayment history with ease.',
  ),
  _PageData(
    'Get Real-Time\nReports',
    'Analyse performance, attendance charts,\nand actionable insights instantly.',
  ),
];

// ─── Main screen ──────────────────────────────────────────────────────────────
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final _pageCtrl = PageController();
  int _page = 0;
  static const int _kTotal = 4; // 3 onboarding + 1 welcome

  late final AnimationController _anim;
  late final Animation<double>  _fade;
  late final Animation<Offset>  _slide;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.14),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic));
    _anim.forward();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _anim.dispose();
    super.dispose();
  }

  void _onPageChanged(int p) {
    setState(() => _page = p);
    _anim.forward(from: 0);
  }

  void _next() {
    if (_page < _kTotal - 1) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _goHome() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, a, __) => const HomeScreen(),
        transitionsBuilder: (_, a, __, child) =>
            FadeTransition(opacity: a, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final safeTop    = MediaQuery.of(context).padding.top;
    final safeBottom = MediaQuery.of(context).padding.bottom;
    final isWelcome  = _page == 3;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Color(0xFFF4F8FF),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: _kBg,
        body: Stack(
          children: [
            // ── Background blobs ──────────────────────────────────────────
            Positioned(
              top: -110, right: -90,
              child: _Blob(280, _kPrimary.withOpacity(0.07)),
            ),
            Positioned(
              bottom: -130, left: -70,
              child: _Blob(320, _kAccent.withOpacity(0.055)),
            ),
            Positioned(
              top: 220, left: -50,
              child: _Blob(170, _kLightBlue.withOpacity(0.09)),
            ),

            // ── Page content ──────────────────────────────────────────────
            PageView(
              controller: _pageCtrl,
              onPageChanged: _onPageChanged,
              physics: const BouncingScrollPhysics(),
              children: [
                _OnboardPage(
                  data: _kPages[0],
                  illustration: const _ManageIllustration(),
                  fade: _fade,
                  slide: _slide,
                ),
                _OnboardPage(
                  data: _kPages[1],
                  illustration: const _PaymentIllustration(),
                  fade: _fade,
                  slide: _slide,
                ),
                _OnboardPage(
                  data: _kPages[2],
                  illustration: const _ReportsIllustration(),
                  fade: _fade,
                  slide: _slide,
                ),
                _WelcomePage(
                  fade: _fade,
                  slide: _slide,
                  onGetStarted: _goHome,
                ),
              ],
            ),

            // ── Skip button ───────────────────────────────────────────────
            if (!isWelcome)
              Positioned(
                top: safeTop + 14,
                right: 20,
                child: GestureDetector(
                  onTap: _goHome,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.88),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Text(
                      'Skip',
                      style: TextStyle(
                        color: _kTextMuted,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
              ),

            // ── Dots + Next button ────────────────────────────────────────
            if (!isWelcome)
              Positioned(
                left: 0,
                right: 0,
                bottom: safeBottom + 32,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _NextBtn(onTap: _next),
                    const SizedBox(height: 20),
                    _DotsRow(total: _kTotal, current: _page),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Background blob ──────────────────────────────────────────────────────────
class _Blob extends StatelessWidget {
  final double size;
  final Color color;
  const _Blob(this.size, this.color);

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      );
}

// ─── Dots indicator ───────────────────────────────────────────────────────────
class _DotsRow extends StatelessWidget {
  final int total, current;
  const _DotsRow({required this.total, required this.current});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(total, (i) {
          final active = i == current;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            margin: const EdgeInsets.only(right: 6),
            width: active ? 24 : 7,
            height: 7,
            decoration: BoxDecoration(
              color: active ? _kPrimary : _kPaleBlue,
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }),
      );
}

// ─── Next button ──────────────────────────────────────────────────────────────
class _NextBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _NextBtn({required this.onTap});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: _kPrimary,
              foregroundColor: Colors.white,
              elevation: 0,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Next',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

// ─── Onboarding page layout ───────────────────────────────────────────────────
class _OnboardPage extends StatelessWidget {
  final _PageData data;
  final Widget illustration;
  final Animation<double> fade;
  final Animation<Offset> slide;

  const _OnboardPage({
    required this.data,
    required this.illustration,
    required this.fade,
    required this.slide,
  });

  @override
  Widget build(BuildContext context) {
    final safeTop    = MediaQuery.of(context).padding.top;
    final safeBottom = MediaQuery.of(context).padding.bottom;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Space below skip button
        SizedBox(height: safeTop + 72),

        // Illustration
        Expanded(
          flex: 5,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: illustration,
          ),
        ),

        const SizedBox(height: 28),

        // Text content
        FadeTransition(
          opacity: fade,
          child: SlideTransition(
            position: slide,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Accent bar
                  Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: _kPrimary,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    data.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: _kTextDark,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    data.desc,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: _kTextMuted,
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      height: 1.65,
                      letterSpacing: 0.05,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Space for dots / nav bar
        SizedBox(height: safeBottom + 172),
      ],
    );
  }
}

// ─── Welcome page ─────────────────────────────────────────────────────────────
class _WelcomePage extends StatelessWidget {
  final Animation<double> fade;
  final Animation<Offset> slide;
  final VoidCallback onGetStarted;

  const _WelcomePage({
    required this.fade,
    required this.slide,
    required this.onGetStarted,
  });

  @override
  Widget build(BuildContext context) {
    final safeTop    = MediaQuery.of(context).padding.top;
    final safeBottom = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.only(top: safeTop, bottom: safeBottom + 40),
      child: Column(
        children: [
          const Spacer(flex: 2),

          // Logo illustration
          FadeTransition(
            opacity: fade,
            child: const _WelcomeIllustration(),
          ),

          const Spacer(flex: 2),

          // Headline + subtitle
          FadeTransition(
            opacity: fade,
            child: SlideTransition(
              position: slide,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    ShaderMask(
                      shaderCallback: (b) => const LinearGradient(
                        colors: [_kPrimary, _kAccent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(b),
                      child: const Text(
                        'Classora',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 46,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 3.0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Your smart coaching\nmanagement companion',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _kTextMuted,
                        fontSize: 16,
                        height: 1.65,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const Spacer(flex: 3),

          // Get Started CTA
          FadeTransition(
            opacity: fade,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: onGetStarted,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Get Started',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 28),

          // Dots
          _DotsRow(total: 4, current: 3),
        ],
      ),
    );
  }
}

// ─── Welcome logo illustration ────────────────────────────────────────────────
class _WelcomeIllustration extends StatelessWidget {
  const _WelcomeIllustration();

  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          width: 148,
          height: 148,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2563EB), Color(0xFF0C3484)],
            ),
            boxShadow: [
              BoxShadow(
                color: _kPrimary.withOpacity(0.5),
                blurRadius: 42,
                spreadRadius: 4,
              ),
              BoxShadow(
                color: _kAccent.withOpacity(0.22),
                blurRadius: 80,
                spreadRadius: 16,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 124,
                height: 124,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.12),
                    width: 1,
                  ),
                ),
              ),
              CustomPaint(
                size: const Size(88, 88),
                painter: _GradCapPainter(),
              ),
            ],
          ),
        ),
      );
}

// ─── Graduation-cap painter (same design as SplashScreen) ────────────────────
class _GradCapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w  = size.width;
    final h  = size.height;
    final cx = w / 2;

    final boardCY = h * 0.36;
    final bHW     = w * 0.44;
    final bHH     = h * 0.13;

    // Board diamond
    final board = Path()
      ..moveTo(cx, boardCY - bHH)
      ..lineTo(cx + bHW, boardCY)
      ..lineTo(cx, boardCY + bHH)
      ..lineTo(cx - bHW, boardCY)
      ..close();
    canvas.drawPath(board, Paint()..color = Colors.white);

    // Highlight
    final highlight = Path()
      ..moveTo(cx, boardCY - bHH)
      ..lineTo(cx + bHW, boardCY)
      ..lineTo(cx, boardCY)
      ..lineTo(cx - bHW, boardCY)
      ..close();
    canvas.drawPath(
      highlight,
      Paint()..color = Colors.white.withOpacity(0.22),
    );

    // Knob
    canvas.drawCircle(
      Offset(cx, boardCY - bHH - 5),
      3.5,
      Paint()..color = _kPaleBlue,
    );

    // Cap body
    final sidesTop    = boardCY + bHH * 0.45;
    final sidesBottom = boardCY + h * 0.38;
    final sHW         = bHW * 0.52;

    final body = Path()
      ..moveTo(cx - sHW, sidesTop)
      ..lineTo(cx + sHW, sidesTop)
      ..lineTo(cx + sHW * 0.78, sidesBottom)
      ..quadraticBezierTo(cx, sidesBottom + h * 0.07, cx - sHW * 0.78, sidesBottom)
      ..close();
    canvas.drawPath(body, Paint()..color = Colors.white.withOpacity(0.88));

    // Tassel line
    final tasselX  = cx + bHW;
    final tasselY0 = boardCY;
    final tasselY1 = boardCY + h * 0.30;
    canvas.drawLine(
      Offset(tasselX, tasselY0),
      Offset(tasselX, tasselY1),
      Paint()
        ..color       = _kPaleBlue
        ..strokeWidth = 2.2
        ..strokeCap   = StrokeCap.round
        ..style       = PaintingStyle.stroke,
    );

    // Tassel tuft
    final tufP = Paint()
      ..color       = _kPaleBlue
      ..strokeWidth = 2.5
      ..strokeCap   = StrokeCap.round;
    canvas.drawLine(
      Offset(tasselX - 5, tasselY1),
      Offset(tasselX + 3, tasselY1 + 7),
      tufP,
    );
    canvas.drawLine(
      Offset(tasselX + 3, tasselY1),
      Offset(tasselX - 5, tasselY1 + 7),
      tufP,
    );

    // Sparkle dots
    for (final pos in [
      Offset(cx - bHW * 0.85, boardCY - bHH * 1.9),
      Offset(cx + bHW * 0.75, boardCY - bHH * 2.2),
      Offset(cx - bHW * 0.55, boardCY + h * 0.58),
    ]) {
      canvas.drawCircle(
        pos, 2.0, Paint()..color = _kPaleBlue.withOpacity(0.7));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// ─── Shared illustration card ─────────────────────────────────────────────────
class _IllustCard extends StatelessWidget {
  final double? width;
  final Widget child;
  final EdgeInsets padding;

  const _IllustCard({
    this.width,
    required this.child,
    this.padding = const EdgeInsets.all(14),
  });

  @override
  Widget build(BuildContext context) => Container(
        width: width,
        padding: padding,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: _kPrimary.withOpacity(0.12),
              blurRadius: 26,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: child,
      );
}

// ══════════════════════════════════════════════════════════════════════════════
// ILLUSTRATION 1 — Manage Coaching
// ══════════════════════════════════════════════════════════════════════════════

class _ManageIllustration extends StatelessWidget {
  const _ManageIllustration();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 300,
        height: 300,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Background glow
            Center(
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _kPrimary.withOpacity(0.08),
                ),
              ),
            ),

            // Back card — attendance summary (rotated)
            Positioned(
              top: 18,
              right: 4,
              child: Transform.rotate(
                angle: 0.13,
                child: _IllustCard(
                  width: 150,
                  padding: const EdgeInsets.all(13),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: _kPrimary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: const Icon(
                              Icons.calendar_today_rounded,
                              color: _kPrimary,
                              size: 11,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Today',
                            style: TextStyle(
                              color: _kTextDark,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 9),
                      Row(
                        children: [
                          for (final c in [
                            _kGreen,
                            _kGreen,
                            _kGreen,
                            _kAmber,
                            _kGreen,
                          ])
                            Container(
                              margin: const EdgeInsets.only(right: 4),
                              width: 15,
                              height: 15,
                              decoration: BoxDecoration(
                                color: c,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 7),
                      Text(
                        '85% Present',
                        style: TextStyle(
                          color: _kGreen,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Main card — student list
            Positioned(
              left: 8,
              top: 36,
              child: _IllustCard(
                width: 192,
                padding: const EdgeInsets.all(15),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: _kPaleBlue,
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: const Text(
                            'Students',
                            style: TextStyle(
                              color: _kPrimary,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: _kPrimary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.add_rounded,
                            color: Colors.white,
                            size: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 11),
                    _StuRow(avatar: 'A', name: 'Ayesha Khan',   present: true),
                    _StuRow(avatar: 'R', name: 'Rahul Sharma',  present: true),
                    _StuRow(avatar: 'M', name: 'Mariam Ali',    present: false),
                    _StuRow(avatar: 'S', name: 'Samir Roy',     present: true),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StuRow extends StatelessWidget {
  final String avatar, name;
  final bool present;
  const _StuRow({
    required this.avatar,
    required this.name,
    required this.present,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.5),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: _kPaleBlue,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  avatar,
                  style: const TextStyle(
                    color: _kPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  color: _kTextDark,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: present ? _kGreen : _kRed,
                shape: BoxShape.circle,
              ),
              child: Icon(
                present ? Icons.check_rounded : Icons.close_rounded,
                color: Colors.white,
                size: 11,
              ),
            ),
          ],
        ),
      );
}

// ══════════════════════════════════════════════════════════════════════════════
// ILLUSTRATION 2 — Track Payments
// ══════════════════════════════════════════════════════════════════════════════

class _PaymentIllustration extends StatelessWidget {
  const _PaymentIllustration();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 300,
        height: 300,
        child: Stack(
          children: [
            // Glow
            Center(
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _kAccent.withOpacity(0.09),
                ),
              ),
            ),

            // Credit card
            Positioned(
              top: 20,
              left: 20,
              right: 20,
              child: Container(
                height: 148,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF1E3A8A),
                      Color(0xFF2563EB),
                      Color(0xFF3B82F6),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: _kPrimary.withOpacity(0.45),
                      blurRadius: 26,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row
                    Row(
                      children: [
                        const Text(
                          'Classora Pay',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const Spacer(),
                        // Chip
                        Container(
                          width: 30,
                          height: 22,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.28),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: CustomPaint(painter: _ChipPainter()),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Card number dots
                    Row(
                      children: [
                        for (int g = 0; g < 3; g++) ...[
                          Row(
                            children: List.generate(
                              4,
                              (_) => Container(
                                width: 5,
                                height: 5,
                                margin: const EdgeInsets.only(right: 3),
                                decoration: const BoxDecoration(
                                  color: Colors.white60,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        const Text(
                          '4832',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'COACHING ACCOUNT',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 8,
                        letterSpacing: 2.2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Transactions card
            Positioned(
              bottom: 12,
              left: 20,
              right: 20,
              child: _IllustCard(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _TxRow(
                        name: 'Ayesha Khan',
                        amount: '৳ 1,500',
                        status: 'Paid'),
                    _TxRow(
                        name: 'Rahul Sharma',
                        amount: '৳ 1,500',
                        status: 'Paid'),
                    _TxRow(
                        name: 'Mariam Ali',
                        amount: '৳ 1,500',
                        status: 'Due'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChipPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(4, 4, size.width - 8, size.height - 8),
        const Radius.circular(2),
      ),
      paint,
    );
    canvas.drawLine(
      Offset(size.width / 2, 4),
      Offset(size.width / 2, size.height - 4),
      paint,
    );
    canvas.drawLine(
      Offset(4, size.height / 2),
      Offset(size.width - 4, size.height / 2),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

class _TxRow extends StatelessWidget {
  final String name, amount, status;
  const _TxRow({
    required this.name,
    required this.amount,
    required this.status,
  });

  bool get _isPaid => status == 'Paid';

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: _kPrimary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                color: _kPrimary,
                size: 14,
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  color: _kTextDark,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              amount,
              style: const TextStyle(
                color: _kTextDark,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: _isPaid
                    ? _kGreen.withOpacity(0.12)
                    : _kAmber.withOpacity(0.15),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                status,
                style: TextStyle(
                  color: _isPaid ? _kGreen : _kAmber,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
}

// ══════════════════════════════════════════════════════════════════════════════
// ILLUSTRATION 3 — Reports
// ══════════════════════════════════════════════════════════════════════════════

class _ReportsIllustration extends StatelessWidget {
  const _ReportsIllustration();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 300,
        height: 300,
        child: Stack(
          children: [
            // Glow
            Center(
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _kPrimary.withOpacity(0.08),
                ),
              ),
            ),

            // Main report card
            Positioned(
              top: 18,
              left: 10,
              right: 10,
              child: _IllustCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Row(
                      children: [
                        const Text(
                          'Performance',
                          style: TextStyle(
                            color: _kTextDark,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _kGreen.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(
                                Icons.trending_up_rounded,
                                color: _kGreen,
                                size: 11,
                              ),
                              SizedBox(width: 3),
                              Text(
                                '+12%',
                                style: TextStyle(
                                  color: _kGreen,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Bar chart
                    SizedBox(
                      height: 82,
                      child: CustomPaint(
                        size: const Size(double.infinity, 82),
                        painter: _BarChartPainter(),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Metric chips
                    Row(
                      children: const [
                        _MetricChip(
                            label: 'Attendance',
                            value: '85%',
                            color: _kPrimary),
                        SizedBox(width: 8),
                        _MetricChip(
                            label: 'Pass Rate',
                            value: '92%',
                            color: _kGreen),
                        SizedBox(width: 8),
                        _MetricChip(
                            label: 'Students',
                            value: '38',
                            color: _kAmber),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final String label, value;
  final Color color;
  const _MetricChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: color.withOpacity(0.09),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: const TextStyle(
                  color: _kTextMuted,
                  fontSize: 7.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
}

class _BarChartPainter extends CustomPainter {
  static const _bars = [0.55, 0.72, 0.88, 0.65, 0.94, 0.78, 0.96];
  static const _labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  void paint(Canvas canvas, Size size) {
    final maxVal  = _bars.reduce(math.max);
    final count   = _bars.length;
    final barW    = size.width / (count * 2 + 1);
    final maxBarH = size.height - 16;

    for (int i = 0; i < count; i++) {
      final x     = barW * (2 * i + 1);
      final barH  = maxBarH * _bars[i];
      final isMax = _bars[i] == maxVal;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, maxBarH - barH, barW, barH),
        const Radius.circular(5),
      );

      if (isMax) {
        canvas.drawRRect(
          rect,
          Paint()
            ..shader = const LinearGradient(
              colors: [_kPrimary, _kAccent],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ).createShader(Rect.fromLTWH(x, 0, barW, size.height)),
        );
      } else {
        canvas.drawRRect(
          rect,
          Paint()..color = _kPaleBlue,
        );
      }

      // Day label
      final tp = TextPainter(
        text: TextSpan(
          text: _labels[i],
          style: TextStyle(
            color: isMax ? _kPrimary : _kTextMuted.withOpacity(0.55),
            fontSize: 8,
            fontWeight: isMax ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
          canvas, Offset(x + (barW - tp.width) / 2, size.height - 13));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}
