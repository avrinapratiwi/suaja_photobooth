import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../models/event_model.dart';
import '../models/queue_model.dart';
import '../services/firebase_service.dart';
import '../widgets/notification_bell.dart';

class KasirEventDetailScreen extends StatefulWidget {
  final EventModel event;

  const KasirEventDetailScreen({super.key, required this.event});

  @override
  State<KasirEventDetailScreen> createState() => _KasirEventDetailScreenState();
}

class _KasirEventDetailScreenState extends State<KasirEventDetailScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  late Future<Map<String, dynamic>> _dataFuture;

  static const Color _headerBg = Color(0xFFE57373); // Pastel Red
  static const Color _borderColor = Color(0xFFE2E8F0);

  @override
  void initState() {
    super.initState();
    _dataFuture = _firebaseService.getEventTransactions(
        widget.event.id, widget.event.date);
  }

  String _getTimeRangeString(
      List<QueueModel> booth, List<QueueModel> aksesoris) {
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
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowLeft, color: Color(0xFF1E293B)),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Transaksi Event',
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
          bottom: TabBar(
            indicatorColor: const Color(0xFFAC282C),
            labelColor: const Color(0xFFAC282C),
            unselectedLabelColor: const Color(0xFF64748B),
            labelStyle:
                GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13),
            unselectedLabelStyle: GoogleFonts.poppins(fontSize: 13),
            tabs: const [
              Tab(text: 'Booth'),
              Tab(text: 'Aksesoris'),
              Tab(text: 'Checklist Set'),
            ],
          ),
        ),
        body: FutureBuilder<Map<String, dynamic>>(
          future: _dataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                  child: Text('Error: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red)));
            }

            final data = snapshot.data!;
            final boothQueues = data['boothQueues'] as List<QueueModel>;
            final aksesorisQueues =
                data['aksesorisQueues'] as List<QueueModel>;
            final timeRange =
                _getTimeRangeString(boothQueues, aksesorisQueues);
            final currency = NumberFormat.currency(
                locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

            // Metrics Booth
            int boothSelesai =
                boothQueues.where((q) => q.status == 'SELESAI').length;
            int boothBatal =
                boothQueues.where((q) => q.status == 'BATAL').length;
            int boothCash = 0;
            int boothQris = 0;
            for (var q in boothQueues) {
              if (q.status == 'SELESAI') {
                if (q.paymentMethod == 'Cash') {
                  boothCash += q.totalPayment;
                } else if (q.paymentMethod == 'QRIS') {
                  boothQris += q.totalPayment;
                } else if (q.paymentMethod == 'Split' &&
                    q.splitPayments != null) {
                  boothCash += (q.splitPayments!['Cash'] ?? 0) as int;
                  boothQris += (q.splitPayments!['QRIS'] ?? 0) as int;
                }
              }
            }
            final int komisi = boothSelesai * 5000;
            final int subTotalBooth = boothCash - komisi;

            // Metrics Aksesoris
            int aksesorisItemTerjual = 0;
            int aksesorisItemBatal = 0;
            int aksesorisCash = 0;
            int aksesorisQris = 0;
            final eventDay = DateTime(widget.event.date.year,
                widget.event.date.month, widget.event.date.day);
            for (var q in aksesorisQueues) {
              final qDay = q.createdAt != null
                  ? DateTime(q.createdAt!.year, q.createdAt!.month,
                      q.createdAt!.day)
                  : null;
              if (q.status == 'SELESAI') {
                if (qDay != null && qDay == eventDay && q.items != null) {
                  for (var item in q.items!) {
                    aksesorisItemTerjual +=
                        (item['qty'] as num?)?.toInt() ?? 0;
                  }
                }
                if (q.paymentMethod == 'Cash') {
                  aksesorisCash += q.totalPayment;
                } else if (q.paymentMethod == 'QRIS') {
                  aksesorisQris += q.totalPayment;
                } else if (q.paymentMethod == 'Split' &&
                    q.splitPayments != null) {
                  aksesorisCash += (q.splitPayments!['Cash'] ?? 0) as int;
                  aksesorisQris += (q.splitPayments!['QRIS'] ?? 0) as int;
                }
              } else if (q.status == 'BATAL') {
                if (qDay != null && qDay == eventDay && q.items != null) {
                  for (var item in q.items!) {
                    aksesorisItemBatal +=
                        (item['qty'] as num?)?.toInt() ?? 0;
                  }
                }
              }
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Event Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.event.name,
                        style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.access_time_rounded,
                              size: 16, color: Color(0xFF64748B)),
                          const SizedBox(width: 6),
                          Text(
                            timeRange,
                            style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: const Color(0xFF64748B)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),

                Expanded(
                  child: TabBarView(
                    children: [
                      // Tab 1: Booth
                      SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildBoothTable(boothQueues, currency),
                            const SizedBox(height: 20),
                            _buildBoothIndicators(boothSelesai, boothBatal,
                                boothCash, boothQris, komisi, subTotalBooth, currency),
                          ],
                        ),
                      ),
                      // Tab 2: Aksesoris
                      SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildAksesorisTable(aksesorisQueues, currency),
                            const SizedBox(height: 20),
                            _buildAksesorisIndicators(aksesorisItemTerjual,
                                aksesorisItemBatal, aksesorisCash, aksesorisQris, currency),
                          ],
                        ),
                      ),
                      // Tab 3: Checklist
                      SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: _buildChecklistTable(),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ── Booth Table (tanpa kolom Kasir) ──────────────────────────
  Widget _buildBoothTable(List<QueueModel> queues, NumberFormat currency) {
    if (queues.isEmpty) return _emptyState('Tidak ada transaksi booth');

    final dtFormat = DateFormat('dd/MM/yy\nHH:mm');

    const headers = ['No', 'Tgl/Waktu', 'Pelanggan', 'Strip', 'Pembayaran', 'Total', 'Status'];
    const columnWidths = [
      FixedColumnWidth(40),
      FixedColumnWidth(95),
      FlexColumnWidth(2),
      FixedColumnWidth(50),
      FixedColumnWidth(140),
      FixedColumnWidth(110),
      FixedColumnWidth(80),
    ];

    final rows = queues.asMap().entries.map((entry) {
      final i = entry.key;
      final q = entry.value;
      final isEven = i % 2 == 0;
      final statusColor = q.status == 'SELESAI'
          ? Colors.green
          : q.status == 'BATAL'
              ? Colors.red
              : Colors.orange;

      Widget paymentWidget;
      if (q.paymentMethod == 'Split' && q.splitPayments != null) {
        paymentWidget = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Cash: ${currency.format(q.splitPayments!['Cash'] ?? 0)}', style: _ts(9)),
            Text('QRIS: ${currency.format(q.splitPayments!['QRIS'] ?? 0)}', style: _ts(9)),
          ],
        );
      } else {
        paymentWidget = Text(q.paymentMethod, style: _ts());
      }

      return TableRow(
        decoration: BoxDecoration(color: isEven ? Colors.white : const Color(0xFFF8FAFC)),
        children: [
          _cell(Text('${i + 1}', style: _ts(), textAlign: TextAlign.center)),
          _cell(Text(q.createdAt != null ? dtFormat.format(q.createdAt!) : '-', style: _ts(), textAlign: TextAlign.center)),
          _cell(Text(q.name, style: _ts())),
          _cell(Text('${q.totalStrips}', style: _ts(), textAlign: TextAlign.center)),
          _cell(paymentWidget),
          _cell(Text(currency.format(q.totalPayment), style: _ts())),
          _cell(Center(child: _statusBadge(q.status, statusColor))),
        ],
      );
    }).toList();

    return _tableWrapper(headers: headers, columnWidths: columnWidths, rows: rows, minWidth: 680);
  }

  // ── Aksesoris Table (tanpa kolom Kasir) ─────────────────────
  Widget _buildAksesorisTable(List<QueueModel> queues, NumberFormat currency) {
    if (queues.isEmpty) return _emptyState('Tidak ada transaksi aksesoris');

    final dtFormat = DateFormat('dd/MM/yy\nHH:mm');

    const headers = ['No', 'Tgl/Waktu', 'Detail Item', 'Jml', 'Pembayaran', 'Total', 'Status'];
    const columnWidths = [
      FixedColumnWidth(40),
      FixedColumnWidth(95),
      FlexColumnWidth(2.5),
      FixedColumnWidth(50),
      FixedColumnWidth(140),
      FixedColumnWidth(110),
      FixedColumnWidth(80),
    ];

    final rows = queues.asMap().entries.map((entry) {
      final i = entry.key;
      final q = entry.value;
      final isEven = i % 2 == 0;
      final statusColor = q.status == 'SELESAI'
          ? Colors.green
          : q.status == 'BATAL'
              ? Colors.red
              : Colors.orange;

      int totalQty = 0;
      Widget itemDetail;
      if (q.items != null && q.items!.isNotEmpty) {
        totalQty = q.items!
            .fold(0, (s, it) => s + ((it['qty'] as num?)?.toInt() ?? 0));
        itemDetail = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: q.items!
              .map((it) => Text('${it['qty']}x ${it['type']}',
                  style: _ts(9), maxLines: 1, overflow: TextOverflow.ellipsis))
              .toList(),
        );
      } else {
        itemDetail = Text('-', style: _ts());
      }

      Widget paymentWidget;
      if (q.paymentMethod == 'Split' && q.splitPayments != null) {
        paymentWidget = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Cash: ${currency.format(q.splitPayments!['Cash'] ?? 0)}', style: _ts(9)),
            Text('QRIS: ${currency.format(q.splitPayments!['QRIS'] ?? 0)}', style: _ts(9)),
          ],
        );
      } else {
        paymentWidget = Text(q.paymentMethod, style: _ts());
      }

      return TableRow(
        decoration: BoxDecoration(color: isEven ? Colors.white : const Color(0xFFF8FAFC)),
        children: [
          _cell(Text('${i + 1}', style: _ts(), textAlign: TextAlign.center)),
          _cell(Text(q.createdAt != null ? dtFormat.format(q.createdAt!) : '-', style: _ts(), textAlign: TextAlign.center)),
          _cell(itemDetail),
          _cell(Text('$totalQty', style: _ts(), textAlign: TextAlign.center)),
          _cell(paymentWidget),
          _cell(Text(currency.format(q.totalPayment), style: _ts())),
          _cell(Center(child: _statusBadge(q.status, statusColor))),
        ],
      );
    }).toList();

    return _tableWrapper(headers: headers, columnWidths: columnWidths, rows: rows, minWidth: 680);
  }

  // ── Checklist Table ──────────────────────────────────────────
  Widget _buildChecklistTable() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _firebaseService.getChecklistFull(
          eventId: widget.event.id, date: widget.event.date),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator()));
        }

        final checkData = snapshot.data ??
            {'items': <Map<String, dynamic>>[], 'updatedAt': null};
        final items = List<Map<String, dynamic>>.from(
            checkData['items'] as List<dynamic>? ?? []);

        if (items.isEmpty) return _emptyState('Belum ada data checklist');

        final updatedAt = checkData['updatedAt'] as DateTime?;
        final dtFormat = DateFormat('dd/MM/yy\nHH:mm');
        final dateStr = updatedAt != null ? dtFormat.format(updatedAt) : '-';

        const headers = ['No', 'Tgl/Waktu', 'Nama Barang', 'Jml', 'Masuk', 'Keluar'];
        const columnWidths = [
          FixedColumnWidth(40),
          FixedColumnWidth(95),
          FlexColumnWidth(3),
          FixedColumnWidth(50),
          FixedColumnWidth(60),
          FixedColumnWidth(60),
        ];

        final rows = items.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          final isEven = i % 2 == 0;
          final masuk = (item['masuk'] as bool?) ?? false;
          final keluar = (item['keluar'] as bool?) ?? false;

          Widget checkIcon(bool val) => Center(
                child: Icon(
                  val ? Icons.check_circle : Icons.cancel,
                  color: val ? Colors.green : Colors.red,
                  size: 18,
                ),
              );

          return TableRow(
            decoration: BoxDecoration(color: isEven ? Colors.white : const Color(0xFFF8FAFC)),
            children: [
              _cell(Text('${i + 1}', style: _ts(), textAlign: TextAlign.center)),
              _cell(Text(dateStr, style: _ts(), textAlign: TextAlign.center)),
              _cell(Text(item['item_name'] ?? '-', style: _ts())),
              _cell(Text('${item['qty'] ?? 0}', style: _ts(), textAlign: TextAlign.center)),
              _cell(checkIcon(masuk)),
              _cell(checkIcon(keluar)),
            ],
          );
        }).toList();

        return _tableWrapper(headers: headers, columnWidths: columnWidths, rows: rows, minWidth: 500);
      },
    );
  }

  // ── Indicators ───────────────────────────────────────────────
  Widget _buildBoothIndicators(int selesai, int batal, int cash, int qris,
      int komisi, int bersih, NumberFormat currency) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _borderColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            _indicRow('Sesi Booth Selesai', '$selesai'),
            const SizedBox(height: 8),
            _indicRow('Sesi Booth Batal', '$batal'),
            const SizedBox(height: 8),
            _indicRow('Cash Booth', currency.format(cash)),
            const SizedBox(height: 8),
            _indicRow('QRIS Booth', currency.format(qris)),
            const SizedBox(height: 8),
            _indicRow('Komisi Panitia', '-${currency.format(komisi)}',
                valueColor: Colors.red),
            const Padding(
                padding: EdgeInsets.symmetric(vertical: 6), child: Divider()),
            _indicRow('Total Cash Booth', currency.format(bersih), isBold: true),
          ],
        ),
      ),
    );
  }

  Widget _buildAksesorisIndicators(int terjual, int batal, int cash, int qris, NumberFormat currency) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _borderColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            _indicRow('Item Terjual', '$terjual'),
            const SizedBox(height: 8),
            _indicRow('Item Dibatalkan', '$batal'),
            const SizedBox(height: 8),
            _indicRow('Cash Aksesoris', currency.format(cash)),
            const SizedBox(height: 8),
            _indicRow('QRIS Aksesoris', currency.format(qris)),
          ],
        ),
      ),
    );
  }

  Widget _indicRow(String label, String value,
      {Color? valueColor, bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: const Color(0xFF1E293B))),
        Text(value,
            style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                color: valueColor ?? const Color(0xFF0F172A))),
      ],
    );
  }

  // ── Helpers ──────────────────────────────────────────────────
  Widget _tableWrapper({
    required List<String> headers,
    required List<TableColumnWidth> columnWidths,
    required List<TableRow> rows,
    required double minWidth,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: _borderColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: constraints.maxWidth > minWidth
                      ? constraints.maxWidth
                      : minWidth,
                ),
                child: Table(
                  columnWidths: Map.fromIterables(
                      List.generate(headers.length, (i) => i), columnWidths),
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  border: const TableBorder(
                    horizontalInside: BorderSide(color: _borderColor),
                    verticalInside: BorderSide(color: _borderColor),
                  ),
                  children: [
                    TableRow(
                      decoration: const BoxDecoration(color: _headerBg),
                      children: headers
                          .map((h) => Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 10),
                                child: Text(h,
                                    style: GoogleFonts.poppins(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white),
                                    textAlign: TextAlign.center),
                              ))
                          .toList(),
                    ),
                    ...rows,
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _cell(Widget child) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: child);

  Widget _emptyState(String msg) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _borderColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(msg,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(color: const Color(0xFF94A3B8))),
      );

  TextStyle _ts([double size = 10.0]) =>
      GoogleFonts.poppins(fontSize: size, color: const Color(0xFF1E293B));

  Widget _statusBadge(String status, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(status,
            style: GoogleFonts.poppins(
                fontSize: 8, fontWeight: FontWeight.bold, color: color),
            textAlign: TextAlign.center),
      );
}
