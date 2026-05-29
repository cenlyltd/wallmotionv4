import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/models.dart';
import '../../services/product_service.dart';
import '../../widgets/widgets.dart';
import '../profile/profile_screen.dart';
import '../profile/orders_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _navIdx = 0;

  final _pages = const [_StorePage(), OrdersScreen(), ProfileScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050508),
      body: _pages[_navIdx],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0A0A10),
          border: Border(
              top: BorderSide(color: Colors.white.withOpacity(.07))),
        ),
        child: BottomNavigationBar(
          currentIndex: _navIdx,
          onTap: (i) => setState(() => _navIdx = i),
          backgroundColor: Colors.transparent,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.home_rounded), label: 'Toko'),
            BottomNavigationBarItem(
                icon: Icon(Icons.receipt_long_rounded),
                label: 'Pembelian'),
            BottomNavigationBarItem(
                icon: Icon(Icons.person_rounded), label: 'Profil'),
          ],
        ),
      ),
    );
  }
}

class _StorePage extends StatelessWidget {
  const _StorePage();

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          backgroundColor: const Color(0xFF050508),
          expandedHeight: 160,
          floating: true,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF050508), Color(0xFF0D0D18)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: const TextSpan(
                      style: TextStyle(
                        fontFamily: 'Syne',
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                      children: [
                        TextSpan(text: 'Wall'),
                        TextSpan(
                          text: 'Motion',
                          style: TextStyle(color: Color(0xFF00FFC8)),
                        ),
                      ],
                    ),
                  ),
                  const Text(
                    'Live Wallpaper Premium untuk Android',
                    style: TextStyle(
                        color: Color(0xFF6B6B80), fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
        StreamBuilder<List<ProductModel>>(
          stream: context.read<ProductService>().productsStream,
          builder: (context, snap) {
            if (snap.hasError) {
              return SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Text('Error: ${snap.error}',
                        style: const TextStyle(color: Colors.red)),
                  ),
                ),
              );
            }

            if (!snap.hasData) {
              return SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _shimmerCard(),
                    childCount: 4,
                  ),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: .6,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                ),
              );
            }

            final products = snap.data!;
            if (products.isEmpty) {
              return const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(60),
                    child: Column(children: [
                      Text('🎨', style: TextStyle(fontSize: 48)),
                      SizedBox(height: 12),
                      Text(
                        'Koleksi segera hadir!',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      Text('Pantau terus ya',
                          style: TextStyle(
                              color: Color(0xFF6B6B80), fontSize: 13)),
                    ]),
                  ),
                ),
              );
            }

            return SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => ProductCard(
                    product: products[i],
                    onTap: () =>
                        context.go('/home/detail/${products[i].id}'),
                  ),
                  childCount: products.length,
                ),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: .58,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _shimmerCard() => Shimmer.fromColors(
        baseColor: const Color(0xFF111118),
        highlightColor: const Color(0xFF1A1A24),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF111118),
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
}
