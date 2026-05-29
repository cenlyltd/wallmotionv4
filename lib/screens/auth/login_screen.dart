import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../widgets/widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email   = TextEditingController();
  final _pass    = TextEditingController();
  bool _loading  = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      await context.read<AuthService>().login(
        email: _email.text.trim(),
        password: _pass.text,
      );
      if (mounted) context.go('/home');
    } catch (e) {
      setState(() { _error = 'Email atau password salah.'; });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050508),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                RichText(
                  text: const TextSpan(
                    style: TextStyle(
                      fontFamily: 'Syne', fontSize: 32,
                      fontWeight: FontWeight.w800, color: Colors.white,
                    ),
                    children: [
                      TextSpan(text: 'Wall'),
                      TextSpan(text: 'Motion',
                          style: TextStyle(color: Color(0xFF00FFC8))),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                const Text('Masuk ke akun kamu',
                    style: TextStyle(color: Color(0xFF6B6B80), fontSize: 14)),
                const SizedBox(height: 40),
                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withOpacity(.2)),
                    ),
                    child: Text(_error!,
                        style: const TextStyle(
                            color: Color(0xFFFF8899), fontSize: 13)),
                  ),
                  const SizedBox(height: 16),
                ],
                WMTextField(
                  label: 'Email',
                  hint: 'email@kamu.com',
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) =>
                      v!.contains('@') ? null : 'Email tidak valid',
                ),
                const SizedBox(height: 16),
                WMTextField(
                  label: 'Password',
                  hint: '••••••••',
                  controller: _pass,
                  obscure: true,
                  validator: (v) =>
                      v!.length >= 6 ? null : 'Min. 6 karakter',
                ),
                const SizedBox(height: 28),
                WMButton(label: 'Masuk →', onTap: _login, loading: _loading),
                const SizedBox(height: 16),
                Center(
                  child: GestureDetector(
                    onTap: () => context.go('/register'),
                    child: RichText(
                      text: const TextSpan(
                        style: TextStyle(
                            fontSize: 13, color: Color(0xFF6B6B80)),
                        children: [
                          TextSpan(text: 'Belum punya akun? '),
                          TextSpan(
                            text: 'Daftar sekarang',
                            style: TextStyle(
                              color: Color(0xFF00FFC8),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: GestureDetector(
                    onTap: () async {
                      final email = _email.text.trim();
                      if (email.isEmpty) {
                        setState(() => _error = 'Masukkan email dulu.');
                        return;
                      }
                      await context
                          .read<AuthService>()
                          .sendPasswordReset(email);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Link reset password dikirim ke email kamu.')),
                        );
                      }
                    },
                    child: const Text('Lupa password?',
                        style: TextStyle(
                            color: Color(0xFF6B6B80), fontSize: 12)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
