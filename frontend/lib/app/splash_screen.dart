import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../features/auth/presentation/auth_provider.dart';
import 'routes.dart';
import 'theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _logoController;
  late final Animation<double> _fadeIn;
  late final Animation<double> _scale;

  late final AnimationController _textController;
  late final Animation<double> _textFade;
  late final Animation<Offset> _textSlide;

  @override
  void initState() {
    super.initState();

    // Logo: fade-in + scale over 800ms
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeIn = CurvedAnimation(parent: _logoController, curve: Curves.easeIn);
    _scale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack),
    );

    // Text: fade + slide up, starts after logo finishes
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _textFade = CurvedAnimation(parent: _textController, curve: Curves.easeIn);
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeOut));

    _startAnimation();
  }

  Future<void> _startAnimation() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _logoController.forward();
    await Future.delayed(const Duration(milliseconds: 500));
    _textController.forward();
    // Wait for animations + a short pause, then navigate
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    String route;
    if (!auth.isLoggedIn) {
      route = AppRoutes.login;
    } else if (auth.isPatient) {
      route = AppRoutes.patientDashboard;
    } else if (auth.isFacilityAdmin) {
      route = AppRoutes.facilityAdminDashboard;
    } else {
      route = AppRoutes.dashboard;
    }
    Navigator.of(context).pushReplacementNamed(route);
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.navyBlue,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated logo
            FadeTransition(
              opacity: _fadeIn,
              child: ScaleTransition(
                scale: _scale,
                child: Image.asset('assets/icon/logo.png', height: 120),
              ),
            ),
            const SizedBox(height: 24),

            // Animated text
            SlideTransition(
              position: _textSlide,
              child: FadeTransition(
                opacity: _textFade,
                child: const Text(
                  'BirthChain',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SlideTransition(
              position: _textSlide,
              child: FadeTransition(
                opacity: _textFade,
                child: Text(
                  'Secure Health Records',
                  style: TextStyle(
                    color: Colors.white.withAlpha(180),
                    fontSize: 14,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
