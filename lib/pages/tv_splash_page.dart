import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/tv_auth_provider.dart';
import '../providers/tv_home_provider.dart';
import '../utils/color.dart';
import '../utils/constant.dart';
import 'tv_home_page.dart';

// Brand palette synchronized with dtlive-app
const _lime = TVColors.primary; // #BAFA34
const _cyan = Color(0xFF00D1FF); // Vibrant Electric Cyan
const _purple = complimentryColor; // #792BEC
const _red = Color(0xFFEC2B4E); // Vibrant Neon Red
const _orange = warningBG; // #FFA500

class TVSplashPage extends StatefulWidget {
  const TVSplashPage({super.key});

  @override
  State<TVSplashPage> createState() => _TVSplashPageState();
}

class _TVSplashPageState extends State<TVSplashPage> with TickerProviderStateMixin {
  // ── Background (starts at 0ms) ─────────────────────────────────────────
  late AnimationController _bgCtrl; // 600ms one-shot
  late Animation<double> _bgFade;

  // ── Glow blobs (all loop forever) ──────────────────────────────────────
  late AnimationController _orbitCtrl; // 9000ms
  late AnimationController _pulse1; // 2400ms
  late AnimationController _pulse2; // 3000ms
  late AnimationController _pulse3; // 3600ms
  late Animation<double> _orbitAngle;
  late Animation<double> _p1s, _p1o;
  late Animation<double> _p2s, _p2o;
  late Animation<double> _p3s, _p3o;

  // ── Icon reveal (starts at 300ms, 700ms duration) ──────────────────────
  late AnimationController _iconCtrl;
  late Animation<double> _iconOpacity;
  late Animation<double> _iconScale;

  // ── Shine sweep — fully controller-driven ─────────────────────────────
  late AnimationController _shineOpCtrl; // 150ms one-shot (fade in)
  late AnimationController _shineProgCtrl; // 450ms one-shot (sweep)
  late AnimationController _shineOutCtrl; // 150ms one-shot (fade out)
  late Animation<double> _shineOpacity;
  late Animation<double> _shineProg;

  // ── Separator (starts at 1000ms, 550ms duration) ───────────────────────
  late AnimationController _sepCtrl;
  late Animation<double> _sepFade;
  late Animation<double> _sepLineScale;

  // ── Separator dot ring (loop, starts at 1000ms) ────────────────────────
  late AnimationController _dotRingCtrl;
  late Animation<double> _dotRingScale;
  late Animation<double> _dotRingOpacity;

  // ── Tagline (starts at 1200ms, 750ms duration) ────────────────────────
  late AnimationController _tagCtrl;
  late Animation<double> _tagOpacity;
  late Animation<Offset> _tagSlide;

  // ── Subtitle (starts at 1900ms, 550ms duration) ───────────────────────
  late AnimationController _subCtrl;
  late Animation<double> _subOpacity;

  // ── Late elements: stripe + dots + bar (starts at 2000ms, 450ms) ──────
  late AnimationController _lateCtrl;
  late Animation<double> _lateFade;

  // ── Dots bounce + colour wave (loop) ──────────────────────────────────
  late AnimationController _dotsCtrl; // 1100ms loop
  late AnimationController _waveCtrl; // 2000ms loop

  // ── Bottom progress strip shimmer (loop) ──────────────────────────────
  late AnimationController _stripCtrl; // 1800ms loop

  // ── Logo geometry for shine sweep ──────────────────────────────────────
  Size _logoSize = Size.zero;
  Offset _logoOffset = Offset.zero;
  final GlobalKey _logoKey = GlobalKey();

  // ── Navigation Gate Flags ─────────────────────────────────────────────
  bool _animDone = false;
  bool _dataDone = false;
  final List<Timer> _timers = [];

  @override
  void initState() {
    super.initState();
    _createControllers();
    _startSequence();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _readLogoGeometry();
      _fetchData();
    });
  }

  void _readLogoGeometry() {
    final box = _logoKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    _logoSize = box.size;
    _logoOffset = box.localToGlobal(Offset.zero);
  }

  void _createControllers() {
    // Background
    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _bgFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _bgCtrl, curve: Curves.easeOut),
    );

    // Orbit
    _orbitCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 9000),
    );
    _orbitAngle = Tween<double>(begin: 0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _orbitCtrl, curve: Curves.linear),
    );

    _pulse1 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    _p1s = Tween<double>(begin: 0.80, end: 1.24).animate(
      CurvedAnimation(parent: _pulse1, curve: Curves.easeInOut),
    );
    _p1o = Tween<double>(begin: 0.17, end: 0.52).animate(
      CurvedAnimation(parent: _pulse1, curve: Curves.easeInOut),
    );

    _pulse2 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
    _p2s = Tween<double>(begin: 0.86, end: 1.30).animate(
      CurvedAnimation(parent: _pulse2, curve: Curves.easeInOut),
    );
    _p2o = Tween<double>(begin: 0.13, end: 0.46).animate(
      CurvedAnimation(parent: _pulse2, curve: Curves.easeInOut),
    );

    _pulse3 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    );
    _p3s = Tween<double>(begin: 0.76, end: 1.20).animate(
      CurvedAnimation(parent: _pulse3, curve: Curves.easeInOut),
    );
    _p3o = Tween<double>(begin: 0.11, end: 0.40).animate(
      CurvedAnimation(parent: _pulse3, curve: Curves.easeInOut),
    );

    // Icon
    _iconCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _iconOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _iconCtrl,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
      ),
    );
    _iconScale = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(
        parent: _iconCtrl,
        curve: const Interval(0.0, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    // Shine sweep
    _shineOpCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _shineOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shineOpCtrl, curve: Curves.easeIn),
    );

    _shineProgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _shineProg = Tween<double>(begin: -0.38, end: 1.38).animate(
      CurvedAnimation(parent: _shineProgCtrl, curve: Curves.easeInOut),
    );

    _shineOutCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );

    // Separator
    _sepCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _sepFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _sepCtrl, curve: Curves.easeOut),
    );
    _sepLineScale = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _sepCtrl, curve: Curves.easeOut),
    );

    // Dot ring
    _dotRingCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _dotRingScale = Tween<double>(begin: 1.0, end: 2.6).animate(
      CurvedAnimation(parent: _dotRingCtrl, curve: Curves.easeOut),
    );
    _dotRingOpacity = Tween<double>(begin: 0.70, end: 0.0).animate(
      CurvedAnimation(parent: _dotRingCtrl, curve: Curves.easeOut),
    );

    // Tagline
    _tagCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
    _tagOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _tagCtrl, curve: Curves.easeOut),
    );
    _tagSlide = Tween<Offset>(
      begin: const Offset(0, 0.14),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _tagCtrl, curve: Curves.easeOutCubic));

    // Subtitle
    _subCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _subOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _subCtrl, curve: Curves.easeOut),
    );

    // Late elements
    _lateCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _lateFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _lateCtrl, curve: Curves.easeOut),
    );

    // Dots + wave
    _dotsCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // Bottom strip
    _stripCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
  }

  void _startSequence() {
    _bgCtrl.forward();
    _orbitCtrl.repeat();
    _pulse1.repeat(reverse: true);
    _pulse2.repeat(reverse: true);
    _pulse3.repeat(reverse: true);
    _dotsCtrl.repeat();
    _waveCtrl.repeat();
    _stripCtrl.repeat();

    _at(250, _iconCtrl.forward);

    _at(550, () {
      _shineOpCtrl.forward().whenComplete(() {
        _shineProgCtrl.forward().whenComplete(() {
          _shineOutCtrl.forward();
        });
      });
    });

    _at(900, () {
      _sepCtrl.forward();
      _dotRingCtrl.repeat();
    });

    _at(1100, _tagCtrl.forward);
    _at(1600, _subCtrl.forward);
    _at(1750, _lateCtrl.forward);

    // Splash duration gate (2400ms)
    _at(2400, () {
      _animDone = true;
      _tryNavigate();
    });

    // Safety fallback so splash screen never gets stuck indefinitely
    _at(5000, () {
      if (!_dataDone) {
        _dataDone = true;
        _tryNavigate();
      }
    });
  }

  void _at(int ms, VoidCallback fn) {
    final timer = Timer(Duration(milliseconds: ms), () {
      if (mounted) fn();
    });
    _timers.add(timer);
  }

  Future<void> _fetchData() async {
    try {
      final homeProvider = Provider.of<TVHomeProvider>(context, listen: false);
      final authProvider = Provider.of<TVAuthProvider>(context, listen: false);

      await Future.wait([
        authProvider.initAuth(),
        homeProvider.initHome(),
      ]);
    } catch (e) {
      debugPrint("Error initializing TV data: $e");
    } finally {
      _dataDone = true;
      if (mounted) _tryNavigate();
    }
  }

  void _tryNavigate() {
    if (!_animDone || !_dataDone || !mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, anim, secAnim) => const TVHomePage(),
        transitionDuration: const Duration(milliseconds: 600),
        transitionsBuilder: (context, anim, secAnim, child) => FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
          child: child,
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    _timers.clear();
    _bgCtrl.dispose();
    _orbitCtrl.dispose();
    _pulse1.dispose();
    _pulse2.dispose();
    _pulse3.dispose();
    _iconCtrl.dispose();
    _shineOpCtrl.dispose();
    _shineProgCtrl.dispose();
    _shineOutCtrl.dispose();
    _sepCtrl.dispose();
    _dotRingCtrl.dispose();
    _tagCtrl.dispose();
    _subCtrl.dispose();
    _lateCtrl.dispose();
    _dotsCtrl.dispose();
    _waveCtrl.dispose();
    _stripCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: appBgColor,
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _bgCtrl,
          _orbitCtrl,
          _pulse1,
          _pulse2,
          _pulse3,
          _iconCtrl,
          _shineOpCtrl,
          _shineProgCtrl,
          _shineOutCtrl,
          _sepCtrl,
          _dotRingCtrl,
          _tagCtrl,
          _subCtrl,
          _lateCtrl,
          _dotsCtrl,
          _waveCtrl,
          _stripCtrl,
        ]),
        builder: (context, child) {
          _readLogoGeometry();

          final shineAlpha =
              _shineOpacity.value * (1.0 - _shineOutCtrl.value).clamp(0.0, 1.0);

          return Stack(
            fit: StackFit.expand,
            children: [
              // 1 — Background
              _buildBg(),

              // 2 — Rotating glow blobs
              _buildBlobs(size),

              // 3 — Shine overlay over logo
              if (_logoSize != Size.zero && shineAlpha > 0.0)
                _buildShine(shineAlpha),

              // 4 — Center content column (Landscape TV optimized)
              _buildContent(size),

              // 5 — Top brand stripe
              Positioned(top: 0, left: 0, right: 0, child: _buildStripe()),

              // 6 — Bottom progress strip
              Positioned(bottom: 0, left: 0, right: 0, child: _buildStripe()),

              // 7 — Version label
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: Opacity(
                  opacity: _lateFade.value.clamp(0.0, 1.0),
                  child: Text(
                    "v${Constant.appVersion}",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 2.0,
                      color: titleTextColor.withValues(alpha: 0.22),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBg() => Opacity(
    opacity: _bgFade.value,
    child: Container(color: appBgColor),
  );

  Widget _buildBlobs(Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.height * 0.40;
    final a = _orbitAngle.value;
    final b3 = Color.lerp(_cyan, _orange, _pulse1.value)!;

    return Opacity(
      opacity: _bgFade.value,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _blob(
            cx + r * math.cos(a),
            cy + r * 0.45 * math.sin(a),
            size.height * 0.85,
            _lime,
            _p1s.value,
            _p1o.value,
          ),
          _blob(
            cx + r * math.cos(a + 2.094),
            cy + r * 0.45 * math.sin(a + 2.094),
            size.height * 0.78,
            _purple,
            _p2s.value,
            _p2o.value,
          ),
          _blob(
            cx + r * math.cos(a + 4.189),
            cy + r * 0.45 * math.sin(a + 4.189),
            size.height * 0.70,
            b3,
            _p3s.value,
            _p3o.value,
          ),
          // Dark radial vignette — keeps center readable and creates cinematic OLED depth
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 0.86,
                colors: [
                  transparent,
                  black.withValues(alpha: 0.80),
                  black.withValues(alpha: 0.97),
                ],
                stops: const [0.24, 0.60, 1.0],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _blob(
    double cx,
    double cy,
    double sz,
    Color color,
    double scale,
    double opacity,
  ) {
    final s = sz * scale;
    return Positioned(
      left: cx - s / 2,
      top: cy - s / 2,
      width: s,
      height: s,
      child: Opacity(
        opacity: opacity,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                color.withValues(alpha: 0.50),
                color.withValues(alpha: 0.13),
                transparent,
              ],
              stops: const [0.0, 0.45, 1.0],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShine(double opacity) => Positioned(
    left: _logoOffset.dx,
    top: _logoOffset.dy,
    width: _logoSize.width,
    height: _logoSize.height,
    child: ClipRect(
      child: Opacity(
        opacity: opacity.clamp(0.0, 1.0),
        child: CustomPaint(painter: _ShinePainter(progress: _shineProg.value)),
      ),
    ),
  );

  Widget _buildStripe() => Opacity(
    opacity: _lateFade.value.clamp(0.0, 1.0),
    child: Container(
      height: 2,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [transparent, _lime, _cyan, transparent],
          stops: [0.0, 0.38, 0.62, 1.0],
        ),
      ),
    ),
  );

  Widget _buildContent(Size size) {
    // Landscape Android TV sizing
    final logoW = (size.height * 0.26).clamp(180.0, 260.0);
    final sepW = (size.width * 0.12).clamp(100.0, 160.0);
    final taglineFs = (size.height * 0.038).clamp(20.0, 26.0);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // ── App Icon with Fade + Scale ─────────────────────────────
        Opacity(
          opacity: _iconOpacity.value.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: _iconScale.value,
            child: SizedBox(
              key: _logoKey,
              width: logoW,
              child: Image.asset(
                'assets/images/appicon.png',
                width: logoW,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Image.asset(
                  'assets/appicon/appicon.png',
                  width: logoW,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 22),

        // ── Separator with expanding ring & center neon dot ────────
        Opacity(
          opacity: _sepFade.value.clamp(0.0, 1.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Left gradient line (sweeps from center outward)
              Transform.scale(
                scaleX: _sepLineScale.value,
                alignment: Alignment.centerRight,
                child: Container(
                  width: sepW,
                  height: 1.5,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [transparent, _lime],
                    ),
                  ),
                ),
              ),

              // Pulsing neon dot with expanding ripple ring
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Expanding ripple ring
                      Transform.scale(
                        scale: _dotRingScale.value,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _lime.withValues(
                                alpha: _dotRingOpacity.value.clamp(0.0, 1.0),
                              ),
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                      // Solid lime center dot
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: _lime,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Right gradient line (sweeps from center outward)
              Transform.scale(
                scaleX: _sepLineScale.value,
                alignment: Alignment.centerLeft,
                child: Container(
                  width: sepW,
                  height: 1.5,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_lime, transparent],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // ── Tagline with Slide & Gradient ShaderMask ────────────────
        FadeTransition(
          opacity: _tagOpacity,
          child: SlideTransition(
            position: _tagSlide,
            child: _buildTagline(taglineFs),
          ),
        ),

        const SizedBox(height: 10),

        // ── Subtitle ───────────────────────────────────────────────
        FadeTransition(
          opacity: _subOpacity,
          child: Text(
            'Unlimited Entertainment Awaits',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 3.2,
              color: titleTextColor.withValues(alpha: 0.38),
            ),
          ),
        ),

        const SizedBox(height: 28),

        // ── Color-cycling bounce wave dots ─────────────────────────
        Opacity(
          opacity: _lateFade.value.clamp(0.0, 1.0),
          child: _buildDots(),
        ),
      ],
    );
  }

  Widget _buildTagline(double fontSize) {
    return Column(
      children: [
        _tagLine('Stream ', 'Everything.', fontSize),
        _tagLine('Miss ', 'Nothing.', fontSize),
      ],
    );
  }

  Widget _tagLine(String plain, String grad, double fontSize) {
    final baseStyle = GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.5,
      height: 1.2,
    );

    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: baseStyle,
        children: [
          TextSpan(
            text: plain,
            style: baseStyle.copyWith(color: white),
          ),
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: ShaderMask(
              shaderCallback: (bounds) =>
                  const LinearGradient(colors: [_lime, _cyan]).createShader(bounds),
              child: Text(
                grad,
                style: baseStyle.copyWith(color: white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDots() {
    const phases = [0.00, 0.20, 0.40, 0.60, 0.80];
    const palette = [_lime, _cyan, _purple, _red, _orange];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (i) {
        return AnimatedBuilder(
          animation: Listenable.merge([_dotsCtrl, _waveCtrl]),
          builder: (context, child) {
            final t = math.sin(((_dotsCtrl.value + phases[i]) % 1.0) * math.pi);
            final ct = (_waveCtrl.value + i * 0.20) % 1.0;
            final ci = (ct * palette.length).floor();
            final cf = ct * palette.length - ci;
            final col = Color.lerp(
              palette[ci % palette.length],
              palette[(ci + 1) % palette.length],
              cf,
            )!;
            return Container(
              width: 8,
              height: 8 + 14.0 * t,
              margin: const EdgeInsets.symmetric(horizontal: 5),
              decoration: BoxDecoration(
                color: col.withValues(alpha: 0.42 + 0.58 * t),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          },
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shine Painter — diagonal light beam sweeping across the app icon
// ─────────────────────────────────────────────────────────────────────────────
class _ShinePainter extends CustomPainter {
  final double progress; // -0.38 → 1.38
  const _ShinePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    const bw = 0.26;
    final cx = size.width * progress;
    final skew = size.height * 0.36;

    final path = Path()
      ..moveTo(cx - size.width * bw / 2 - skew, 0)
      ..lineTo(cx + size.width * bw / 2 - skew, 0)
      ..lineTo(cx + size.width * bw / 2 + skew, size.height)
      ..lineTo(cx - size.width * bw / 2 + skew, size.height)
      ..close();

    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          colors: [
            white.withValues(alpha: 0.0),
            white.withValues(alpha: 0.40),
            white.withValues(alpha: 0.60),
            white.withValues(alpha: 0.40),
            white.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.35, 0.50, 0.65, 1.0],
        ).createShader(
          Rect.fromLTWH(
            cx - size.width * bw / 2,
            0,
            size.width * bw,
            size.height,
          ),
        ),
    );
  }

  @override
  bool shouldRepaint(_ShinePainter oldDelegate) => oldDelegate.progress != progress;
}
