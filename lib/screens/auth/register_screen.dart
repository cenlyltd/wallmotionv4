import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../widgets/widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name    = TextEditingController();
  final _email   = TextEditingController();
  final _pass    = TextEditingController();
  bool _loading  = false;
  bool _done     = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      await context.read<AuthService>().register(
        name:     _name.text.trim(),
        email:    _email.text.trim(),
        password: _pass.text,
      );
      if (mounted) setState(() { _done = true; _loading = false; });
    } catch (e) {
      setState(() {
        _error   = 'Email sudah terdaftar atau terjadi kesalahan.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_done) {
      return Scaffold(
        backgroundColor: const Color(0xFF050508),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('📬', style: TextStyle(fontSize: 64)),
                const SizedBox(height: 20),
                const Text(
                  'Cek Email Kamu!',
                  style: TextStyle(
                    fontFamily: 'Syne',
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Link verifikasi dikirim ke\n${_email.text}',
                  style: const TextStyle(
                    color: Color(0xFF6B6B80),
                    fontSize: 14,
                    height: 1.7,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                WMButton(
                  label: 'Ke Halaman Login →',
                  onTap: () => context.go('/login'),
                ),
              ],
            ),
          ),
        ),
      );
    }

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
                const Text(
                  'Buat Akun',
                  style: TextStyle(
                    fontFamily: 'Syne',
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const Text('Gratis, selamanya.',
                    style: TextStyle(
                        color: Color(0xFF6B6B80), fontSize: 14)),
                const SizedBox(height: 36),
                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(.08),
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: Colors.red.withOpacity(.2)),
                    ),
                    child: Text(_error!,
                        style: const TextStyle(
                            color: Color(0xFFFF8899), fontSize: 13)),
                  ),
                  const SizedBox(height: 16),
                ],
                WMTextField(
                  label: 'Nama Lengkap',
                  hint: 'Nama kamu',
                  controller: _name,
                  validator: (v) =>
                      v!.isNotEmpty ? null : 'Nama wajib diisi',
                ),
                const SizedBox(height: 16),
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
                  hint: 'Minimal 6 karakter',
                  controller: _pass,
                  obscure: true,
                  validator: (v) =>
                      v!.length >= 6 ? null : 'Min. 6 karakter',
                ),
                const SizedBox(height: 28),
                WMButton(
                  label: 'Buat Akun →',
                  onTap: _register,
                  loading: _loading,
                ),
                const SizedBox(height: 16),
                Center(
                  child: GestureDetector(
                    onTap: () => context.go('/login'),
                    child: RichText(
                      text: const TextSpan(
                        style: TextStyle(
                            fontSize: 13, color: Color(0xFF6B6B80)),
                        children: [
                          TextSpan(text: 'Sudah punya akun? '),
                          TextSpan(
                            text: 'Masuk',
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
