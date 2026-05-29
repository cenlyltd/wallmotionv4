import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';

class ProductService extends ChangeNotifier {
  final _db = FirebaseFirestore.instance;

  Stream<List<ProductModel>> get productsStream {
    return _db
        .collection('products')
        .where('active', isEqualTo: true)
        .orderBy('featured', descending: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(ProductModel.fromDoc).toList());
  }

  Future<ProductModel?> getProduct(String id) async {
    final doc = await _db.collection('products').doc(id).get();
    if (!doc.exists) return null;
    return ProductModel.fromDoc(doc);
  }
}
