import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:wallpaper_manager_flutter/wallpaper_manager_flutter.dart';
import '../../models/models.dart';
import '../../services/order_service.dart';

class AccessScreen extends StatefulWidget {
  final String orderId;
  const AccessScreen({super.key, required this.orderId});
  @override State<AccessScreen> createState() => _AccessScreenState();
}

class _AccessScreenState extends State<AccessScreen> {
  OrderModel? _order;
  bool _loading     = true;
  bool _settingWall = false;
  bool _wallSet     = false;
  String? _error;
  String? _streamUrl;
  int _wallProgress = 0;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    final orderService = context.read<OrderService>();

    // Listen once
    orderService.orderStream(widget.orderId).first.then((order) {
      if (!mounted) return;
      setState(() { _order = order; _loading = false; });
      if (order?.canAccess ?? false) _getStreamUrl();
    });
  }

  Future<void> _getStreamUrl() async {
    try {
      final url = await context.read<OrderService>().getWallpaperStreamUrl(widget.orderId);
      if (mounted) setState(() => _streamUrl = url);
    } catch (e) {
      if (mounted) setState(() => _error = 'Gagal memuat wallpaper. Coba lagi.');
    }
  }

  // ── Set wallpaper langsung dari stream URL ────────────────────────────
  // File di-stream ke temp, dipasang, lalu temp dihapus
  Future<void> _setWallpaper(int location) async {
    if (_streamUrl == null) return;
    setState(() { _settingWall = true; _wallProgress = 0; _error = null; });

    try {
      // Download to temp (bukan ke gallery, tidak bisa dilihat user)
      final tempDir  = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/wm_temp_${DateTime.now().millisecondsSinceEpoch}.mp4');

      final response = await http.get(Uri.parse(_streamUrl!));
      if (response.statusCode != 200) throw Exception('Download gagal');

      await tempFile.writeAsBytes(response.bodyBytes);
      setState(() => _wallProgress = 60);

      // Set wallpaper via plugin
      await WallpaperManagerFlutter().setwallpaperfromFile(tempFile, location);
      setState(() => _wallProgress = 100);

      // Hapus temp file
      await tempFile.delete();

      HapticFeedback.heavyImpact();
      if (mounted) setState(() { _wallSet = true; _settingWall = false; });

    } catch (e) {
      setState(() {
        _error      = 'Gagal memasang wallpaper. Pastikan izin diberikan.';
        _settingWall = false;
      });
    }
  }

  void _showLocationPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111118),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 36, height: 4, margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(4))),
          Text('Pasang di mana?', style: GoogleFonts.syne(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
          const SizedBox(height: 20),
          _locationBtn('🏠 Home Screen', WallpaperManagerFlutter.HOME_SCREEN),
          const SizedBox(height: 10),
          _locationBtn('🔒 Lock Screen', WallpaperManagerFlutter.LOCK_SCREEN),
          const SizedBox(height: 10),
          _locationBtn('📱 Home + Lock Screen', WallpaperManagerFlutter.BOTH_SCREENS),
        ]),
      ),
    );
  }

  Widget _locationBtn(String label, int loc) => GestureDetector(
    onTap: () { Navigator.pop(context); _setWallpaper(loc); },
    child: Container(
      width: double.infinity, height: 52,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      alignment: Alignment.center,
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
    ),
  );

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFF050508),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF00FFC8))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF050508),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
          onPressed: () => context.go('/home'),
        ),
        title: Text('Wallpaper Kamu', style: GoogleFonts.syne(fontWeight: FontWeight.w700, color: Colors.white)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
        child: Column(children: [

          // ── Success badge ──────────────────────────────────────────
          if (_wallSet)
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 500),
            curve: Curves.elasticOut,
            builder: (_, v, child) => Transform.scale(scale: v, child: child),
            child: Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF00FFC8).withOpacity(.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF00FFC8).withOpacity(.2)),
              ),
              child: Row(children: [
                const Text('🎉', style: TextStyle(fontSize: 28)),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Wallpaper Terpasang!', style: GoogleFonts.syne(fontWeight: FontWeight.w800, fontSize: 15, color: Colors.white)),
                  const Text('Live wallpaper kamu sudah aktif.', style: TextStyle(color: Color(0xFF6B6B80), fontSize: 12)),
                ])),
              ]),
            ),
          ),

          // ── Order info ─────────────────────────────────────────────
          if (_order != null)
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF111118),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(.07)),
            ),
            padding: const EdgeInsets.all(22),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_order!.productName,
                style: GoogleFonts.syne(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
              const SizedBox(height: 6),
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00FFC8).withOpacity(.1),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: const Text('✅ Lunas',
                    style: TextStyle(color: Color(0xFF00FFC8), fontSize: 11, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 8),
                Text(_order!.formattedAmount,
                  style: const TextStyle(color: Color(0xFF00FFC8), fontSize: 13, fontWeight: FontWeight.w700)),
              ]),
              if (_order!.tokenExpires != null) ...[
                const SizedBox(height: 12),
                const Divider(color: Colors.white10),
                const SizedBox(height: 10),
                Row(children: [
                  const Icon(Icons.schedule_rounded, color: Color(0xFF6B6B80), size: 14),
                  const SizedBox(width: 6),
                  Text(
                    _order!.isExpired
                      ? 'Akses sudah kadaluarsa'
                      : 'Aktif hingga ${_fmtDate(_order!.tokenExpires!)}',
                    style: TextStyle(
                      color: _order!.isExpired ? const Color(0xFFFF4466) : const Color(0xFF6B6B80),
                      fontSize: 12,
                    ),
                  ),
                ]),
              ],
            ]),
          ),

          const SizedBox(height: 16),

          // ── Set Wallpaper Button ───────────────────────────────────
          if (_order?.canAccess ?? false) ...[
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(.2)),
                ),
                child: Text(_error!, style: const TextStyle(color: Color(0xFFFF8899), fontSize: 13)),
              ),
              const SizedBox(height: 14),
            ],

            if (_settingWall)
              Column(children: [
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: _wallProgress / 100,
                  backgroundColor: Colors.white.withOpacity(.05),
                  valueColor: const AlwaysStoppedAnimation(Color(0xFF00FFC8)),
                  borderRadius: BorderRadius.circular(100),
                  minHeight: 4,
                ),
                const SizedBox(height: 12),
                Text('Memasang wallpaper... $_wallProgress%',
                  style: const TextStyle(color: Color(0xFF6B6B80), fontSize: 13)),
                const SizedBox(height: 16),
              ])
            else
              GestureDetector(
                onTap: _streamUrl != null ? _showLocationPicker : null,
                child: Container(
                  width: double.infinity, height: 56,
                  decoration: BoxDecoration(
                    color: _streamUrl != null ? const Color(0xFF00FFC8) : Colors.white.withOpacity(.1),
                    borderRadius: BorderRadius.circular(100),
                    boxShadow: _streamUrl != null ? [
                      BoxShadow(color: const Color(0xFF00FFC8).withOpacity(.3), blurRadius: 20, offset: const Offset(0, 8))
                    ] : null,
                  ),
                  alignment: Alignment.center,
                  child: _streamUrl == null
                    ? const Row(mainAxisSize: MainAxisSize.min, children: [
                        SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white54)),
                        SizedBox(width: 10),
                        Text('Memuat wallpaper...', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.w600)),
                      ])
                    : Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.wallpaper_rounded, color: Colors.black, size: 20),
                        const SizedBox(width: 8),
                        Text('Pasang Wallpaper', style: GoogleFonts.syne(color: Colors.black, fontWeight: FontWeight.w700, fontSize: 15)),
                      ]),
                ),
              ),

            const SizedBox(height: 20),

            // Installation guide
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF111118),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(.07)),
              ),
              padding: const EdgeInsets.all(18),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Panduan', style: GoogleFonts.syne(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.white)),
                const SizedBox(height: 12),
                ...[
                  'Tap tombol "Pasang Wallpaper" di atas',
                  'Pilih lokasi: Home, Lock, atau keduanya',
                  'Tunggu beberapa detik — wallpaper aktif!',
                  'Cek HP kamu — live wallpaper sudah berjalan 🎉',
                ].asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(
                      width: 22, height: 22,
                      decoration: BoxDecoration(
                        color: const Color(0xFF00FFC8).withOpacity(.1), shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: Text('${e.key + 1}',
                        style: const TextStyle(color: Color(0xFF00FFC8), fontSize: 11, fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(e.value, style: const TextStyle(color: Color(0xFF9B9BAA), fontSize: 12, height: 1.5))),
                  ]),
                )),
              ]),
            ),
          ] else if (_order?.isExpired ?? false) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red.withOpacity(.2)),
              ),
              child: Column(children: [
                const Text('⏰', style: TextStyle(fontSize: 40)),
                const SizedBox(height: 12),
                const Text('Akses Kadaluarsa', style: TextStyle(fontFamily: 'Syne', fontWeight: FontWeight.w800, fontSize: 18, color: Colors.white)),
                const SizedBox(height: 8),
                const Text('Hubungi admin untuk perpanjangan akses.',
                  style: TextStyle(color: Color(0xFF6B6B80), fontSize: 13), textAlign: TextAlign.center),
              ]),
            ),
          ],

          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => context.go('/home'),
            child: const Text('← Kembali ke Toko', style: TextStyle(color: Color(0xFF6B6B80), fontSize: 13)),
          ),
        ]),
      ),
    );
  }

  String _fmtDate(DateTime d) {
    const months = ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Agu','Sep','Okt','Nov','Des'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}
