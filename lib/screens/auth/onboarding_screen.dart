import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _ctrl = PageController();
  int _page   = 0;

  final _pages = const [
    _OnboardPage(
      icon: '🎨',
      title: 'Wallpaper Eksklusif',
      sub: 'Ribuan live wallpaper aesthetic, cinematic, dan keren — tidak ada di tempat lain.',
    ),
    _OnboardPage(
      icon: '📱',
      title: 'Pasang Langsung',
      sub: 'Beli → bayar QRIS → wallpaper terpasang otomatis. Semua dalam satu app.',
    ),
    _OnboardPage(
      icon: '🔒',
      title: 'Aman & Eksklusif',
      sub: 'Wallpaper kamu dilindungi. File asli tidak bisa diunduh atau dishare orang lain.',
    ),
  ];

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _done() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarded', true);
    if (mounted) context.go('/register');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050508),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _ctrl,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (_, i) => _pages[i],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 36),
              child: Column(
                children: [
                  SmoothPageIndicator(
                    controller: _ctrl,
                    count: _pages.length,
                    effect: const ExpandingDotsEffect(
                      activeDotColor: Color(0xFF00FFC8),
                      dotColor: Color(0xFF2A2A35),
                      dotHeight: 6,
                      dotWidth: 6,
                      expansionFactor: 3,
                    ),
                  ),
                  const SizedBox(height: 28),
                  GestureDetector(
                    onTap: () {
                      if (_page < _pages.length - 1) {
                        _ctrl.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                        );
                      } else {
                        _done();
                      }
                    },
                    child: Container(
                      height: 52,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFF00FFC8),
                        borderRadius: BorderRadius.circular(100),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00FFC8).withOpacity(.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Text(
                        _page < _pages.length - 1
                            ? 'Selanjutnya →'
                            : 'Mulai Sekarang →',
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  if (_page < _pages.length - 1) ...[
                    const SizedBox(height: 14),
                    GestureDetector(
                      onTap: _done,
                      child: const Text('Lewati',
                          style: TextStyle(
                              color: Color(0xFF6B6B80), fontSize: 13)),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardPage extends StatelessWidget {
  final String icon, title, sub;
  const _OnboardPage({
    required this.icon,
    required this.title,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 72)),
            const SizedBox(height: 32),
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Syne',
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            Text(
              sub,
              style: const TextStyle(
                color: Color(0xFF6B6B80),
                fontSize: 15,
                height: 1.7,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
}
