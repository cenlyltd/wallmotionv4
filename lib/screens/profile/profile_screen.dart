import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import '../../widgets/widgets.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameCtrl    = TextEditingController();
  final _phoneCtrl   = TextEditingController();
  final _curPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confPassCtrl= TextEditingController();

  bool _editMode = false;
  bool _loading  = false;
  String? _msg;
  String? _error;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthService>().user;
    _nameCtrl.text  = user?.name  ?? '';
    _phoneCtrl.text = user?.phone ?? '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _phoneCtrl.dispose();
    _curPassCtrl.dispose(); _newPassCtrl.dispose(); _confPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() { _loading = true; _msg = null; _error = null; });
    try {
      await context.read<AuthService>().updateProfile(
        name: _nameCtrl.text.trim(), phone: _phoneCtrl.text.trim());
      setState(() { _msg = 'Profil berhasil diperbarui.'; _editMode = false; });
    } catch (e) {
      setState(() => _error = 'Gagal memperbarui profil.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _changePass() async {
    if (_newPassCtrl.text != _confPassCtrl.text) {
      setState(() => _error = 'Konfirmasi password tidak cocok.'); return;
    }
    if (_newPassCtrl.text.length < 6) {
      setState(() => _error = 'Password baru minimal 6 karakter.'); return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await context.read<AuthService>().changePassword(
        currentPassword: _curPassCtrl.text, newPassword: _newPassCtrl.text);
      _curPassCtrl.clear(); _newPassCtrl.clear(); _confPassCtrl.clear();
      setState(() => _msg = 'Password berhasil diubah.');
    } catch (e) {
      setState(() => _error = 'Password saat ini salah.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final user = auth.user;

    return Scaffold(
      backgroundColor: const Color(0xFF050508),
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0, automaticallyImplyLeading: false,
        title: Text('Profil', style: GoogleFonts.syne(fontWeight: FontWeight.w800, color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () async {
              await auth.logout();
              if (mounted) context.go('/login');
            },
            child: const Text('Keluar', style: TextStyle(color: Color(0xFFFF4466), fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── Avatar + name ──────────────────────────────────────────
          Center(
            child: Column(children: [
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00FFC8), Color(0xFF7B5CFF)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  (user?.name ?? 'U').substring(0, 1).toUpperCase(),
                  style: GoogleFonts.syne(color: Colors.black, fontSize: 32, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(height: 12),
              Text(user?.name ?? '', style: GoogleFonts.syne(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
              Text(user?.email ?? '', style: const TextStyle(color: Color(0xFF6B6B80), fontSize: 13)),
            ]),
          ),
          const SizedBox(height: 28),

          // Messages
          if (_msg != null) _banner(_msg!, isError: false),
          if (_error != null) _banner(_error!, isError: true),

          // ── Info card ──────────────────────────────────────────────
          _sectionCard(
            title: 'Informasi Akun',
            trailing: TextButton(
              onPressed: () => setState(() { _editMode = !_editMode; _msg = null; _error = null; }),
              child: Text(_editMode ? 'Batal' : 'Edit',
                style: const TextStyle(color: Color(0xFF00FFC8), fontWeight: FontWeight.w600, fontSize: 13)),
            ),
            child: Column(children: [
              if (_editMode) ...[
                WMTextField(label: 'Nama', controller: _nameCtrl),
                const SizedBox(height: 14),
                WMTextField(label: 'Nomor HP', controller: _phoneCtrl, keyboardType: TextInputType.phone),
                const SizedBox(height: 18),
                WMButton(label: 'Simpan', onTap: _save, loading: _loading),
              ] else ...[
                _infoRow('Nama',    user?.name  ?? '-'),
                _infoRow('Email',   user?.email ?? '-'),
                _infoRow('Nomor HP', user?.phone?.isEmpty ?? true ? '-' : user!.phone!),
              ],
            ]),
          ),
          const SizedBox(height: 14),

          // ── Password card ──────────────────────────────────────────
          _sectionCard(
            title: 'Ganti Password',
            child: Column(children: [
              WMTextField(label: 'Password Saat Ini', controller: _curPassCtrl, obscure: true),
              const SizedBox(height: 14),
              WMTextField(label: 'Password Baru', controller: _newPassCtrl, obscure: true),
              const SizedBox(height: 14),
              WMTextField(label: 'Konfirmasi Password Baru', controller: _confPassCtrl, obscure: true),
              const SizedBox(height: 18),
              WMButton(label: 'Ubah Password', onTap: _changePass, loading: _loading),
            ]),
          ),
          const SizedBox(height: 14),

          // ── Danger zone ────────────────────────────────────────────
          GestureDetector(
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  backgroundColor: const Color(0xFF111118),
                  title: const Text('Keluar?', style: TextStyle(color: Colors.white, fontFamily: 'Syne')),
                  content: const Text('Kamu akan logout dari WallMotion.', style: TextStyle(color: Color(0xFF6B6B80))),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
                    TextButton(onPressed: () => Navigator.pop(context, true),
                      child: const Text('Keluar', style: TextStyle(color: Color(0xFFFF4466)))),
                  ],
                ),
              );
              if (confirm == true && mounted) {
                await auth.logout();
                context.go('/login');
              }
            },
            child: Container(
              width: double.infinity, height: 50,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.red.withOpacity(.2)),
              ),
              alignment: Alignment.center,
              child: const Text('Keluar dari Akun',
                style: TextStyle(color: Color(0xFFFF4466), fontWeight: FontWeight.w600, fontSize: 14)),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _banner(String msg, {required bool isError}) => Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: (isError ? Colors.red : const Color(0xFF00FFC8)).withOpacity(.08),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: (isError ? Colors.red : const Color(0xFF00FFC8)).withOpacity(.2)),
    ),
    child: Text(msg, style: TextStyle(color: isError ? const Color(0xFFFF8899) : const Color(0xFF00FFC8), fontSize: 13)),
  );

  Widget _sectionCard({required String title, required Widget child, Widget? trailing}) => Container(
    decoration: BoxDecoration(
      color: const Color(0xFF111118),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.white.withOpacity(.07)),
    ),
    padding: const EdgeInsets.all(18),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text(title, style: GoogleFonts.syne(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.white)),
        const Spacer(),
        if (trailing != null) trailing,
      ]),
      const SizedBox(height: 16),
      child,
    ]),
  );

  Widget _infoRow(String label, String val) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(children: [
      Text(label, style: const TextStyle(color: Color(0xFF6B6B80), fontSize: 13)),
      const Spacer(),
      Text(val, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
    ]),
  );
}

