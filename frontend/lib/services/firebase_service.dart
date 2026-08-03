import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/queue_model.dart';
import '../models/event_model.dart';
import '../models/aksesoris_item_model.dart';
import '../models/set_photobooth_model.dart';
import '../models/user_model.dart';
import '../utils/business_day_utils.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  
  bool _useDummyData = false;
  final StreamController<List<QueueModel>> _dummyStreamController = StreamController<List<QueueModel>>.broadcast();
  final StreamController<List<EventModel>> _dummyEventsStreamController = StreamController<List<EventModel>>.broadcast();
  final StreamController<List<AksesorisItemModel>> _dummyAccessoriesStreamController = StreamController<List<AksesorisItemModel>>.broadcast();

  FirebaseService._internal() {
    try {
      // Test if Firebase is initialized
      FirebaseFirestore.instance;
    } catch (e) {
      _useDummyData = true;
    }
  }

  final List<QueueModel> _dummyQueues = [
    QueueModel(id: 'dummy1', eventId: 'e2', name: 'BUDI SANTOSO', totalStrips: 2, totalPayment: 20000, paymentMethod: 'QRIS', status: 'MENUNGGU', createdAt: DateTime.now().subtract(const Duration(minutes: 10))),
    QueueModel(id: 'dummy2', eventId: 'e2', name: 'SITI AMINAH', totalStrips: 4, totalPayment: 25000, paymentMethod: 'Cash', status: 'MENUNGGU', createdAt: DateTime.now().subtract(const Duration(minutes: 5))),
    QueueModel(id: 'dummy3', eventId: 'e2', name: 'ANDI WIJAYA', totalStrips: 2, totalPayment: 20000, paymentMethod: 'QRIS', status: 'MENUNGGU', createdAt: DateTime.now().subtract(const Duration(minutes: 2))),
    // Demo SELESAI
    QueueModel(id: 'dummy4', eventId: 'e2', name: 'RINA MELATI', totalStrips: 6, totalPayment: 35000, paymentMethod: 'QRIS', status: 'SELESAI', createdAt: DateTime.now().subtract(const Duration(minutes: 30)), updatedAt: DateTime.now().subtract(const Duration(minutes: 15))),
    QueueModel(id: 'dummy5', eventId: 'e2', name: 'DEWA KETUT', totalStrips: 2, totalPayment: 20000, paymentMethod: 'Cash', status: 'SELESAI', createdAt: DateTime.now().subtract(const Duration(minutes: 45)), updatedAt: DateTime.now().subtract(const Duration(minutes: 25))),
    // Demo BATAL
    QueueModel(id: 'dummy6', eventId: 'e2', name: 'JOKO TINGKIR', totalStrips: 4, totalPayment: 25000, paymentMethod: 'QRIS', status: 'BATAL', createdAt: DateTime.now().subtract(const Duration(hours: 1)), updatedAt: DateTime.now().subtract(const Duration(minutes: 10))),
    // Demo Aksesoris SELESAI
    QueueModel(
      id: 'dummy_acc1', 
      eventId: 'e2',
      name: 'FITRI', 
      totalStrips: 0, 
      totalPayment: 150000, 
      paymentMethod: 'QRIS', 
      status: 'SELESAI', 
      type: 'Aksesoris',
      items: [
        {'type': 'Frame Minimalis', 'price': 50000, 'qty': 2},
        {'type': 'Stiker Lucu', 'price': 25000, 'qty': 2}
      ],
      createdAt: DateTime.now().subtract(const Duration(minutes: 5)), 
      updatedAt: DateTime.now().subtract(const Duration(minutes: 5))
    ),
  ];



  CollectionReference get _queueCollection =>
      FirebaseFirestore.instance.collection('queues');
  
  CollectionReference get _eventsCollection =>
      FirebaseFirestore.instance.collection('events');

  CollectionReference get _accessoriesCollection =>
      FirebaseFirestore.instance.collection('accessories');
  CollectionReference get _setPhotoboothCollection =>
      FirebaseFirestore.instance.collection('set_photobooth');

  CollectionReference get _usersCollection =>
      FirebaseFirestore.instance.collection('users');

  // Fetch all cashiers (users with role 'kasir')
  Future<List<UserModel>> getCashiers() async {
    if (_useDummyData) {
      return [
        UserModel(id: 'u1', name: 'Kasir Utama', password: '123', role: 'kasir'),
        UserModel(id: 'u2', name: 'Kasir Kedua', password: '123', role: 'kasir'),
      ];
    }
    try {
      final snapshot = await _usersCollection.where('role', isEqualTo: 'kasir').get();
      return snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Stream active queues for Kasir
  Stream<List<QueueModel>> get activeQueuesStream async* {
    if (_useDummyData) {
      yield _dummyQueues;
      yield* _dummyStreamController.stream;
      return;
    }
    
    try {
      yield* _queueCollection
          .orderBy('created_at', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => QueueModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList();
      });
    } catch (e) {
      // Fallback if exception is thrown later
      yield _dummyQueues;
      yield* _dummyStreamController.stream;
    }
  }

  Stream<List<EventModel>> get eventsStream async* {
    if (_useDummyData) {
      yield dummyEvents;
      yield* _dummyEventsStreamController.stream;
      return;
    }
    try {
      yield* _eventsCollection.snapshots().map((snapshot) {
        return snapshot.docs
            .map((doc) => EventModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList();
      });
    } catch (e) {
      yield dummyEvents;
      yield* _dummyEventsStreamController.stream;
    }
  }

  Stream<List<AksesorisItemModel>> get accessoriesStream async* {
    if (_useDummyData) {
      yield dummyAksesorisItems;
      yield* _dummyAccessoriesStreamController.stream;
      return;
    }
    try {
      yield* _accessoriesCollection.snapshots().map((snapshot) {
        return snapshot.docs
            .map((doc) => AksesorisItemModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList();
      });
    } catch (e) {
      yield dummyAksesorisItems;
      yield* _dummyAccessoriesStreamController.stream;
    }
  }

  Stream<List<SetPhotoboothModel>> get setPhotoboothStream async* {
    if (_useDummyData) {
      yield []; // No dummy data needed
      return;
    }
    try {
      yield* _setPhotoboothCollection.snapshots().map((snapshot) {
        return snapshot.docs
            .map((doc) => SetPhotoboothModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList();
      });
    } catch (e) {
      yield [];
    }
  }

  // Add new queue
  Future<void> addQueue(QueueModel queue) async {
    if (_useDummyData) {
      final newQ = QueueModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        eventId: queue.eventId,
        name: queue.name,
        totalStrips: queue.totalStrips,
        totalPayment: queue.totalPayment,
        paymentMethod: queue.paymentMethod,
        splitPayments: queue.splitPayments,
        status: queue.status,
        type: queue.type,
        items: queue.items,
        createdAt: DateTime.now(),
      );
      _dummyQueues.insert(0, newQ);
      _dummyStreamController.add(List.from(_dummyQueues));
      return;
    }
    
    if (queue.type == 'Aksesoris' && queue.items != null && queue.items!.isNotEmpty) {
      final batch = FirebaseFirestore.instance.batch();
      final docRef = _queueCollection.doc();
      batch.set(docRef, queue.toMap());

      for (var item in queue.items!) {
        if (item['id'] != null) {
          final accRef = _accessoriesCollection.doc(item['id']);
          batch.update(accRef, {
            'stock': FieldValue.increment(-(item['qty'] as int)),
          });
        }
      }
      await batch.commit();
    } else {
      await _queueCollection.add(queue.toMap());
    }
  }

  // Update queue status
  Future<void> updateStatus(String id, String status) async {
    if (_useDummyData) {
      final index = _dummyQueues.indexWhere((q) => q.id == id);
      if (index != -1) {
        final oldQ = _dummyQueues[index];
        _dummyQueues[index] = QueueModel(
          id: oldQ.id,
          name: oldQ.name,
          totalStrips: oldQ.totalStrips,
          totalPayment: oldQ.totalPayment,
          paymentMethod: oldQ.paymentMethod,
          splitPayments: oldQ.splitPayments,
          status: status,
          type: oldQ.type,
          items: oldQ.items,
          createdAt: oldQ.createdAt,
          updatedAt: DateTime.now(),
          eventId: oldQ.eventId,
        );
        _dummyStreamController.add(List.from(_dummyQueues));
      }
      return;
    }

    // Jika status diubah ke BATAL, kembalikan stok aksesoris jika ada
    if (status == 'BATAL') {
      final docSnapshot = await _queueCollection.doc(id).get();
      if (docSnapshot.exists) {
        final queueData = docSnapshot.data() as Map<String, dynamic>;
        final type = queueData['type'] as String? ?? 'Booth';
        final oldStatus = queueData['status'] as String? ?? '';
        final items = queueData['items'] as List<dynamic>?;

        // Hanya kembalikan stok jika transaksi aksesoris & sebelumnya BUKAN sudah BATAL
        if (type == 'Aksesoris' && oldStatus != 'BATAL' && items != null && items.isNotEmpty) {
          final batch = FirebaseFirestore.instance.batch();
          batch.update(_queueCollection.doc(id), {
            'status': status,
            'updated_at': FieldValue.serverTimestamp(),
          });
          for (var item in items) {
            final itemMap = item as Map<String, dynamic>;
            final itemId = itemMap['id'] as String?;
            final qty = itemMap['qty'] as int? ?? 0;
            if (itemId != null && qty > 0) {
              final accRef = _accessoriesCollection.doc(itemId);
              batch.update(accRef, {
                'stock': FieldValue.increment(qty), // kembalikan stok
              });
            }
          }
          await batch.commit();
          return;
        }
      }
    }

    await _queueCollection.doc(id).update({
      'status': status,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  // Hard Delete Queue
  Future<void> deleteQueue(String id) async {
    if (_useDummyData) {
      _dummyQueues.removeWhere((q) => q.id == id);
      _dummyStreamController.add(List.from(_dummyQueues));
      return;
    }

    // Kembalikan stok aksesoris sebelum menghapus, jika transaksi belum BATAL
    final docSnapshot = await _queueCollection.doc(id).get();
    if (docSnapshot.exists) {
      final queueData = docSnapshot.data() as Map<String, dynamic>;
      final type = queueData['type'] as String? ?? 'Booth';
      final currentStatus = queueData['status'] as String? ?? '';
      final items = queueData['items'] as List<dynamic>?;

      // Hanya kembalikan stok jika aksesoris & belum BATAL (jika sudah BATAL, stok sudah dikembalikan)
      if (type == 'Aksesoris' && currentStatus != 'BATAL' && items != null && items.isNotEmpty) {
        final batch = FirebaseFirestore.instance.batch();
        batch.delete(_queueCollection.doc(id));
        for (var item in items) {
          final itemMap = item as Map<String, dynamic>;
          final itemId = itemMap['id'] as String?;
          final qty = itemMap['qty'] as int? ?? 0;
          if (itemId != null && qty > 0) {
            final accRef = _accessoriesCollection.doc(itemId);
            batch.update(accRef, {
              'stock': FieldValue.increment(qty), // kembalikan stok
            });
          }
        }
        await batch.commit();
        return;
      }
    }

    await _queueCollection.doc(id).delete();
  }

  // Event CRUD
  Future<void> addEvent(EventModel event) async {
    if (_useDummyData) {
      dummyEvents.add(event);
      _dummyEventsStreamController.add(List.from(dummyEvents));
      return;
    }
    await _eventsCollection.add(event.toMap());
  }

  Future<void> updateEvent(EventModel event) async {
    if (_useDummyData) {
      final index = dummyEvents.indexWhere((e) => e.id == event.id);
      if (index != -1) {
        dummyEvents[index] = event;
        _dummyEventsStreamController.add(List.from(dummyEvents));
      }
      return;
    }
    await _eventsCollection.doc(event.id).update(event.toMap());
  }

  Future<void> deleteEvent(String id) async {
    if (_useDummyData) {
      dummyEvents.removeWhere((e) => e.id == id);
      _dummyEventsStreamController.add(List.from(dummyEvents));
      return;
    }
    await _eventsCollection.doc(id).delete();
  }

  Future<void> deleteEventWithRelatedData(String eventId) async {
    if (_useDummyData) return;
    final batch = FirebaseFirestore.instance.batch();

    // 1. Delete queues related to this event
    final queuesSnapshot = await _queueCollection.where('event_id', isEqualTo: eventId).get();
    for (var doc in queuesSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // 2. Delete checklists related to this event
    final checklistsSnapshot = await _checklistCollection.where('event_id', isEqualTo: eventId).get();
    for (var doc in checklistsSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // 3. Delete the event itself
    final eventRef = _eventsCollection.doc(eventId);
    batch.delete(eventRef);

    await batch.commit();
  }

  Future<int> getTotalDatabaseDocumentsCount() async {
    if (_useDummyData) return 0;
    try {
      final eventsCount = await _eventsCollection.count().get();
      final queuesCount = await _queueCollection.count().get();
      final checklistCount = await _checklistCollection.count().get();
      return (eventsCount.count ?? 0) + (queuesCount.count ?? 0) + (checklistCount.count ?? 0);
    } catch (e) {
      return 0;
    }
  }

  // Toggle pinned status
  Future<void> toggleQueuePin(String id, bool isPinned) async {
    if (_useDummyData) {
      final index = _dummyQueues.indexWhere((q) => q.id == id);
      if (index != -1) {
        final oldQ = _dummyQueues[index];
        _dummyQueues[index] = oldQ.copyWith(
          isPinned: isPinned,
          updatedAt: DateTime.now(),
        );
        _dummyStreamController.add(List.from(_dummyQueues));
      }
      return;
    }
    
    await _queueCollection.doc(id).update({
      'is_pinned': isPinned,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  // Update entire queue details
  Future<void> updateQueue(QueueModel queue) async {
    if (_useDummyData) {
      final index = _dummyQueues.indexWhere((q) => q.id == queue.id);
      if (index != -1) {
        _dummyQueues[index] = QueueModel(
          id: queue.id,
          name: queue.name,
          totalStrips: queue.totalStrips,
          totalPayment: queue.totalPayment,
          paymentMethod: queue.paymentMethod,
          splitPayments: queue.splitPayments,
          status: queue.status,
          type: queue.type,
          items: queue.items,
          createdAt: queue.createdAt,
          updatedAt: DateTime.now(),
          eventId: queue.eventId,
        );
        _dummyStreamController.add(List.from(_dummyQueues));
      }
      return;
    }
    
    final Map<String, dynamic> updateData = {
      'name': queue.name,
      'total_strips': queue.totalStrips,
      'total_payment': queue.totalPayment,
      'payment_method': queue.paymentMethod,
      'type': queue.type,
      'updated_at': FieldValue.serverTimestamp(),
    };
    if (queue.items != null) {
      updateData['items'] = queue.items;
    } else {
      updateData['items'] = FieldValue.delete();
    }
    if (queue.splitPayments != null) {
      updateData['split_payments'] = queue.splitPayments;
    } else {
      updateData['split_payments'] = FieldValue.delete();
    }
    await _queueCollection.doc(queue.id).update(updateData);
  }
  
  // Calculate daily report
  Future<Map<String, dynamic>> getDailyReport() async {
    if (_useDummyData) {
      return _calculateReportFromList(_dummyQueues);
    }
    
    try {
      DateTime today = BusinessDayUtils.getBusinessDay();
      DateTime startOfDay = DateTime(today.year, today.month, today.day, 6, 0); // 06:00 AM
      
      QuerySnapshot snapshot = await _queueCollection
          .where('created_at', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .get();
          
      final list = snapshot.docs
          .map((doc) => QueueModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
          
      return _calculateReportFromList(list);
    } catch (e) {
      return _calculateReportFromList(_dummyQueues);
    }
  }

  Future<int> getEventSessionCountByDate(String eventId, DateTime date) async {
    List<QueueModel> queues = [];
    if (_useDummyData) {
      queues = _dummyQueues.where((q) => q.eventId == eventId).toList();
    } else {
      try {
        QuerySnapshot snapshot = await _queueCollection
            .where('event_id', isEqualTo: eventId)
            .get();
        queues = snapshot.docs
            .map((doc) => QueueModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList();
      } catch (e) {
        return 0;
      }
    }
    
    int count = 0;
    for (var q in queues) {
      if (q.status == 'SELESAI' && q.type == 'Booth') {
        if (q.createdAt != null && 
            BusinessDayUtils.getBusinessDayFor(q.createdAt!) == BusinessDayUtils.getBusinessDayFor(date)) {
          count++;
        }
      }
    }
    return count;
  }


  // ========================
  //  KPI Methods for Home
  // ========================

  /// Hitung jumlah hari mendatang (termasuk hari ini) yang ada event
  Future<int> getUpcomingEventDaysCount() async {
    List<EventModel> events = [];
    if (_useDummyData) {
      events = List.from(dummyEvents);
    } else {
      try {
        final snapshot = await _eventsCollection.get();
        events = snapshot.docs.map((doc) => EventModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
      } catch (e) {
        return 0;
      }
    }

    final today = BusinessDayUtils.getBusinessDay();
    final todayNorm = today;

    // Collect all unique calendar days that have an event >= today
    final Set<String> uniqueDays = {};
    for (var event in events) {
      DateTime cur = DateTime(event.date.year, event.date.month, event.date.day);
      final end = DateTime(event.endDate.year, event.endDate.month, event.endDate.day);
      while (!cur.isAfter(end)) {
        if (!cur.isBefore(todayNorm)) {
          uniqueDays.add('${cur.year}-${cur.month}-${cur.day}');
        }
        cur = cur.add(const Duration(days: 1));
      }
    }
    return uniqueDays.length;
  }

  /// Total sesi selesai booth hari ini
  Future<int> getTodayBoothSelesaiCount() async {
    final today = BusinessDayUtils.getBusinessDay();
    List<QueueModel> queues = [];
    if (_useDummyData) {
      queues = _dummyQueues;
    } else {
      try {
        final snapshot = await _queueCollection
            .where('type', isEqualTo: 'Booth')
            .where('status', isEqualTo: 'SELESAI')
            .get();
        queues = snapshot.docs.map((doc) => QueueModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
      } catch (e) {
        return 0;
      }
    }
    return queues.where((q) {
      if (q.createdAt == null) return false;
      return BusinessDayUtils.getBusinessDayFor(q.createdAt!) == today;
    }).length;
  }

  /// Total pendapatan 7 hari terakhir (termasuk hari ini): booth + aksesoris
  Future<int> getLast7DaysRevenue() async {
    final today = BusinessDayUtils.getBusinessDay();
    final cutoff = DateTime(today.year, today.month, today.day).subtract(const Duration(days: 6));
    List<QueueModel> queues = [];
    if (_useDummyData) {
      queues = _dummyQueues;
    } else {
      try {
        final snapshot = await _queueCollection
            .where('status', isEqualTo: 'SELESAI')
            .get();
        queues = snapshot.docs.map((doc) => QueueModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
      } catch (e) {
        return 0;
      }
    }
    int total = 0;
    for (var q in queues) {
      if (q.createdAt == null) continue;
      final d = BusinessDayUtils.getBusinessDayFor(q.createdAt!);
      if (!d.isBefore(cutoff)) {
        int payment = q.totalPayment;
        if (q.paymentMethod == 'Split' && q.splitPayments != null) {
          payment = ((q.splitPayments!['Cash'] ?? 0) as num).toInt() +
                    ((q.splitPayments!['QRIS'] ?? 0) as num).toInt();
        }
        total += payment;
      }
    }
    return total;
  }

  Stream<int> get todayBoothSelesaiCountStream {
    final today = BusinessDayUtils.getBusinessDay();
    if (_useDummyData) {
      return Stream.value(_dummyQueues.where((q) =>
        q.status == 'SELESAI' && q.type == 'Booth' &&
        q.createdAt != null &&
        q.createdAt!.year == today.year &&
        q.createdAt!.month == today.month &&
        q.createdAt!.day == today.day).length);
    }
    return _queueCollection
        .where('type', isEqualTo: 'Booth')
        .where('status', isEqualTo: 'SELESAI')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => QueueModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .where((q) => q.createdAt != null &&
                BusinessDayUtils.getBusinessDayFor(q.createdAt!) == today)
            .length)
        .handleError((e) => 0);
  }

  Stream<int> get last7DaysRevenueStream {
    final today = BusinessDayUtils.getBusinessDay();
    final cutoff = DateTime(today.year, today.month, today.day).subtract(const Duration(days: 6));
    if (_useDummyData) return Stream.value(0);
    return _queueCollection.where('status', isEqualTo: 'SELESAI').snapshots().map((snapshot) {
      int total = 0;
      for (var doc in snapshot.docs) {
        final q = QueueModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        if (q.createdAt == null) continue;
        final d = BusinessDayUtils.getBusinessDayFor(q.createdAt!);
        if (!d.isBefore(cutoff)) {
          int payment = q.totalPayment;
          if (q.paymentMethod == 'Split' && q.splitPayments != null) {
            payment = ((q.splitPayments!['Cash'] ?? 0) as num).toInt() +
                      ((q.splitPayments!['QRIS'] ?? 0) as num).toInt();
          }
          total += payment;
        }
      }
      return total;
    }).handleError((e) => 0);
  }

  Stream<int> get last7DaysBoothSelesaiCountStream {
    final today = BusinessDayUtils.getBusinessDay();
    final cutoff = DateTime(today.year, today.month, today.day).subtract(const Duration(days: 6));
    if (_useDummyData) return Stream.value(0);
    return _queueCollection
        .where('type', isEqualTo: 'Booth')
        .where('status', isEqualTo: 'SELESAI')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => QueueModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .where((q) {
              if (q.createdAt == null) return false;
              final d = BusinessDayUtils.getBusinessDayFor(q.createdAt!);
              return !d.isBefore(cutoff);
            })
            .length)
        .handleError((e) => 0);
  }

  Stream<int> get last7DaysAksesorisItemsSoldStream {
    final today = BusinessDayUtils.getBusinessDay();
    final cutoff = DateTime(today.year, today.month, today.day).subtract(const Duration(days: 6));
    if (_useDummyData) return Stream.value(0);
    return _queueCollection
        .where('type', isEqualTo: 'Aksesoris')
        .where('status', isEqualTo: 'SELESAI')
        .snapshots()
        .map((snapshot) {
          int totalItems = 0;
          for (var doc in snapshot.docs) {
            final q = QueueModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
            if (q.createdAt == null) continue;
            final d = BusinessDayUtils.getBusinessDayFor(q.createdAt!);
            if (!d.isBefore(cutoff)) {
              if (q.items != null) {
                for (var item in q.items!) {
                  totalItems += ((item['quantity'] ?? 1) as num).toInt();
                }
              } else {
                totalItems += 1;
              }
            }
          }
          return totalItems;
        })
        .handleError((e) => 0);
  }

  /// Total sesi selesai booth dalam 7 hari terakhir (termasuk hari ini)
  Future<int> getLast7DaysBoothSelesaiCount() async {
    final today = BusinessDayUtils.getBusinessDay();
    final cutoff = DateTime(today.year, today.month, today.day).subtract(const Duration(days: 6));
    List<QueueModel> queues = [];
    if (_useDummyData) {
      queues = _dummyQueues;
    } else {
      try {
        final snapshot = await _queueCollection
            .where('type', isEqualTo: 'Booth')
            .where('status', isEqualTo: 'SELESAI')
            .get();
        queues = snapshot.docs.map((doc) => QueueModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
      } catch (e) {
        return 0;
      }
    }
    return queues.where((q) {
      if (q.createdAt == null) return false;
      final d = BusinessDayUtils.getBusinessDayFor(q.createdAt!);
      return !d.isBefore(cutoff);
    }).length;
  }

  /// Total item aksesoris terjual dalam 7 hari terakhir (termasuk hari ini)
  Future<int> getLast7DaysAksesorisItemsSold() async {
    final today = BusinessDayUtils.getBusinessDay();
    final cutoff = DateTime(today.year, today.month, today.day).subtract(const Duration(days: 6));
    List<QueueModel> queues = [];
    if (_useDummyData) {
      queues = _dummyQueues;
    } else {
      try {
        final snapshot = await _queueCollection
            .where('type', isEqualTo: 'Aksesoris')
            .where('status', isEqualTo: 'SELESAI')
            .get();
        queues = snapshot.docs.map((doc) => QueueModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
      } catch (e) {
        return 0;
      }
    }
    int totalItems = 0;
    for (var q in queues) {
      if (q.createdAt == null) continue;
      final d = BusinessDayUtils.getBusinessDayFor(q.createdAt!);
      if (!d.isBefore(cutoff)) {
        if (q.items != null) {
          for (var item in q.items!) {
            totalItems += ((item['quantity'] ?? 1) as num).toInt();
          }
        } else {
          totalItems += 1;
        }
      }
    }
    return totalItems;
  }



  /// Total pendapatan keseluruhan dari semua event yang sudah terlewat atau hari ini
  Future<int> getAllTimeRevenue() async {
    final today = BusinessDayUtils.getBusinessDay();
    final todayNorm = today;
    List<QueueModel> queues = [];
    if (_useDummyData) {
      queues = _dummyQueues;
    } else {
      try {
        final snapshot = await _queueCollection
            .where('status', isEqualTo: 'SELESAI')
            .get();
        queues = snapshot.docs.map((doc) => QueueModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
      } catch (e) {
        return 0;
      }
    }
    int total = 0;
    for (var q in queues) {
      if (q.createdAt == null) continue;
      final d = BusinessDayUtils.getBusinessDayFor(q.createdAt!);
      if (!d.isAfter(todayNorm)) { // Only today or past
        int payment = q.totalPayment;
        if (q.paymentMethod == 'Split' && q.splitPayments != null) {
          payment = ((q.splitPayments!['Cash'] ?? 0) as num).toInt() +
                    ((q.splitPayments!['QRIS'] ?? 0) as num).toInt();
        }
        total += payment;
      }
    }
    return total;
  }

  Stream<int> get allTimeRevenueStream {
    final today = BusinessDayUtils.getBusinessDay();
    final todayNorm = today;
    
    if (_useDummyData) {
      int total = 0;
      for (var q in _dummyQueues) {
        if (q.createdAt == null) continue;
        final d = BusinessDayUtils.getBusinessDayFor(q.createdAt!);
        if (!d.isAfter(todayNorm) && q.status == 'SELESAI') {
          int payment = q.totalPayment;
          if (q.paymentMethod == 'Split' && q.splitPayments != null) {
            payment = ((q.splitPayments!['Cash'] ?? 0) as num).toInt() +
                      ((q.splitPayments!['QRIS'] ?? 0) as num).toInt();
          }
          total += payment;
        }
      }
      return Stream.value(total);
    }

    return _queueCollection.where('status', isEqualTo: 'SELESAI').snapshots().map((snapshot) {
      int total = 0;
      for (var doc in snapshot.docs) {
        final q = QueueModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        if (q.createdAt == null) continue;
        final d = BusinessDayUtils.getBusinessDayFor(q.createdAt!);
        if (!d.isAfter(todayNorm)) {
          int payment = q.totalPayment;
          if (q.paymentMethod == 'Split' && q.splitPayments != null) {
            payment = ((q.splitPayments!['Cash'] ?? 0) as num).toInt() +
                      ((q.splitPayments!['QRIS'] ?? 0) as num).toInt();
          }
          total += payment;
        }
      }
      return total;
    }).handleError((e) => 0);
  }

  /// Total sesi booth dari semua event yang sudah terlewat atau hari ini
  Future<int> getAllTimeBoothSelesaiCount() async {
    final today = BusinessDayUtils.getBusinessDay();
    final todayNorm = today;
    List<QueueModel> queues = [];
    if (_useDummyData) {
      queues = _dummyQueues;
    } else {
      try {
        final snapshot = await _queueCollection
            .where('type', isEqualTo: 'Booth')
            .where('status', isEqualTo: 'SELESAI')
            .get();
        queues = snapshot.docs.map((doc) => QueueModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
      } catch (e) {
        return 0;
      }
    }
    return queues.where((q) {
      if (q.createdAt == null) return false;
      final d = BusinessDayUtils.getBusinessDayFor(q.createdAt!);
      return !d.isAfter(todayNorm); // Only today or past
    }).length;
  }

  Stream<int> get allTimeBoothSelesaiCountStream {
    final today = BusinessDayUtils.getBusinessDay();
    final todayNorm = today;

    if (_useDummyData) {
      int count = _dummyQueues.where((q) {
        if (q.status != 'SELESAI' || q.type != 'Booth' || q.createdAt == null) return false;
        final d = BusinessDayUtils.getBusinessDayFor(q.createdAt!);
        return !d.isAfter(todayNorm);
      }).length;
      return Stream.value(count);
    }

    return _queueCollection
        .where('type', isEqualTo: 'Booth')
        .where('status', isEqualTo: 'SELESAI')
        .snapshots()
        .map((snapshot) {
      int count = 0;
      for (var doc in snapshot.docs) {
        final q = QueueModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        if (q.createdAt == null) continue;
        final d = BusinessDayUtils.getBusinessDayFor(q.createdAt!);
        if (!d.isAfter(todayNorm)) count++;
      }
      return count;
    }).handleError((e) => 0);
  }

  // Event Summary for Past Events
  Future<Map<String, dynamic>> getEventSummary(String eventId, DateTime eventDate) async {
    List<QueueModel> queues = [];
    if (_useDummyData) {
      queues = _dummyQueues;
    } else {
      try {
        QuerySnapshot snapshot = await _queueCollection
            .where('event_id', isEqualTo: eventId)
            .get();
            
        queues = snapshot.docs
            .map((doc) => QueueModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList();
      } catch (e) {
        queues = _dummyQueues;
      }
    }
    
    // (Date filter removed to include all transactions for this event)
    
    DateTime? startTime;
    DateTime? endTime;
    int sessionCount = 0;
    
    for (var q in queues) {
      if (q.createdAt != null) {
        if (startTime == null || q.createdAt!.isBefore(startTime)) {
          startTime = q.createdAt;
        }
      }
      if (q.status == 'SELESAI' && q.type == 'Booth') {
        sessionCount++;
        final time = q.updatedAt ?? q.createdAt;
        if (time != null) {
          if (endTime == null || time.isAfter(endTime)) {
            endTime = time;
          }
        }
      }
    }
    
    return {
      'startTime': startTime,
      'endTime': endTime,
      'sessionCount': sessionCount,
    };
  }

  // Event Detailed Transactions and Metrics
  Future<Map<String, dynamic>> getEventTransactions(String eventId, DateTime eventDate) async {
    List<QueueModel> queues = [];
    if (_useDummyData) {
      queues = _dummyQueues;
    } else {
      try {
        QuerySnapshot snapshot = await _queueCollection
            .where('event_id', isEqualTo: eventId)
            .get();
            
        queues = snapshot.docs
            .map((doc) => QueueModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList();
      } catch (e) {
        queues = _dummyQueues;
      }
    }
    
    // Date filter for per-day item counts
    final eventDay = DateTime(eventDate.year, eventDate.month, eventDate.day);
    
    List<QueueModel> boothQueues = [];
    List<QueueModel> aksesorisQueues = [];
    
    int boothSelesai = 0;
    int boothBatal = 0;
    int boothCash = 0;
    int boothQris = 0;
    
    int aksesorisSelesai = 0;
    int aksesorisBatal = 0;
    int aksesorisCash = 0;
    int aksesorisQris = 0;
    int aksesorisItemTerjual = 0; // total qty item aksesoris terjual (SELESAI)
    int aksesorisItemBatal = 0;  // total qty item aksesoris dibatalkan (BATAL)
    
    for (var q in queues) {
      if (q.type == 'Booth') {
        boothQueues.add(q);
        if (q.status == 'SELESAI' && q.type == 'Booth') {
          boothSelesai++;
          if (q.paymentMethod == 'Cash') {
            boothCash += q.totalPayment;
          } else if (q.paymentMethod == 'QRIS') {
            boothQris += q.totalPayment;
          } else if (q.paymentMethod == 'Split' && q.splitPayments != null) {
            boothCash += (q.splitPayments!['Cash'] ?? 0) as int;
            boothQris += (q.splitPayments!['QRIS'] ?? 0) as int;
          }
        } else if (q.status == 'BATAL') {
          boothBatal++;
        }
      } else { // Aksesoris
        aksesorisQueues.add(q);
        if (q.status == 'SELESAI' && q.type == 'Aksesoris') {
          aksesorisSelesai++;
          // Hitung total qty item terjual (sama seperti kasir mode aksesoris: sum qty)
          final qDay = q.createdAt != null ? DateTime(q.createdAt!.year, q.createdAt!.month, q.createdAt!.day) : null;
          if (qDay != null && qDay == eventDay && q.items != null) {
            for (var item in q.items!) {
              aksesorisItemTerjual += (item['qty'] as num?)?.toInt() ?? 0;
            }
          }
          if (q.paymentMethod == 'Cash') {
            aksesorisCash += q.totalPayment;
          } else if (q.paymentMethod == 'QRIS') {
            aksesorisQris += q.totalPayment;
          } else if (q.paymentMethod == 'Split' && q.splitPayments != null) {
            aksesorisCash += (q.splitPayments!['Cash'] ?? 0) as int;
            aksesorisQris += (q.splitPayments!['QRIS'] ?? 0) as int;
          }
        } else if (q.status == 'BATAL') {
          aksesorisBatal++;
          // Hitung total qty item dibatalkan
          final qDay = q.createdAt != null ? DateTime(q.createdAt!.year, q.createdAt!.month, q.createdAt!.day) : null;
          if (qDay != null && qDay == eventDay && q.items != null) {
            for (var item in q.items!) {
              aksesorisItemBatal += (item['qty'] as num?)?.toInt() ?? 0;
            }
          }
        }
      }
    }
    
    // Sort ascending by created_at (oldest first)
    boothQueues.sort((a, b) => (a.createdAt ?? DateTime.now()).compareTo(b.createdAt ?? DateTime.now()));
    aksesorisQueues.sort((a, b) => (a.createdAt ?? DateTime.now()).compareTo(b.createdAt ?? DateTime.now()));
    
    int komisi = boothSelesai * 5000;
    int subTotalBooth = boothCash - komisi;
    
    return {
      'boothQueues': boothQueues,
      'aksesorisQueues': aksesorisQueues,
      'boothSelesai': boothSelesai,
      'boothBatal': boothBatal,
      'boothCash': boothCash,
      'boothQris': boothQris,
      'aksesorisSelesai': aksesorisSelesai,
      'aksesorisBatal': aksesorisBatal,
      'aksesorisCash': aksesorisCash,
      'aksesorisQris': aksesorisQris,
      'aksesorisItemTerjual': aksesorisItemTerjual,
      'aksesorisItemBatal': aksesorisItemBatal,
      'komisi': komisi,
      'subTotalBooth': subTotalBooth,
    };
  }

  // Helper method for reports
  Map<String, dynamic> _calculateReportFromList(List<QueueModel> queues) {
    int totalRevenue = 0;
    int totalCash = 0;
    int totalQris = 0;
    int totalStrips = 0;
    int cancelledCount = 0;
    
    for (var q in queues) {
      if (q.status == 'SELESAI') {
        totalRevenue += q.totalPayment;
        if (q.type == 'Booth') {
          totalStrips += q.totalStrips;
        }
        if (q.paymentMethod == 'Cash') {
          totalCash += q.totalPayment;
        } else if (q.paymentMethod == 'QRIS') {
          totalQris += q.totalPayment;
        } else if (q.paymentMethod == 'Split' && q.splitPayments != null) {
          totalCash += (q.splitPayments!['Cash'] ?? 0) as int;
          totalQris += (q.splitPayments!['QRIS'] ?? 0) as int;
        }
      } else if (q.status == 'BATAL') {
        cancelledCount++;
      }
    }
    
    return {
      'totalRevenue': totalRevenue,
      'totalCash': totalCash,
      'totalQris': totalQris,
      'totalStrips': totalStrips,
      'cancelledCount': cancelledCount,
    };
  }

  // Accessory CRUD
  Future<void> addAccessory(AksesorisItemModel accessory) async {
    if (_useDummyData) {
      dummyAksesorisItems.add(accessory);
      _dummyAccessoriesStreamController.add(List.from(dummyAksesorisItems));
      return;
    }
    await _accessoriesCollection.add(accessory.toMap());
  }

  Future<void> updateAccessory(AksesorisItemModel accessory) async {
    if (_useDummyData) {
      final index = dummyAksesorisItems.indexWhere((a) => a.id == accessory.id);
      if (index != -1) {
        dummyAksesorisItems[index] = accessory;
        _dummyAccessoriesStreamController.add(List.from(dummyAksesorisItems));
      }
      return;
    }
    await _accessoriesCollection.doc(accessory.id).update(accessory.toMap());
  }

  Future<void> deleteAccessory(String id) async {
    if (_useDummyData) {
      dummyAksesorisItems.removeWhere((a) => a.id == id);
      _dummyAccessoriesStreamController.add(List.from(dummyAksesorisItems));
      return;
    }
    await _accessoriesCollection.doc(id).delete();
  }

  // Set Photobooth CRUD
  Future<void> addSetPhotobooth(SetPhotoboothModel item) async {
    if (_useDummyData) return;
    await _setPhotoboothCollection.add(item.toMap());
  }

  Future<void> updateSetPhotobooth(SetPhotoboothModel item) async {
    if (_useDummyData) return;
    await _setPhotoboothCollection.doc(item.id).update(item.toMap());
  }

  Future<void> deleteSetPhotobooth(String id) async {
    if (_useDummyData) return;
    await _setPhotoboothCollection.doc(id).delete();
  }

  // --- USER AUTH & KASIR CRUD ---
  
  Future<UserModel?> login(String password) async {
    if (_useDummyData) {
      if (password == 'admin123') return UserModel(id: '1', name: 'Admin', password: password, role: 'admin');
      if (password == 'kasir') return UserModel(id: '2', name: 'Kasir', password: password, role: 'kasir');
      return null;
    }

    // Check if the user is the default admin
    if (password == 'admin123') {
      final adminQuery = await _usersCollection.where('role', isEqualTo: 'admin').get();
      if (adminQuery.docs.isEmpty) {
        // Seed default admin
        final newAdmin = UserModel(id: '', name: 'Super Admin', password: 'admin123', role: 'admin');
        await _usersCollection.add(newAdmin.toMap());
        return newAdmin;
      }
    }

    final querySnapshot = await _usersCollection.where('password', isEqualTo: password).get();
    if (querySnapshot.docs.isNotEmpty) {
      final doc = querySnapshot.docs.first;
      return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }
    return null;
  }

  Stream<List<UserModel>> get kasirsStream {
    if (_useDummyData) {
      return Stream.value([]);
    }
    return _usersCollection
        .where('role', isEqualTo: 'kasir')
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
      list.sort((a, b) => (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));
      return list;
    });
  }

  Future<void> addUser(UserModel user) async {
    if (_useDummyData) return;
    await _usersCollection.add(user.toMap());
  }

  Future<void> updateUser(UserModel user) async {
    if (_useDummyData) return;
    await _usersCollection.doc(user.id).update(user.toMap());
  }

  Future<bool> updateKasirPassword(String id, String newPassword) async {
    if (_useDummyData) return true; // Simulate success
    try {
      await _usersCollection.doc(id).update({
        'password': newPassword,
        'updated_at': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> deleteUser(String id) async {
    if (_useDummyData) return;
    await _usersCollection.doc(id).delete();
  }

  // ========================
  //  Checklist Methods
  // ========================

  CollectionReference get _checklistCollection =>
      FirebaseFirestore.instance.collection('checklists');

  String _checklistDocId(String eventId, DateTime date) =>
      '${eventId}_${date.year}${date.month.toString().padLeft(2,'0')}${date.day.toString().padLeft(2,'0')}';

  Future<void> saveChecklist({
    required String eventId,
    required DateTime date,
    required List<Map<String, dynamic>> items,
  }) async {
    if (_useDummyData) return;
    final docId = _checklistDocId(eventId, date);
    await _checklistCollection.doc(docId).set({
      'event_id': eventId,
      'date': Timestamp.fromDate(DateTime(date.year, date.month, date.day)),
      'items': items,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  Future<Map<String, Map<String, bool>>> getChecklist({
    required String eventId,
    required DateTime date,
  }) async {
    if (_useDummyData) return {};
    try {
      final docId = _checklistDocId(eventId, date);
      final doc = await _checklistCollection.doc(docId).get();
      if (!doc.exists) return {};
      final data = doc.data() as Map<String, dynamic>;
      final items = (data['items'] as List<dynamic>?) ?? [];
      final result = <String, Map<String, bool>>{};
      for (var item in items) {
        final id = item['item_id'] as String? ?? '';
        if (id.isNotEmpty) {
          result[id] = {
            'masuk': (item['masuk'] as bool?) ?? false,
            'keluar': (item['keluar'] as bool?) ?? false,
          };
        }
      }
      return result;
    } catch (e) {
      return {};
    }
  }
  Future<Map<String, dynamic>> getChecklistFull({
    required String eventId,
    required DateTime date,
  }) async {
    if (_useDummyData) return {'items': [], 'updatedAt': null};
    try {
      final docId = _checklistDocId(eventId, date);
      final doc = await _checklistCollection.doc(docId).get();
      if (!doc.exists) return {'items': [], 'updatedAt': null};
      final data = doc.data() as Map<String, dynamic>;
      final items = List<Map<String, dynamic>>.from(
        (data['items'] as List<dynamic>?)?.map((e) => Map<String, dynamic>.from(e)) ?? [],
      );
      final updatedAt = (data['updated_at'] as Timestamp?)?.toDate();
      return {'items': items, 'updatedAt': updatedAt};
    } catch (e) {
      return {'items': [], 'updatedAt': null};
    }
  }
}
