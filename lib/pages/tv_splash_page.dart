import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/tv_auth_provider.dart';
import '../providers/tv_home_provider.dart';
import '../utils/color.dart';
import 'tv_home_page.dart';

class TVSplashPage extends StatefulWidget {
  const TVSplashPage({super.key});

  @override
  State<TVSplashPage> createState() => _TVSplashPageState();
}

class _TVSplashPageState extends State<TVSplashPage> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _scaleAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );

    _animController.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _initAndNavigate();
    });
  }

  Future<void> _initAndNavigate() async {
    final homeProvider = Provider.of<TVHomeProvider>(context, listen: false);
    final authProvider = Provider.of<TVAuthProvider>(context, listen: false);

    await Future.wait([
      authProvider.initAuth(),
      homeProvider.initHome(),
      Future.delayed(const Duration(milliseconds: 2200)),
    ]);

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const TVHomePage(),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: anim,
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TVColors.appBg,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: ScaleTransition(
            scale: _scaleAnim,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // App Logo Icon
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: TVColors.primary,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: TVColors.primary.withValues(alpha: 0.50),
                        blurRadius: 30,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: 60),
                  ),
                ),
                const SizedBox(height: 24),

                // Brand Name
                Text(
                  "NEXSTREAM TV",
                  style: GoogleFonts.outfit(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3.0,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),

                // Tagline
                Text(
                  "Streaming Movies, Drama & Anime di Layar Lebar",
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: TVColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 48),

                // Loader
                const SpinKitThreeBounce(
                  color: TVColors.primary,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
