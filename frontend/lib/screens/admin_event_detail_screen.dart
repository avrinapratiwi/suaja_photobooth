import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../models/event_model.dart';
import '../models/queue_model.dart';
import '../models/user_model.dart';
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

  static const Color _headerBg = Color(0xFFAC282C); // Suaja Red (Theme Color)
  static const Color _borderColor = Color(0xFFE2E8F0);

  // Filter States
  String _searchQuery = '';
  String? _selectedStatus;
  String? _selectedPayment;
  String? _selectedKasir;
  bool _isFilterOpen = false;
  List<UserModel> _cashiers = [];

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _dataFuture = _firebaseService.getEventTransactions(
        widget.event.id, widget.event.date);
    _loadCashiers();
  }

  Future<void> _loadCashiers() async {
    final list = await _firebaseService.getCashiers();
    setState(() {
      _cashiers = list;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  Widget _buildSearchAndFilterRow() {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 44,
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
              decoration: InputDecoration(
                hintText: 'Cari pelanggan atau item...',
                hintStyle: GoogleFonts.poppins(
                    fontSize: 13, color: const Color(0xFF94A3B8)),
                prefixIcon: const Icon(LucideIcons.search,
                    size: 18, color: Color(0xFF64748B)),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                    vertical: 0, horizontal: 16),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: _borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFAC282C)),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          height: 44,
          child: ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _isFilterOpen = !_isFilterOpen;
              });
            },
            icon: const Icon(LucideIcons.sliders, size: 16),
            label: Text(
              'Filter',
              style: GoogleFonts.poppins(
                  fontSize: 13, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFAC282C),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
        ),
      ],
    );
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
          bottom: TabBar(
            indicatorColor: const Color(0xFFAC282C),
            labelColor: const Color(0xFFAC282C),
            unselectedLabelColor: const Color(0xFF64748B),
            labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13),
            unselectedLabelStyle: GoogleFonts.poppins(fontSize: 13),
            tabs: const [
              Tab(text: 'Booth'),
              Tab(text: 'Aksesoris'),
              Tab(text: 'Checklist Set'),
            ],
          ),
        ),
        body: Stack(
          children: [
            FutureBuilder<Map<String, dynamic>>(
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
                final aksesorisQueues = data['aksesorisQueues'] as List<QueueModel>;
                final timeRange =
                    _getTimeRangeString(boothQueues, aksesorisQueues);
                final currency = NumberFormat.currency(
                    locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

                // Apply Filters
                final filteredBooth = boothQueues.where((q) {
                  final matchSearch = _searchQuery.isEmpty ||
                      q.name.toLowerCase().contains(_searchQuery.toLowerCase());
                  final matchStatus = _selectedStatus == null || q.status == _selectedStatus;
                  final matchPayment = _selectedPayment == null || q.paymentMethod == _selectedPayment;
                  final matchKasir = _selectedKasir == null ||
                      (q.kasirName ?? '').toLowerCase() == _selectedKasir!.toLowerCase();
                  return matchSearch && matchStatus && matchPayment && matchKasir;
                }).toList();

                final filteredAksesoris = aksesorisQueues.where((q) {
                  final matchSearch = _searchQuery.isEmpty ||
                      q.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                      (q.items != null &&
                          q.items!.any((item) => (item['type'] as String? ?? '')
                              .toLowerCase()
                              .contains(_searchQuery.toLowerCase())));
                  final matchStatus = _selectedStatus == null || q.status == _selectedStatus;
                  final matchPayment = _selectedPayment == null || q.paymentMethod == _selectedPayment;
                  final matchKasir = _selectedKasir == null ||
                      (q.kasirName ?? '').toLowerCase() == _selectedKasir!.toLowerCase();
                  return matchSearch && matchStatus && matchPayment && matchKasir;
                }).toList();

                // Recalculate Metrics for Filtered Data
                int boothSelesai = filteredBooth.where((q) => q.status == 'SELESAI').length;
                int boothBatal = filteredBooth.where((q) => q.status == 'BATAL').length;

                int boothCash = 0;
                int boothQris = 0;
                for (var q in filteredBooth) {
                  if (q.status == 'SELESAI') {
                    if (q.paymentMethod == 'Cash') {
                      boothCash += q.totalPayment;
                    } else if (q.paymentMethod == 'QRIS') {
                      boothQris += q.totalPayment;
                    } else if (q.paymentMethod == 'Split' && q.splitPayments != null) {
                      boothCash += (q.splitPayments!['Cash'] ?? 0) as int;
                      boothQris += (q.splitPayments!['QRIS'] ?? 0) as int;
                    }
                  }
                }
                int komisi = boothSelesai * 5000;
                int subTotalBooth = boothCash - komisi;

                int aksesorisItemTerjual = 0;
                int aksesorisItemBatal = 0;
                int aksesorisCash = 0;
                int aksesorisQris = 0;
                final eventDay = DateTime(
                    widget.event.date.year, widget.event.date.month, widget.event.date.day);

                for (var q in filteredAksesoris) {
                  final qDay = q.createdAt != null
                      ? DateTime(q.createdAt!.year, q.createdAt!.month, q.createdAt!.day)
                      : null;
                  if (q.status == 'SELESAI') {
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
                    if (qDay != null && qDay == eventDay && q.items != null) {
                      for (var item in q.items!) {
                        aksesorisItemBatal += (item['qty'] as num?)?.toInt() ?? 0;
                      }
                    }
                  }
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Event Header ──────────────────────────────
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
                                    fontSize: 14, color: const Color(0xFF64748B)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),

                    // TabBarView for Content
                    Expanded(
                      child: TabBarView(
                        children: [
                          // Tab 1: Booth
                          SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSearchAndFilterRow(),
                                const SizedBox(height: 16),
                                _buildBoothTable(filteredBooth),
                                const SizedBox(height: 20),
                                _buildBoothIndicators(
                                  boothSelesai,
                                  boothBatal,
                                  boothCash,
                                  boothQris,
                                  komisi,
                                  subTotalBooth,
                                  currency,
                                ),
                              ],
                            ),
                          ),
                          // Tab 2: Aksesoris
                          SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSearchAndFilterRow(),
                                const SizedBox(height: 16),
                                _buildAksesorisTable(filteredAksesoris),
                                const SizedBox(height: 20),
                                _buildAksesorisIndicators(
                                  aksesorisItemTerjual,
                                  aksesorisItemBatal,
                                  aksesorisCash,
                                  aksesorisQris,
                                  currency,
                                ),
                              ],
                            ),
                          ),
                          // Tab 3: Checklist Set
                          SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildChecklistTable(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),

            // Sliding filter panel overlay
            if (_isFilterOpen) ...[
              GestureDetector(
                onTap: () => setState(() => _isFilterOpen = false),
                child: Container(
                  color: Colors.black.withOpacity(0.4),
                ),
              ),
              Positioned(
                top: 0,
                bottom: 0,
                right: 0,
                left: MediaQuery.of(context).size.width > 600
                    ? MediaQuery.of(context).size.width * 0.25
                    : 0,
                child: Material(
                  elevation: 16,
                  child: Container(
                    color: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          color: const Color(0xFFFFF1F2), // Theme pastel (Red 50)
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Filter Laporan',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFAC282C),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(LucideIcons.x, color: Color(0xFFAC282C)),
                                onPressed: () => setState(() => _isFilterOpen = false),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Filter Status
                                Text('Status',
                                    style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF475569))),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<String>(
                                  value: _selectedStatus,
                                  hint: Text('Semua Status',
                                      style: GoogleFonts.poppins(fontSize: 13)),
                                  decoration: InputDecoration(
                                    contentPadding:
                                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(color: _borderColor)),
                                    enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(color: _borderColor)),
                                    focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(color: Color(0xFFAC282C))),
                                  ),
                                  items: const [
                                    DropdownMenuItem(value: null, child: Text('Semua Status')),
                                    DropdownMenuItem(value: 'SELESAI', child: Text('Selesai')),
                                    DropdownMenuItem(value: 'BATAL', child: Text('Batal')),
                                  ],
                                  onChanged: (val) => setState(() => _selectedStatus = val),
                                ),
                                const SizedBox(height: 20),

                                // Filter Pembayaran
                                Text('Metode Pembayaran',
                                    style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF475569))),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<String>(
                                  value: _selectedPayment,
                                  hint: Text('Semua Metode',
                                      style: GoogleFonts.poppins(fontSize: 13)),
                                  decoration: InputDecoration(
                                    contentPadding:
                                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(color: _borderColor)),
                                    enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(color: _borderColor)),
                                    focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(color: Color(0xFFAC282C))),
                                  ),
                                  items: const [
                                    DropdownMenuItem(value: null, child: Text('Semua Metode')),
                                    DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                                    DropdownMenuItem(value: 'QRIS', child: Text('QRIS')),
                                    DropdownMenuItem(value: 'Split', child: Text('Split')),
                                  ],
                                  onChanged: (val) => setState(() => _selectedPayment = val),
                                ),
                                const SizedBox(height: 20),

                                // Filter Kasir
                                Text('Kasir',
                                    style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF475569))),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<String>(
                                  value: _selectedKasir,
                                  hint: Text('Semua Kasir',
                                      style: GoogleFonts.poppins(fontSize: 13)),
                                  decoration: InputDecoration(
                                    contentPadding:
                                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(color: _borderColor)),
                                    enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(color: _borderColor)),
                                    focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(color: Color(0xFFAC282C))),
                                  ),
                                  items: [
                                    const DropdownMenuItem<String>(
                                        value: null, child: Text('Semua Kasir')),
                                    ..._cashiers.map((c) => DropdownMenuItem<String>(
                                          value: c.name,
                                          child: Text(c.name),
                                        )),
                                  ],
                                  onChanged: (val) => setState(() => _selectedKasir = val),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    setState(() {
                                      _selectedStatus = null;
                                      _selectedPayment = null;
                                      _selectedKasir = null;
                                      _isFilterOpen = false;
                                    });
                                  },
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Color(0xFFAC282C)),
                                    foregroundColor: const Color(0xFFAC282C),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8)),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                  ),
                                  child: Text('Reset',
                                      style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.bold)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => setState(() => _isFilterOpen = false),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFAC282C),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8)),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                  ),
                                  child: Text('Terapkan',
                                      style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ============================================================
  // BOOTH TABLE
  // ============================================================
  Widget _buildBoothTable(List<QueueModel> queues) {
    if (queues.isEmpty) {
      return _buildEmptyState('Tidak ada transaksi booth');
    }

    final currency =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
    final dtFormat = DateFormat('dd/MM/yy\nHH:mm');

    const headers = ['No', 'Tgl/Waktu', 'Pelanggan', 'Strip', 'Pembayaran', 'Total', 'Status', 'Kasir'];
    const columnWidths = [
      FixedColumnWidth(40),
      FixedColumnWidth(95),
      FlexColumnWidth(2),
      FixedColumnWidth(50),
      FixedColumnWidth(140),
      FixedColumnWidth(100),
      FixedColumnWidth(80),
      FlexColumnWidth(1.5),
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
            Text('Cash: ${currency.format(q.splitPayments!['Cash'] ?? 0)}',
                style: _ts(9)),
            Text('QRIS: ${currency.format(q.splitPayments!['QRIS'] ?? 0)}',
                style: _ts(9)),
          ],
        );
      } else {
        paymentWidget =
            Text(q.paymentMethod, style: _ts());
      }

      final cellBg = isEven ? Colors.white : const Color(0xFFF8FAFC);

      return TableRow(
        decoration: BoxDecoration(color: cellBg),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            child: Text('${i + 1}', style: _ts(), textAlign: TextAlign.center),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            child: Text(q.createdAt != null ? dtFormat.format(q.createdAt!) : '-',
                style: _ts(), textAlign: TextAlign.center),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            child: Text(q.name, style: _ts()),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            child: Text('${q.totalStrips}', style: _ts(), textAlign: TextAlign.center),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            child: paymentWidget,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            child: Text(currency.format(q.totalPayment), style: _ts()),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            child: Center(child: _statusBadge(q.status, statusColor)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            child: Text(q.kasirName ?? '-', style: _ts()),
          ),
        ],
      );
    }).toList();

    return _tableWrapper(
      headers: headers,
      columnWidths: columnWidths,
      rows: rows,
      minWidth: 780,
    );
  }

  // ============================================================
  // AKSESORIS TABLE
  // ============================================================
  Widget _buildAksesorisTable(List<QueueModel> queues) {
    if (queues.isEmpty) {
      return _buildEmptyState('Tidak ada transaksi aksesoris');
    }

    final currency =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
    final dtFormat = DateFormat('dd/MM/yy\nHH:mm');

    const headers = ['No', 'Tgl/Waktu', 'Detail Item', 'Jml', 'Pembayaran', 'Total', 'Status', 'Kasir'];
    const columnWidths = [
      FixedColumnWidth(40),
      FixedColumnWidth(95),
      FlexColumnWidth(2.5),
      FixedColumnWidth(50),
      FixedColumnWidth(140),
      FixedColumnWidth(100),
      FixedColumnWidth(80),
      FlexColumnWidth(1.5),
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

      // Detail item widget
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
                  style: _ts(9),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis))
              .toList(),
        );
      } else {
        itemDetail = Text('-', style: _ts());
      }

      // Payment widget
      Widget paymentWidget;
      if (q.paymentMethod == 'Split' && q.splitPayments != null) {
        paymentWidget = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Cash: ${currency.format(q.splitPayments!['Cash'] ?? 0)}',
                style: _ts(9)),
            Text('QRIS: ${currency.format(q.splitPayments!['QRIS'] ?? 0)}',
                style: _ts(9)),
          ],
        );
      } else {
        paymentWidget =
            Text(q.paymentMethod, style: _ts());
      }

      final cellBg = isEven ? Colors.white : const Color(0xFFF8FAFC);

      return TableRow(
        decoration: BoxDecoration(color: cellBg),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            child: Text('${i + 1}', style: _ts(), textAlign: TextAlign.center),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            child: Text(q.createdAt != null ? dtFormat.format(q.createdAt!) : '-',
                style: _ts(), textAlign: TextAlign.center),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            child: itemDetail,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            child: Text('$totalQty', style: _ts(), textAlign: TextAlign.center),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            child: paymentWidget,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            child: Text(currency.format(q.totalPayment), style: _ts()),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            child: Center(child: _statusBadge(q.status, statusColor)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            child: Text(q.kasirName ?? '-', style: _ts()),
          ),
        ],
      );
    }).toList();

    return _tableWrapper(
      headers: headers,
      columnWidths: columnWidths,
      rows: rows,
      minWidth: 800,
    );
  }

  // ============================================================
  // CHECKLIST TABLE
  // ============================================================
  Widget _buildChecklistTable() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _firebaseService.getChecklistFull(
        eventId: widget.event.id,
        date: widget.event.date,
      ),
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

        if (items.isEmpty) {
          return _buildEmptyState('Belum ada data checklist');
        }

        final updatedAt = checkData['updatedAt'] as DateTime?;
        final dtFormat = DateFormat('dd/MM/yy\nHH:mm');
        final dateStr =
            updatedAt != null ? dtFormat.format(updatedAt) : '-';

        const headers = ['No', 'Tgl/Waktu', 'Nama Barang', 'Jml', 'Masuk', 'Keluar', 'Kasir'];
        const columnWidths = [
          FixedColumnWidth(40),
          FixedColumnWidth(95),
          FlexColumnWidth(3),
          FixedColumnWidth(50),
          FixedColumnWidth(60),
          FixedColumnWidth(60),
          FlexColumnWidth(2),
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

          final cellBg = isEven ? Colors.white : const Color(0xFFF8FAFC);

          return TableRow(
            decoration: BoxDecoration(color: cellBg),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                child: Text('${i + 1}',
                    style: _ts(), textAlign: TextAlign.center),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                child: Text(dateStr, style: _ts(), textAlign: TextAlign.center),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                child: Text(item['item_name'] ?? '-', style: _ts()),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                child: Text('${item['qty'] ?? 0}',
                    style: _ts(), textAlign: TextAlign.center),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                child: checkIcon(masuk),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                child: checkIcon(keluar),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                child: Text(item['user_name'] ?? '-', style: _ts()),
              ),
            ],
          );
        }).toList();

        return _tableWrapper(
          headers: headers,
          columnWidths: columnWidths,
          rows: rows,
          minWidth: 600,
        );
      },
    );
  }

  // ============================================================
  // INDICATOR CONTAINERS (BOOTH AND AKSESORIS)
  // ============================================================
  Widget _buildBoothIndicators(
      int selesai, int batal, int cash, int qris, int komisi, int bersih, NumberFormat currency) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        width: 320,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _borderColor),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildIndicatorRow('Sesi Booth Selesai', '$selesai'),
            const SizedBox(height: 8),
            _buildIndicatorRow('Sesi Booth Batal', '$batal'),
            const SizedBox(height: 8),
            _buildIndicatorRow('Cash Booth', currency.format(cash)),
            const SizedBox(height: 8),
            _buildIndicatorRow('QRIS Booth', currency.format(qris)),
            const SizedBox(height: 8),
            _buildIndicatorRow(
              'Komisi Panitia',
              '-${currency.format(komisi)}',
              labelColor: Colors.red,
              valueColor: Colors.red,
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Divider(),
            ),
            _buildIndicatorRow(
              'Total Cash Booth',
              currency.format(bersih),
              isBold: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAksesorisIndicators(
      int terjual, int batal, int cash, int qris, NumberFormat currency) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        width: 320,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _borderColor),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildIndicatorRow('Item Terjual', '$terjual'),
            const SizedBox(height: 8),
            _buildIndicatorRow('Item Dibatalkan', '$batal'),
            const SizedBox(height: 8),
            _buildIndicatorRow('Cash Aksesoris', currency.format(cash)),
            const SizedBox(height: 8),
            _buildIndicatorRow('QRIS Aksesoris', currency.format(qris)),
          ],
        ),
      ),
    );
  }

  Widget _buildIndicatorRow(String label, String value,
      {Color? labelColor, Color? valueColor, bool isBold = false}) {
    final style = GoogleFonts.poppins(
      fontSize: 12,
      fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
      color: labelColor ?? const Color(0xFF1E293B),
    );
    final valStyle = GoogleFonts.poppins(
      fontSize: 12,
      fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
      color: valueColor ?? const Color(0xFF0F172A),
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(value, style: valStyle),
      ],
    );
  }

  // ============================================================
  // TABLE HELPERS
  // ============================================================

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
                  minWidth: constraints.maxWidth > minWidth ? constraints.maxWidth : minWidth,
                ),
                child: Table(
                  columnWidths: Map.fromIterables(
                    List.generate(headers.length, (i) => i),
                    columnWidths,
                  ),
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  border: const TableBorder(
                    horizontalInside: BorderSide(color: _borderColor),
                    verticalInside: BorderSide(color: _borderColor),
                  ),
                  children: [
                    // Header row
                    TableRow(
                      decoration: const BoxDecoration(color: _headerBg),
                      children: headers.map((header) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 10),
                          child: Text(
                            header,
                            style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                        );
                      }).toList(),
                    ),
                    // Data rows
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

  Widget _buildEmptyState(String emptyMessage) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _borderColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        emptyMessage,
        textAlign: TextAlign.center,
        style: GoogleFonts.poppins(color: const Color(0xFF94A3B8)),
      ),
    );
  }

  TextStyle _ts([double size = 10.0]) => GoogleFonts.poppins(
      fontSize: size, color: const Color(0xFF1E293B));

  Widget _statusBadge(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        status,
        style: GoogleFonts.poppins(
            fontSize: 8, fontWeight: FontWeight.bold, color: color),
        textAlign: TextAlign.center,
      ),
    );
  }
}
