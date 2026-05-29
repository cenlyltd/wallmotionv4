import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'services/auth_service.dart';
import 'screens/auth/splash_screen.dart';
import 'screens/auth/onboarding_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/detail/detail_screen.dart';
import 'screens/payment/payment_screen.dart';
import 'screens/access/access_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/profile/orders_screen.dart';

final _rootKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootKey,
  initialLocation: '/splash',
  redirect: (context, state) {
    final auth     = context.read<AuthService>();
    final loggedIn = auth.isLoggedIn;
    final loc      = state.matchedLocation;

    final publicRoutes = ['/splash', '/onboarding', '/login', '/register'];
    final isPublic     = publicRoutes.any((r) => loc.startsWith(r));

    if (!loggedIn && !isPublic) return '/login';
    if (loggedIn && (loc == '/login' || loc == '/register')) return '/home';
    return null;
  },
  routes: [
    GoRoute(path: '/splash',      builder: (_, __) => const SplashScreen()),
    GoRoute(path: '/onboarding',  builder: (_, __) => const OnboardingScreen()),
    GoRoute(path: '/login',       builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/register',    builder: (_, __) => const RegisterScreen()),
    GoRoute(
      path: '/home',
      builder: (_, __) => const HomeScreen(),
      routes: [
        GoRoute(
          path: 'detail/:id',
          builder: (_, state) => DetailScreen(productId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: 'payment/:orderId',
          builder: (_, state) => PaymentScreen(orderId: state.pathParameters['orderId']!),
        ),
        GoRoute(
          path: 'access/:orderId',
          builder: (_, state) => AccessScreen(orderId: state.pathParameters['orderId']!),
        ),
      ],
    ),
    GoRoute(path: '/profile',  builder: (_, __) => const ProfileScreen()),
    GoRoute(path: '/orders',   builder: (_, __) => const OrdersScreen()),
  ],
  errorBuilder: (_, state) => Scaffold(
    backgroundColor: const Color(0xFF050508),
    body: Center(
      child: Text('Halaman tidak ditemukan: ${state.error}',
          style: const TextStyle(color: Colors.white)),
    ),
  ),
);
