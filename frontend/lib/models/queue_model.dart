import 'package:cloud_firestore/cloud_firestore.dart';

class QueueModel {
  final String id;
  final String eventId;
  final String name;
  final int totalStrips;
  final int totalPayment;
  final String paymentMethod; // "QRIS" / "Cash" / "Split"
  final Map<String, dynamic>? splitPayments; // e.g. {"QRIS": 10000, "Cash": 10000}
  final String status; // "MENUNGGU" / "SELESAI" / "BATAL"
  final String type; // 'Booth' / 'Aksesoris'
  final List<Map<String, dynamic>>? items; // For Accessories cart items
  final bool isPinned;
  final String? kasirName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  QueueModel({
    required this.id,
    required this.eventId,
    required this.name,
    required this.totalStrips,
    required this.totalPayment,
    required this.paymentMethod,
    this.splitPayments,
    required this.status,
    this.type = 'Booth',
    this.items,
    this.isPinned = false,
    this.kasirName,
    this.createdAt,
    this.updatedAt,
  });

  factory QueueModel.fromMap(Map<String, dynamic> data, String documentId) {
    return QueueModel(
      id: documentId,
      eventId: data['event_id'] ?? '',
      name: data['name'] ?? '',
      totalStrips: data['total_strips'] ?? 0,
      totalPayment: data['total_payment'] ?? 0,
      paymentMethod: data['payment_method'] ?? 'Cash',
      splitPayments: data['split_payments'] != null ? Map<String, dynamic>.from(data['split_payments']) : null,
      status: data['status'] ?? 'MENUNGGU',
      type: data['type'] ?? 'Booth',
      items: data['items'] != null ? List<Map<String, dynamic>>.from(data['items']) : null,
      isPinned: data['is_pinned'] ?? false,
      kasirName: data['kasir_name'] as String?,
      createdAt: (data['created_at'] as Timestamp?)?.toDate(),
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'event_id': eventId,
      'name': name,
      'total_strips': totalStrips,
      'total_payment': totalPayment,
      'payment_method': paymentMethod,
      if (splitPayments != null) 'split_payments': splitPayments,
      'status': status,
      'type': type,
      if (items != null) 'items': items,
      'is_pinned': isPinned,
      'kasir_name': kasirName,
      'created_at': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updated_at': updatedAt != null ? Timestamp.fromDate(updatedAt!) : FieldValue.serverTimestamp(),
    };
  }

  QueueModel copyWith({
    String? id,
    String? eventId,
    String? name,
    int? totalStrips,
    int? totalPayment,
    String? paymentMethod,
    Map<String, dynamic>? splitPayments,
    String? status,
    String? type,
    List<Map<String, dynamic>>? items,
    bool? isPinned,
    String? kasirName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return QueueModel(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      name: name ?? this.name,
      totalStrips: totalStrips ?? this.totalStrips,
      totalPayment: totalPayment ?? this.totalPayment,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      splitPayments: splitPayments ?? this.splitPayments,
      status: status ?? this.status,
      type: type ?? this.type,
      items: items ?? this.items,
      isPinned: isPinned ?? this.isPinned,
      kasirName: kasirName ?? this.kasirName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
