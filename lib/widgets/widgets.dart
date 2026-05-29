// ── widgets/wm_button.dart ────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WMButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool loading;
  final bool outline;
  final Color? color;
  final double height;

  const WMButton({
    super.key,
    required this.label,
    this.onTap,
    this.loading = false,
    this.outline  = false,
    this.color,
    this.height = 52,
  });

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final bg     = outline ? Colors.transparent : (color ?? accent);
    final fg     = outline ? Colors.white60 : Colors.black;

    return GestureDetector(
      onTap: loading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: height,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(100),
          border: outline ? Border.all(color: Colors.white12) : null,
          boxShadow: outline ? null : [
            BoxShadow(color: accent.withOpacity(.25), blurRadius: 20, offset: const Offset(0, 8)),
          ],
        ),
        alignment: Alignment.center,
        child: loading
          ? SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: fg))
          : Text(label, style: GoogleFonts.syne(fontSize: 15, fontWeight: FontWeight.w700, color: fg)),
      ),
    );
  }
}

// ── widgets/wm_text_field.dart ────────────────────────────────────────────
class WMTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final bool obscure;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final Widget? suffix;

  const WMTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.obscure = false,
    this.keyboardType,
    this.validator,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(),
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: Color(0xFF6B6B80))),
        const SizedBox(height: 7),
        TextFormField(
          controller:   controller,
          obscureText:  obscure,
          keyboardType: keyboardType,
          validator:    validator,
          style: const TextStyle(color: Color(0xFFF0F0F8), fontSize: 14),
          decoration: InputDecoration(hintText: hint, suffixIcon: suffix),
        ),
      ],
    );
  }
}

// ── widgets/product_card.dart ─────────────────────────────────────────────
import 'package:video_player/video_player.dart';
import '../models/models.dart';

class ProductCard extends StatefulWidget {
  final ProductModel product;
  final VoidCallback onTap;

  const ProductCard({super.key, required this.product, required this.onTap});

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  VideoPlayerController? _ctrl;

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
    if (widget.product.previewUrl != null) {
      _ctrl = VideoPlayerController.networkUrl(Uri.parse(widget.product.previewUrl!))
        ..initialize().then((_) {
          if (mounted) {
            _ctrl!.setLooping(true);
            _ctrl!.setVolume(0);
            _ctrl!.play();
            setState(() {});
          }
        });
    }
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = _gradients[widget.product.color] ?? _gradients['neon']!;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF111118),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(.07)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Preview ──────────────────────────────────────────────
            Expanded(
              flex: 7,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Video or animated gradient
                    if (_ctrl != null && _ctrl!.value.isInitialized)
                      VideoPlayer(_ctrl!)
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
                    // Watermark
                    Positioned.fill(
                      child: Opacity(
                        opacity: .18,
                        child: Center(
                          child: Transform.rotate(
                            angle: -0.5,
                            child: Text('© WallMotion',
                              style: const TextStyle(
                                color: Colors.white, fontSize: 11,
                                fontWeight: FontWeight.w700, letterSpacing: 3,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Lock badge
                    Positioned(
                      bottom: 0, left: 0, right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 7),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.transparent, Colors.black.withOpacity(.7)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.lock_outline, size: 10, color: Colors.white54),
                            SizedBox(width: 4),
                            Text('Preview', style: TextStyle(color: Colors.white54, fontSize: 9, letterSpacing: 1)),
                          ],
                        ),
                      ),
                    ),
                    // Featured badge
                    if (widget.product.featured)
                    Positioned(
                      top: 8, left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00FFC8).withOpacity(.2),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(color: const Color(0xFF00FFC8).withOpacity(.4)),
                        ),
                        child: const Text('⚡ Viral',
                          style: TextStyle(color: Color(0xFF00FFC8), fontSize: 9, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Info ─────────────────────────────────────────────────
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.product.name,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.white),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                    const Spacer(),
                    Row(
                      children: [
                        Text(widget.product.formattedPrice,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF00FFC8))),
                        const Spacer(),
                        GestureDetector(
                          onTap: widget.onTap,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00FFC8),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: const Text('Beli',
                              style: TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
