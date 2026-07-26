import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  static const _primaryRed = Color(0xFFAC282C);

  // Logo scale + fade
  late final AnimationController _logoController;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;

  // Glow pulse
  late final AnimationController _glowController;
  late final Animation<double> _glowRadius;

  // Tagline slide-up + fade
  late final AnimationController _taglineController;
  late final Animation<double> _taglineOpacity;
  late final Animation<Offset> _taglineSlide;

  // Shimmer sweep
  late final AnimationController _shimmerController;
  late final Animation<double> _shimmerPos;

  @override
  void initState() {
    super.initState();

    // --- Logo: pop-in with bounce ---
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _logoScale = CurvedAnimation(parent: _logoController, curve: Curves.elasticOut)
        .drive(Tween(begin: 0.0, end: 1.0));
    _logoOpacity = CurvedAnimation(parent: _logoController, curve: const Interval(0.0, 0.5))
        .drive(Tween(begin: 0.0, end: 1.0));

    // --- Glow: continuous pulsing ---
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _glowRadius = Tween<double>(begin: 20, end: 60).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // --- Tagline: slide up from below ---
    _taglineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _taglineOpacity = CurvedAnimation(parent: _taglineController, curve: Curves.easeOut)
        .drive(Tween(begin: 0.0, end: 1.0));
    _taglineSlide = Tween<Offset>(begin: const Offset(0, 0.6), end: Offset.zero).animate(
      CurvedAnimation(parent: _taglineController, curve: Curves.easeOutCubic),
    );

    // --- Shimmer sweep across logo ---
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _shimmerPos = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    // Sequence
    _runSequence();
  }

  Future<void> _runSequence() async {
    await Future.delayed(const Duration(milliseconds: 200));
    await _logoController.forward();
    _shimmerController.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    await _taglineController.forward();
    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 700),
        pageBuilder: (_, __, ___) => const LoginScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeIn),
            child: child,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _logoController.dispose();
    _glowController.dispose();
    _taglineController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _primaryRed,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 2),

            // Logo with glow + shimmer
            AnimatedBuilder(
              animation: Listenable.merge([_glowController, _logoController, _shimmerController]),
              builder: (context, child) {
                return ScaleTransition(
                  scale: _logoScale,
                  child: FadeTransition(
                    opacity: _logoOpacity,
                    child: Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.35),
                            blurRadius: _glowRadius.value,
                            spreadRadius: _glowRadius.value * 0.3,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Stack(
                          children: [
                            // Logo
                            Container(
                              color: Colors.white,
                              child: Image.asset(
                                'assets/images/suaja_logo.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                            // Shimmer sweep
                            if (_shimmerController.isAnimating)
                              Positioned.fill(
                                child: Transform.translate(
                                  offset: Offset(_shimmerPos.value * 220, 0),
                                  child: Container(
                                    width: 60,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.white.withValues(alpha: 0.0),
                                          Colors.white.withValues(alpha: 0.5),
                                          Colors.white.withValues(alpha: 0.0),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 32),

            // Tagline
            SlideTransition(
              position: _taglineSlide,
              child: FadeTransition(
                opacity: _taglineOpacity,
                child: Text(
                  'satu jepretan, sejuta kemenangan',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    color: Colors.white.withValues(alpha: 0.9),
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),

            const Spacer(flex: 2),

            // Loading dots
            FadeTransition(
              opacity: _taglineOpacity,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 48),
                child: _LoadingDots(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingDots extends StatefulWidget {
  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final delay = i / 3;
            final t = ((_ctrl.value - delay) % 1.0).clamp(0.0, 1.0);
            final scale = 0.6 + 0.6 * (1 - (t - 0.5).abs() * 2).clamp(0.0, 1.0);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.white70,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
