// ── models/product_model.dart ─────────────────────────────────────────────
import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModel {
  final String id;
  final String name;
  final String description;
  final int price;
  final int? originalPrice;
  final List<String> tags;
  final String? previewUrl;  // Firebase Storage URL (preview, watermarked)
  final String? hdStoragePath; // Storage path (tidak di-expose ke client)
  final String color;
  final bool featured;
  final bool active;
  final DateTime createdAt;

  const ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.originalPrice,
    required this.tags,
    this.previewUrl,
    this.hdStoragePath,
    required this.color,
    required this.featured,
    required this.active,
    required this.createdAt,
  });

  factory ProductModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ProductModel(
      id:            doc.id,
      name:          d['name']          ?? '',
      description:   d['description']   ?? '',
      price:         d['price']         ?? 0,
      originalPrice: d['originalPrice'],
      tags:          List<String>.from(d['tags'] ?? []),
      previewUrl:    d['previewUrl'],
      hdStoragePath: d['hdStoragePath'],
      color:         d['color']         ?? 'neon',
      featured:      d['featured']      ?? false,
      active:        d['active']        ?? true,
      createdAt:     (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  String get formattedPrice {
    return 'Rp ${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  String? get formattedOriginalPrice {
    if (originalPrice == null) return null;
    return 'Rp ${originalPrice.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  int get discountPercent {
    if (originalPrice == null || originalPrice! <= price) return 0;
    return ((originalPrice! - price) / originalPrice! * 100).round();
  }
}

// ── models/order_model.dart ───────────────────────────────────────────────
class OrderModel {
  final String id;
  final String userId;
  final String productId;
  final String productName;
  final int amount;
  final String status; // pending_payment | paid | failed | expired
  final String? midtransOrderId;
  final String? qrisUrl;
  final DateTime? qrisExpires;
  final String? accessToken;
  final DateTime? tokenExpires;
  final DateTime createdAt;
  final DateTime? paidAt;

  const OrderModel({
    required this.id,
    required this.userId,
    required this.productId,
    required this.productName,
    required this.amount,
    required this.status,
    this.midtransOrderId,
    this.qrisUrl,
    this.qrisExpires,
    this.accessToken,
    this.tokenExpires,
    required this.createdAt,
    this.paidAt,
  });

  factory OrderModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return OrderModel(
      id:              doc.id,
      userId:          d['userId']          ?? '',
      productId:       d['productId']       ?? '',
      productName:     d['productName']     ?? '',
      amount:          d['amount']          ?? 0,
      status:          d['status']          ?? 'pending_payment',
      midtransOrderId: d['midtransOrderId'],
      qrisUrl:         d['qrisUrl'],
      qrisExpires:     (d['qrisExpires'] as Timestamp?)?.toDate(),
      accessToken:     d['accessToken'],
      tokenExpires:    (d['tokenExpires'] as Timestamp?)?.toDate(),
      createdAt:       (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      paidAt:          (d['paidAt'] as Timestamp?)?.toDate(),
    );
  }

  bool get isPaid      => status == 'paid';
  bool get isPending   => status == 'pending_payment';
  bool get isExpired   => tokenExpires != null && tokenExpires!.isBefore(DateTime.now());
  bool get canAccess   => isPaid && !isExpired;

  String get statusLabel => switch (status) {
    'paid'            => 'Lunas',
    'pending_payment' => 'Menunggu Bayar',
    'failed'          => 'Gagal',
    'expired'         => 'Kadaluarsa',
    _                 => status,
  };

  String get formattedAmount {
    return 'Rp ${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }
}

// ── models/user_model.dart ────────────────────────────────────────────────
class UserModel {
  final String uid;
  final String name;
  final String email;
  final String? phone;
  final bool emailVerified;
  final DateTime createdAt;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.phone,
    required this.emailVerified,
    required this.createdAt,
  });

  factory UserModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid:           doc.id,
      name:          d['name']          ?? '',
      email:         d['email']         ?? '',
      phone:         d['phone'],
      emailVerified: d['emailVerified'] ?? false,
      createdAt:     (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
