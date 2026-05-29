import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/models.dart';
import '../../services/order_service.dart';

class PaymentScreen extends StatefulWidget {
  final String orderId;
  const PaymentScreen({super.key, required this.orderId});
  @override State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> with WidgetsBindingObserver {
  StreamSubscription<OrderModel?>? _sub;
  OrderModel? _order;
  bool _paid = false;

  // Countdown
  Timer? _countdownTimer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _listenOrder();
  }

  void _listenOrder() {
    _sub = context.read<OrderService>()
        .orderStream(widget.orderId)
        .listen((order) {
      if (!mounted) return;
      setState(() => _order = order);

      if (order?.status == 'paid' && !_paid) {
        _paid = true;
        _onPaid();
      }

      if (order?.qrisExpires != null) {
        _startCountdown(order!.qrisExpires!);
      }
    });
  }

  void _startCountdown(DateTime expires) {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final rem = expires.difference(DateTime.now());
      if (!mounted) return;
      setState(() => _remaining = rem.isNegative ? Duration.zero : rem);
      if (_remaining == Duration.zero) _countdownTimer?.cancel();
    });
  }

  void _onPaid() {
    HapticFeedback.heavyImpact();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) context.go('/home/access/${widget.orderId}');
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sub?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  String _fmtDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050508),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _paid ? null : IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
          onPressed: () => context.pop(),
        ),
        title: Text('Pembayaran', style: GoogleFonts.syne(fontWeight: FontWeight.w700, color: Colors.white)),
        centerTitle: true,
      ),
      body: _paid ? _buildPaidUI() : _buildQrisUI(),
    );
  }

  Widget _buildPaidUI() {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 600),
          curve: Curves.elasticOut,
          builder: (_, v, child) => Transform.scale(scale: v, child: child),
          child: Container(
            width: 100, height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFF00FFC8).withOpacity(.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_rounded, color: Color(0xFF00FFC8), size: 64),
          ),
        ),
        const SizedBox(height: 24),
        Text('Pembayaran Lunas!', style: GoogleFonts.syne(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
        const SizedBox(height: 8),
        const Text('Menuju akses wallpaper...', style: TextStyle(color: Color(0xFF6B6B80))),
        const SizedBox(height: 24),
        const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00FFC8))),
      ]),
    );
  }

  Widget _buildQrisUI() {
    final order = _order;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
      child: Column(children: [

        // Step indicator
        _stepBar(),
        const SizedBox(height: 24),

        // QRIS Card
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF111118),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(.07)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(children: [
            Text('Scan QRIS',
              style: GoogleFonts.syne(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.white)),
            const SizedBox(height: 20),

            // QR Image
            if (order?.qrisUrl != null)
              Container(
                width: 220, height: 220,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.all(12),
                child: order!.qrisUrl!.startsWith('http')
                  ? CachedNetworkImage(imageUrl: order.qrisUrl!, fit: BoxFit.contain)
                  : Image.network(
                      'https://api.qrserver.com/v1/create-qr-code/?size=196x196&data=${Uri.encodeComponent(order.qrisUrl!)}',
                      fit: BoxFit.contain,
                    ),
              )
            else
              Container(
                width: 220, height: 220,
                decoration: BoxDecoration(color: Colors.white.withOpacity(.04), borderRadius: BorderRadius.circular(16)),
                child: const Center(child: CircularProgressIndicator(color: Color(0xFF00FFC8), strokeWidth: 2)),
              ),

            const SizedBox(height: 20),
            const Text('DANA · GoPay · OVO · LinkAja\nSemua m-banking didukung',
              style: TextStyle(color: Color(0xFF6B6B80), fontSize: 12, height: 1.6), textAlign: TextAlign.center),
            const SizedBox(height: 16),

            // Timer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(.08),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: Colors.orange.withOpacity(.2)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.timer_outlined, color: Colors.orange, size: 16),
                const SizedBox(width: 6),
                Text('Batas waktu: ${_fmtDuration(_remaining)}',
                  style: const TextStyle(color: Colors.orange, fontSize: 13, fontWeight: FontWeight.w700)),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 16),

        // Order info card
        if (order != null)
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF111118),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(.07)),
          ),
          padding: const EdgeInsets.all(18),
          child: Column(children: [
            _infoRow('Produk', order.productName),
            const SizedBox(height: 8),
            _infoRow('Total', order.formattedAmount, valueColor: const Color(0xFF00FFC8)),
            const SizedBox(height: 8),
            _infoRow('Status', 'Menunggu Pembayaran', valueColor: Colors.orange),
          ]),
        ),

        const SizedBox(height: 20),

        // Guide
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF111118),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(.07)),
          ),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Cara Bayar QRIS', style: GoogleFonts.syne(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.white)),
              const SizedBox(height: 12),
              ...[
                'Buka e-wallet atau m-banking kamu',
                'Pilih menu Bayar / Scan QR',
                'Arahkan kamera ke QR di atas',
                'Konfirmasi pembayaran — selesai!',
              ].asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(children: [
                  Container(
                    width: 22, height: 22,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00FFC8).withOpacity(.1),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text('${e.key + 1}',
                      style: const TextStyle(color: Color(0xFF00FFC8), fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(e.value, style: const TextStyle(color: Color(0xFF9B9BAA), fontSize: 12))),
                ]),
              )),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _stepBar() {
    return Row(children: [
      _dot(true, '✓'),
      _line(true),
      _dot(true, '2', active: true),
      _line(false),
      _dot(false, '3'),
    ]);
  }

  Widget _dot(bool done, String label, {bool active = false}) => Container(
    width: 28, height: 28,
    decoration: BoxDecoration(
      color: done ? (active ? const Color(0xFF00FFC8).withOpacity(.15) : const Color(0xFF00FFC8)) : Colors.white.withOpacity(.05),
      shape: BoxShape.circle,
      border: active ? Border.all(color: const Color(0xFF00FFC8), width: 1.5) : null,
    ),
    alignment: Alignment.center,
    child: Text(label,
      style: TextStyle(
        color: active ? const Color(0xFF00FFC8) : (done && !active ? Colors.black : Colors.white38),
        fontSize: 11, fontWeight: FontWeight.w700,
      )),
  );

  Widget _line(bool done) => Expanded(
    child: Container(height: 2, color: done ? const Color(0xFF00FFC8) : Colors.white12),
  );

  Widget _infoRow(String label, String val, {Color? valueColor}) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: const TextStyle(color: Color(0xFF6B6B80), fontSize: 13)),
      Text(val, style: TextStyle(color: valueColor ?? Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
    ],
  );
}
