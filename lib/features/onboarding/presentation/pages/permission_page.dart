import 'dart:async';
import 'package:flutter/material.dart';
import 'package:miaomiao_fill_light/core/theme/app_theme.dart';
import 'package:miaomiao_fill_light/features/lighting/presentation/pages/lighting_page.dart';

class PermissionPage extends StatefulWidget {
  const PermissionPage({super.key});

  @override
  State<PermissionPage> createState() => _PermissionPageState();
}

class _PermissionPageState extends State<PermissionPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _fadeController.forward();

    // 3-second splash timer
    _navigationTimer = Timer(const Duration(seconds: 3), () {
      _navigateToMain();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _navigationTimer?.cancel();
    super.dispose();
  }

  void _navigateToMain() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const LightingPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 1000),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.charcoal,
              Color(0xFF1A1A1A),
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),
                  // 3D Cat Illustration
                  Hero(
                    tag: 'cat_illustration',
                    child: Image.asset(
                      'assets/images/onboarding_cat.png',
                      height: 320,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 50),
                  Text(
                    '喵~ 开启时尚补光',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          letterSpacing: 2,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'MIAOMIAO FILL LIGHT',
                    style: TextStyle(
                      color: AppTheme.vibrantPink.withOpacity(0.4),
                      fontSize: 12,
                      letterSpacing: 6,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  const Spacer(flex: 1),
                  const Text(
                    '正在为您准备光影环境...',
                    style: TextStyle(
                      color: Colors.white24,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: 100,
                    child: LinearProgressIndicator(
                      backgroundColor: Colors.white10,
                      color: AppTheme.vibrantPink.withOpacity(0.3),
                      minHeight: 1,
                    ),
                  ),
                  const Spacer(flex: 2),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
