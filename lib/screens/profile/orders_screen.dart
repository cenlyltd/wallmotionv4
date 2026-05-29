import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/models.dart';
import '../../services/auth_service.dart';
import '../../services/order_service.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().user;

    return Scaffold(
      backgroundColor: const Color(0xFF050508),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Pembelian Saya',
          style: GoogleFonts.syne(
              fontWeight: FontWeight.w800, color: Colors.white),
        ),
      ),
      body: user == null
          ? const Center(
              child: Text('Silakan login dulu.',
                  style: TextStyle(color: Color(0xFF6B6B80))))
          : StreamBuilder<List<OrderModel>>(
              stream: context
                  .read<OrderService>()
                  .userOrdersStream(user.uid),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFF00FFC8), strokeWidth: 2),
                  );
                }
                final orders = snap.data!;
                if (orders.isEmpty) return _emptyState(context);
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                  itemCount: orders.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: 10),
                  itemBuilder: (_, i) =>
                      _orderCard(context, orders[i]),
                );
              },
            ),
    );
  }

  Widget _emptyState(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('📦', style: TextStyle(fontSize: 52)),
            const SizedBox(height: 16),
            Text(
              'Belum ada pembelian',
              style: GoogleFonts.syne(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white),
            ),
            const SizedBox(height: 8),
            const Text(
              'Yuk lihat koleksi wallpaper kami!',
              style: TextStyle(color: Color(0xFF6B6B80), fontSize: 13),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () => context.go('/home'),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 13),
                decoration: BoxDecoration(
                  color: const Color(0xFF00FFC8),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  'Lihat Koleksi →',
                  style: GoogleFonts.syne(
                      color: Colors.black, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _orderCard(BuildContext context, OrderModel order) {
    final statusColor = switch (order.status) {
      'paid'            => const Color(0xFF00FFC8),
      'pending_payment' => Colors.orange,
      _                 => const Color(0xFFFF4466),
    };

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111118),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(.07)),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  order.productName,
                  style: GoogleFonts.syne(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Colors.white),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(.1),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  order.statusLabel,
                  style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '#${order.id.length > 8 ? order.id.substring(0, 8) : order.id}',
            style: const TextStyle(
                color: Color(0xFF6B6B80),
                fontSize: 11,
                fontFamily: 'monospace'),
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.white10),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                order.formattedAmount,
                style: GoogleFonts.syne(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF00FFC8)),
              ),
              const Spacer(),
              if (order.canAccess)
                GestureDetector(
                  onTap: () =>
                      context.go('/home/access/${order.id}'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00FFC8),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.wallpaper_rounded,
                            color: Colors.black, size: 14),
                        const SizedBox(width: 5),
                        Text(
                          'Akses',
                          style: GoogleFonts.syne(
                              color: Colors.black,
                              fontWeight: FontWeight.w700,
                              fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                )
              else if (order.isPending)
                GestureDetector(
                  onTap: () =>
                      context.go('/home/payment/${order.id}'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(.15),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                          color: Colors.orange.withOpacity(.3)),
                    ),
                    child: const Text(
                      'Lanjut Bayar',
                      style: TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.w600,
                          fontSize: 12),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
