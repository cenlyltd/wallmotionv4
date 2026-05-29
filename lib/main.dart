import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/product_service.dart';
import 'services/order_service.dart';
import 'router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase init
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Portrait only
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Full screen immersive
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF050508),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => ProductService()),
        ChangeNotifierProvider(create: (_) => OrderService()),
      ],
      child: const WallMotionApp(),
    ),
  );
}

class WallMotionApp extends StatelessWidget {
  const WallMotionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'WallMotion',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      routerConfig: appRouter,
    );
  }

  ThemeData _buildTheme() {
    const bg      = Color(0xFF050508);
    const surface = Color(0xFF111118);
    const accent  = Color(0xFF00FFC8);
    const text     = Color(0xFFF0F0F8);
    const muted    = Color(0xFF6B6B80);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      colorScheme: const ColorScheme.dark(
        background: bg,
        surface: surface,
        primary: accent,
        onPrimary: Colors.black,
        secondary: Color(0xFF7B5CFF),
        onSecondary: Colors.white,
        onBackground: text,
        onSurface: text,
      ),
      textTheme: GoogleFonts.dmSansTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.syne(
          fontSize: 36, fontWeight: FontWeight.w800, color: text, letterSpacing: -1.5,
        ),
        displayMedium: GoogleFonts.syne(
          fontSize: 28, fontWeight: FontWeight.w800, color: text, letterSpacing: -1,
        ),
        headlineMedium: GoogleFonts.syne(
          fontSize: 22, fontWeight: FontWeight.w800, color: text, letterSpacing: -.5,
        ),
        titleLarge: GoogleFonts.syne(
          fontSize: 18, fontWeight: FontWeight.w700, color: text,
        ),
        titleMedium: GoogleFonts.syne(
          fontSize: 15, fontWeight: FontWeight.w700, color: text,
        ),
        bodyLarge: GoogleFonts.dmSans(fontSize: 15, color: text),
        bodyMedium: GoogleFonts.dmSans(fontSize: 13, color: muted),
        labelSmall: GoogleFonts.dmSans(
          fontSize: 10, fontWeight: FontWeight.w700,
          letterSpacing: 1.5, color: muted,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.07)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.07)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accent, width: 1.5),
        ),
        hintStyle: GoogleFonts.dmSans(color: muted, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.black,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
          textStyle: GoogleFonts.syne(fontSize: 15, fontWeight: FontWeight.w700),
          elevation: 0,
        ),
      ),
      cardTheme: CardTheme(
        color: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withOpacity(0.07)),
        ),
        elevation: 0,
      ),
      dividerTheme: DividerThemeData(
        color: Colors.white.withOpacity(0.07),
        thickness: 1,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF0A0A10),
        selectedItemColor: accent,
        unselectedItemColor: muted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }
}
