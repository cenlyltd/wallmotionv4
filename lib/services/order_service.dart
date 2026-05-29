import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/models.dart';

class OrderService extends ChangeNotifier {
  final _db        = FirebaseFirestore.instance;
  final _functions = FirebaseFunctions.instanceFor(region: 'asia-southeast1');

  // ── Create order via Cloud Function ─────────────────────────────────
  Future<Map<String, dynamic>> createOrder({
    required String productId,
    required String userId,
    required String buyerName,
    required String buyerEmail,
  }) async {
    final fn  = _functions.httpsCallable('createOrder');
    final res = await fn.call({
      'productId':  productId,
      'userId':     userId,
      'buyerName':  buyerName,
      'buyerEmail': buyerEmail,
    });
    return Map<String, dynamic>.from(res.data as Map);
  }

  // ── Real-time order stream ────────────────────────────────────────────
  Stream<OrderModel?> orderStream(String orderId) {
    return _db
        .collection('orders')
        .doc(orderId)
        .snapshots()
        .map((doc) => doc.exists ? OrderModel.fromDoc(doc) : null);
  }

  // ── User orders ───────────────────────────────────────────────────────
  Stream<List<OrderModel>> userOrdersStream(String userId) {
    return _db
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map(OrderModel.fromDoc).toList());
  }

  // ── Get signed stream URL via Cloud Function ──────────────────────────
  Future<String> getWallpaperStreamUrl(String orderId) async {
    final fn  = _functions.httpsCallable('getWallpaperUrl');
    final res = await fn.call({'orderId': orderId});
    return (res.data as Map)['url'] as String;
  }
}
