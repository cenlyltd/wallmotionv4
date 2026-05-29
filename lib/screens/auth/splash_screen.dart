import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ac;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ac   = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fade = CurvedAnimation(parent: _ac, curve: Curves.easeOut);
    _ac.forward();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;
    final auth      = context.read<AuthService>();
    final prefs     = await SharedPreferences.getInstance();
    final onboarded = prefs.getBool('onboarded') ?? false;

    if (!onboarded) { context.go('/onboarding'); return; }
    if (auth.isLoggedIn) { context.go('/home'); return; }
    context.go('/login');
  }

  @override
  void dispose() { _ac.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050508),
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00FFC8), Color(0xFF7B5CFF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Icon(Icons.wallpaper_rounded, color: Colors.black, size: 40),
              ),
              const SizedBox(height: 20),
              RichText(
                text: const TextSpan(
                  style: TextStyle(
                    fontFamily: 'Syne', fontSize: 28,
                    fontWeight: FontWeight.w800, color: Colors.white,
                  ),
                  children: [
                    TextSpan(text: 'Wall'),
                    TextSpan(text: 'Motion',
                        style: TextStyle(color: Color(0xFF00FFC8))),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Text('Live Wallpaper Premium',
                  style: TextStyle(color: Color(0xFF6B6B80), fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}
