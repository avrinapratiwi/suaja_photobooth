import 'package:cloud_firestore/cloud_firestore.dart';

class AksesorisItemModel {
  final String id;
  final String name;
  final int price;
  final int stock;
  final DateTime? updatedAt;

  AksesorisItemModel({
    required this.id,
    required this.name,
    required this.price,
    required this.stock,
    this.updatedAt,
  });

  factory AksesorisItemModel.fromMap(Map<String, dynamic> data, String documentId) {
    return AksesorisItemModel(
      id: documentId,
      name: data['name'] ?? '',
      price: data['price'] ?? 0,
      stock: data['stock'] ?? 0,
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'stock': stock,
      'updated_at': updatedAt != null ? Timestamp.fromDate(updatedAt!) : FieldValue.serverTimestamp(),
    };
  }

  AksesorisItemModel copyWith({
    String? id,
    String? name,
    int? price,
    int? stock,
    DateTime? updatedAt,
  }) {
    return AksesorisItemModel(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// Dummy data for Katalog Aksesoris
final List<AksesorisItemModel> dummyAksesorisItems = [
  AksesorisItemModel(id: 'a1', name: 'Frame Minimalis Putih', price: 50000, stock: 15, updatedAt: DateTime(2026, 7, 23, 12, 30)),
  AksesorisItemModel(id: 'a2', name: 'Frame Minimalis Hitam', price: 50000, stock: 12, updatedAt: DateTime(2026, 7, 23, 13, 00)),
  AksesorisItemModel(id: 'a3', name: 'Stiker Lucu Kucing', price: 15000, stock: 50, updatedAt: DateTime(2026, 7, 24, 9, 15)),
  AksesorisItemModel(id: 'a4', name: 'Gantungan Kunci Kayu', price: 35000, stock: 30, updatedAt: DateTime(2026, 7, 24, 10, 45)),
];
