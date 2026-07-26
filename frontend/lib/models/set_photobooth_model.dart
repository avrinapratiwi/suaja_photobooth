import 'package:cloud_firestore/cloud_firestore.dart';

class SetPhotoboothModel {
  final String id;
  final String name;
  final int qty;
  final DateTime? updatedAt;

  SetPhotoboothModel({
    required this.id,
    required this.name,
    required this.qty,
    this.updatedAt,
  });

  factory SetPhotoboothModel.fromMap(Map<String, dynamic> data, String documentId) {
    return SetPhotoboothModel(
      id: documentId,
      name: data['name'] ?? '',
      qty: data['qty'] ?? 0,
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'qty': qty,
      'updated_at': updatedAt != null ? Timestamp.fromDate(updatedAt!) : FieldValue.serverTimestamp(),
    };
  }

  SetPhotoboothModel copyWith({
    String? id,
    String? name,
    int? qty,
    DateTime? updatedAt,
  }) {
    return SetPhotoboothModel(
      id: id ?? this.id,
      name: name ?? this.name,
      qty: qty ?? this.qty,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
