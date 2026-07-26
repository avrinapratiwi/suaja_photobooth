import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../models/event_model.dart';
import '../models/queue_model.dart';
import '../services/firebase_service.dart';
import '../widgets/notification_bell.dart';

class AdminEventDetailScreen extends StatefulWidget {
  final EventModel event;

  const AdminEventDetailScreen({super.key, required this.event});

  @override
  State<AdminEventDetailScreen> createState() => _AdminEventDetailScreenState();
}

class _AdminEventDetailScreenState extends State<AdminEventDetailScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  late Future<Map<String, dynamic>> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _firebaseService.getEventTransactions(widget.event.id, widget.event.date);
  }

  String _getTimeRangeString(List<QueueModel> booth, List<QueueModel> aksesoris) {
    final allQueues = [...booth, ...aksesoris];
    if (allQueues.isEmpty) return 'Belum ada transaksi';

    DateTime? firstTime;
    DateTime? lastTime;

    for (var q in allQueues) {
      if (q.createdAt != null) {
        if (firstTime == null || q.createdAt!.isBefore(firstTime)) {
          firstTime = q.createdAt;
        }
      }
      final updated = q.updatedAt ?? q.createdAt;
      if (updated != null) {
        if (lastTime == null || updated.isAfter(lastTime)) {
          lastTime = updated;
        }
      }
    }

    if (firstTime == null || lastTime == null) return 'Waktu tidak diketahui';

    final format = DateFormat('HH:mm');
    return '${format.format(firstTime)} - ${format.format(lastTime)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Laporan Event',
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E293B),
          ),
        ),
        actions: const [
          NotificationBellWidget(),
          SizedBox(width: 16),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
          }

          final data = snapshot.data!;
          final boothQueues = data['boothQueues'] as List<QueueModel>;
          final aksesorisQueues = data['aksesorisQueues'] as List<QueueModel>;
          final timeRange = _getTimeRangeString(boothQueues, aksesorisQueues);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Event Header (no card)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.event.name,
                      style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.access_time_rounded, size: 16, color: Color(0xFF64748B)),
                        const SizedBox(width: 6),
                        Text(
                          timeRange,
                          style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Booth Section
                Text(
                  'Booth',
                  style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                ),
                const SizedBox(height: 12),
                _buildTransactionList(boothQueues, true),
                const SizedBox(height: 32),

                // Aksesoris Section
                Text(
                  'Aksesoris',
                  style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                ),
                const SizedBox(height: 12),
                _buildTransactionList(aksesorisQueues, false),
                const SizedBox(height: 32),

                // Checklist Set Section
                Text(
                  'Checklist Set',
                  style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                ),
                const SizedBox(height: 12),
                _buildChecklistSection(),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildChecklistSection() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _firebaseService.getChecklistFull(
        eventId: widget.event.id,
        date: widget.event.date,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(),
          ));
        }
        final checkData = snapshot.data ?? {'items': <Map<String, dynamic>>[], 'updatedAt': null};
        final items = List<Map<String, dynamic>>.from(checkData['items'] as List<dynamic>? ?? []);
        final updatedAt = checkData['updatedAt'] as DateTime?;
        final timeFormat = DateFormat('HH:mm');
        final timeStr = updatedAt != null ? timeFormat.format(updatedAt) : '--:--';

        if (items.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Text(
              'Belum ada data checklist',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: const Color(0xFF94A3B8)),
            ),
          );
        }


        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              // Header: Masuk
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  border: Border(
                    bottom: BorderSide(color: const Color(0xFFE2E8F0)),
                  ),
                ),
                child: Text(
                  'Masuk',
                  style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF475569)),
                ),
              ),
              ...items.asMap().entries.map((entry) {
                final item = entry.value;
                final isChecked = (item['masuk'] as bool?) ?? false;
                final name = item['item_name'] ?? '-';
                final qty = item['qty'] ?? 0;
                return _buildChecklistRow(
                  name: '$name (x$qty)',
                  isChecked: isChecked,
                  timeStr: timeStr,
                  userName: item['user_name'] ?? 'User',
                  isLast: entry.key == items.length - 1,
                );
              }),
              // Header: Keluar
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  border: const Border(
                    top: BorderSide(color: Color(0xFFE2E8F0)),
                    bottom: BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                ),
                child: Text(
                  'Keluar',
                  style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF475569)),
                ),
              ),
              ...items.asMap().entries.map((entry) {
                final item = entry.value;
                final isChecked = (item['keluar'] as bool?) ?? false;
                final name = item['item_name'] ?? '-';
                final qty = item['qty'] ?? 0;
                return _buildChecklistRow(
                  name: '$name (x$qty)',
                  isChecked: isChecked,
                  timeStr: timeStr,
                  userName: item['user_name'] ?? 'User',
                  isLast: entry.key == items.length - 1,
                  isLastSection: true,
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChecklistRow({
    required String name,
    required bool isChecked,
    required String timeStr,
    required String userName,
    bool isLast = false,
    bool isLastSection = false,
  }) {
    final color = isChecked ? Colors.green : Colors.red;
    final icon = isChecked ? Icons.check_circle : Icons.cancel;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: (isLast && isLastSection)
              ? BorderSide.none
              : const BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        timeStr,
                        style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF64748B)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isChecked ? 'kasir: $userName' : 'tidak sesuai',
                    style: GoogleFonts.poppins(fontSize: 12, fontStyle: FontStyle.italic, color: color),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionList(List<QueueModel> queues, bool isBooth) {
    if (queues.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Text(
          'Tidak ada transaksi',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(color: const Color(0xFF94A3B8)),
        ),
      );
    }
    
    final timeFormat = DateFormat('HH:mm');

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: queues.length,
      itemBuilder: (context, index) {
        final q = queues[index];
        final isSelesai = q.status == 'SELESAI';
        final isBatal = q.status == 'BATAL';
        
        Color statusColor = Colors.orange; // MENUNGGU
        IconData statusIcon = Icons.access_time_filled;
        if (isSelesai) {
          statusColor = Colors.green;
          statusIcon = Icons.check_circle;
        } else if (isBatal) {
          statusColor = Colors.red;
          statusIcon = Icons.cancel;
        }

        final timeString = q.createdAt != null ? timeFormat.format(q.createdAt!) : '--:--';

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: const Color(0xFFE2E8F0), width: 1),
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showTransactionDetail(context, q, isBooth),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(statusIcon, color: statusColor, size: 20),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  q.name,
                                  style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                timeString,
                                style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF64748B)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'kasir: ${q.kasirName ?? 'Kasir'}',
                            style: GoogleFonts.poppins(fontSize: 12, fontStyle: FontStyle.italic, color: const Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showTransactionDetail(BuildContext context, QueueModel queue, bool isBooth) {
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
    final timeFormat = DateFormat('dd MMM yyyy, HH:mm');
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Detail Transaksi',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow('Nama Pelanggan', queue.name),
                _buildDetailRow('Waktu Transaksi', queue.createdAt != null ? timeFormat.format(queue.createdAt!) : '-'),
                _buildDetailRow('Tipe Layanan', queue.type),
                _buildDetailRow('Status', queue.status),
                _buildDetailRow('Metode Pembayaran', queue.paymentMethod),
                
                if (queue.paymentMethod == 'Split' && queue.splitPayments != null) ...[
                  const Divider(),
                  const Text('Detail Split Payment:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...queue.splitPayments!.entries.map((e) => 
                    _buildDetailRow('  - ${e.key}', currency.format(e.value))
                  ),
                ],
                
                const Divider(),
                
                if (isBooth)
                  _buildDetailRow('Total Strip', '${queue.totalStrips} Strip')
                else if (queue.items != null) ...[
                  Text('Detail Item:', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...queue.items!.map((item) {
                    final qty = item['qty'] ?? 1;
                    final price = item['price'] ?? 0;
                    final total = qty * price;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '${item['type']} (x$qty)',
                              style: GoogleFonts.poppins(fontSize: 13),
                            ),
                          ),
                          Text(
                            currency.format(total),
                            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                ],
                
                const Divider(),
                _buildDetailRow('Total Pembayaran', currency.format(queue.totalPayment), isBold: true),
                const SizedBox(height: 4),
                _buildDetailRow('Dilakukan Oleh', queue.kasirName ?? 'Kasir (Data lama)'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Tutup',
                style: GoogleFonts.poppins(color: const Color(0xFFAC282C), fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                color: Colors.grey[600],
                fontSize: 13,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                fontSize: isBold ? 15 : 13,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
