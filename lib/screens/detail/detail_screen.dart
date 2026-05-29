import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/models.dart';
import '../../services/product_service.dart';
import '../../services/auth_service.dart';
import '../../services/order_service.dart';
import '../../widgets/widgets.dart';

class DetailScreen extends StatefulWidget {
  final String productId;
  const DetailScreen({super.key, required this.productId});
  @override State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  ProductModel? _product;
  bool _loading    = true;
  bool _buying     = false;
  String? _error;
  VideoPlayerController? _videoCtrl;

  static const _gradients = {
    'neon':   [Color(0xFF00FFC8), Color(0xFF000510)],
    'purple': [Color(0xFF7B5CFF), Color(0xFF050508)],
    'fire':   [Color(0xFFFF6B00), Color(0xFF050508)],
    'ocean':  [Color(0xFF0099FF), Color(0xFF003366)],
    'galaxy': [Color(0xFFFF00AA), Color(0xFF7B5CFF)],
    'gold':   [Color(0xFFFFD700), Color(0xFF050508)],
  };

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    final p = await context.read<ProductService>().getProduct(widget.productId);
    if (!mounted) return;
    setState(() { _product = p; _loading = false; });
    if (p?.previewUrl != null) _initVideo(p!.previewUrl!);
  }

  void _initVideo(String url) {
    _videoCtrl = VideoPlayerController.networkUrl(Uri.parse(url))
      ..initialize().then((_) {
        if (mounted) {
          _videoCtrl!.setLooping(true);
          _videoCtrl!.setVolume(0);
          _videoCtrl!.play();
          setState(() {});
        }
      });
  }

  Future<void> _buy() async {
    final auth  = context.read<AuthService>();
    final order = context.read<OrderService>();
    final user  = auth.user;
    if (user == null || _product == null) return;

    setState(() { _buying = true; _error = null; });
    try {
      final result = await order.createOrder(
        productId:  _product!.id,
        userId:     user.uid,
        buyerName:  user.name,
        buyerEmail: user.email,
      );
      if (mounted) context.go('/home/payment/${result['orderId']}',
        extra: {'qrisUrl': result['qrisUrl'], 'amount': result['amount']});
    } catch (e) {
      setState(() { _error = 'Gagal membuat order. Coba lagi.'; });
    } finally {
      if (mounted) setState(() => _buying = false);
    }
  }

  @override
  void dispose() {
    _videoCtrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFF050508),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF00FFC8))),
      );
    }
    if (_product == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF050508),
        appBar: AppBar(backgroundColor: Colors.transparent),
        body: const Center(child: Text('Produk tidak ditemukan', style: TextStyle(color: Colors.white))),
      );
    }

    final p      = _product!;
    final colors = _gradients[p.color] ?? _gradients['neon']!;

    return Scaffold(
      backgroundColor: const Color(0xFF050508),
      body: Stack(
        children: [
          // ── Fullscreen Preview ──────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: MediaQuery.of(context).size.height * .65,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (_videoCtrl != null && _videoCtrl!.value.isInitialized)
                  VideoPlayer(_videoCtrl!)
                else
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: colors,
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                    ),
                  ),
                // Watermark overlay
                Positioned.fill(
                  child: Opacity(
                    opacity: .15,
                    child: RepaintBoundary(
                      child: CustomPaint(painter: _WatermarkPainter()),
                    ),
                  ),
                ),
                // Gradient fade bottom
                Positioned(
                  bottom: 0, left: 0, right: 0, height: 180,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.transparent, const Color(0xFF050508)],
                        begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Back button ─────────────────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 8, left: 16,
            child: GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: Colors.black54, borderRadius: BorderRadius.circular(100)),
                child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
              ),
            ),
          ),

          // ── Content ──────────────────────────────────────────────────
          DraggableScrollableSheet(
            initialChildSize: .45,
            minChildSize: .45,
            maxChildSize: .92,
            builder: (_, ctrl) => Container(
              decoration: const BoxDecoration(
                color: Color(0xFF050508),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: ListView(
                controller: ctrl,
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 36, height: 4,
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white12, borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Tags
                  if (p.tags.isNotEmpty)
                  Wrap(
                    spacing: 6, runSpacing: 6,
                    children: [
                      if (p.featured)
                        _tag('⚡ Viral', accent: true),
                      ...p.tags.map((t) => _tag(t)),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Name & price
                  Text(p.name, style: GoogleFonts.syne(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(p.formattedPrice,
                        style: GoogleFonts.syne(fontSize: 24, fontWeight: FontWeight.w800, color: const Color(0xFF00FFC8))),
                      if (p.originalPrice != null) ...[
                        const SizedBox(width: 10),
                        Text(p.formattedOriginalPrice!,
                          style: const TextStyle(color: Color(0xFF6B6B80), fontSize: 14, decoration: TextDecoration.lineThrough)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00FFC8).withOpacity(.1),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text('-${p.discountPercent}%',
                            style: const TextStyle(color: Color(0xFF00FFC8), fontSize: 11, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ],
                  ),

                  if (p.description.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Divider(color: Colors.white10),
                    const SizedBox(height: 14),
                    Text(p.description,
                      style: const TextStyle(color: Color(0xFF9B9BAA), fontSize: 14, height: 1.7)),
                  ],

                  const SizedBox(height: 20),
                  const Divider(color: Colors.white10),
                  const SizedBox(height: 14),

                  // Features
                  _featureRow(Icons.hd_rounded,         'Kualitas 4K HD'),
                  _featureRow(Icons.lock_outline_rounded,'File asli terlindungi'),
                  _featureRow(Icons.wallpaper_rounded,  'Pasang langsung dari app'),
                  _featureRow(Icons.qr_code_rounded,    'Bayar via QRIS'),

                  const SizedBox(height: 28),
                  if (_error != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.red.withOpacity(.2)),
                      ),
                      child: Text(_error!, style: const TextStyle(color: Color(0xFFFF8899), fontSize: 13)),
                    ),
                    const SizedBox(height: 14),
                  ],
                  WMButton(label: 'Beli Sekarang — ${p.formattedPrice}', onTap: _buy, loading: _buying),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tag(String label, {bool accent = false}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: accent ? const Color(0xFF00FFC8).withOpacity(.1) : Colors.white.withOpacity(.05),
      borderRadius: BorderRadius.circular(100),
      border: Border.all(color: accent ? const Color(0xFF00FFC8).withOpacity(.3) : Colors.white12),
    ),
    child: Text(label,
      style: TextStyle(
        color: accent ? const Color(0xFF00FFC8) : const Color(0xFF9B9BAA),
        fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1,
      ),
    ),
  );

  Widget _featureRow(IconData icon, String label) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(children: [
      Icon(icon, color: const Color(0xFF00FFC8), size: 18),
      const SizedBox(width: 10),
      Text(label, style: const TextStyle(color: Color(0xFF9B9BAA), fontSize: 13)),
    ]),
  );
}

class _WatermarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final tp = TextPainter(
      text: const TextSpan(text: '© WallMotion',
        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 3)),
      textDirection: TextDirection.ltr,
    )..layout();
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(-0.5);
    tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
    canvas.restore();
  }
  @override bool shouldRepaint(_) => false;
}
