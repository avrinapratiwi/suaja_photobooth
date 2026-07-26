import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/event_model.dart';
import '../models/queue_model.dart';
import '../services/firebase_service.dart';

class RekapDetailView extends StatefulWidget {
  final EventModel event;

  const RekapDetailView({
    Key? key,
    required this.event,
  }) : super(key: key);

  @override
  State<RekapDetailView> createState() => _RekapDetailViewState();
}

class _RekapDetailViewState extends State<RekapDetailView> with SingleTickerProviderStateMixin {
  final FirebaseService _firebaseService = FirebaseService();
  late Future<Map<String, dynamic>> _dataFuture;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _dataFuture = _firebaseService.getEventTransactions(widget.event.id, widget.event.date);
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

    return FutureBuilder<Map<String, dynamic>>(
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
        
        return Stack(
          children: [
            // Top Summary Section
            SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.event.name,
                      style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 16),
                    
                    // Grid of metrics
                    LayoutBuilder(
                      builder: (context, constraints) {
                        return GridView.count(
                          crossAxisCount: constraints.maxWidth > 600 ? 4 : 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 2.2,
                          children: [
                            _buildMetricCard('Sesi Booth Selesai', '${data['boothSelesai']}', Icons.check_circle, Colors.green),
                            _buildMetricCard('Sesi Booth Batal', '${data['boothBatal']}', Icons.cancel, Colors.red),
                            _buildMetricCard('Cash Booth', currency.format(data['boothCash']), Icons.money, Colors.teal),
                            _buildMetricCard('QRIS Booth', currency.format(data['boothQris']), Icons.qr_code, Colors.blue),
                            _buildMetricCard('Cash Aksesoris', currency.format(data['aksesorisCash']), Icons.money, Colors.orange),
                            _buildMetricCard('QRIS Aksesoris', currency.format(data['aksesorisQris']), Icons.qr_code, Colors.deepPurple),
                            _buildMetricCard('Total Komisi', currency.format(data['komisi']), Icons.money_off, Colors.redAccent),
                            _buildMetricCard('Sub Total Booth', currency.format(data['subTotalBooth']), Icons.account_balance_wallet, const Color(0xFFAC282C)),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 400), // extra padding to allow scrolling past bottom sheet
                  ],
                ),
              ),
            ),
            
            // Draggable Bottom Sheet
            DraggableScrollableSheet(
              initialChildSize: 0.35,
              minChildSize: 0.35,
              maxChildSize: 1.0,
              builder: (context, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      // Grabber
                      GestureDetector(
                        onVerticalDragUpdate: (details) {
                          // Allow dragging the sheet from the grabber area
                          final double fraction = details.primaryDelta! / MediaQuery.of(context).size.height;
                          scrollController.jumpTo(scrollController.offset - fraction * 500); // Approximation to help drag
                        },
                        child: Container(
                          color: Colors.transparent, // target area
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Center(
                            child: Container(
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      // TabBar for Transactions
                      Container(
                        color: Colors.white,
                        child: TabBar(
                          controller: _tabController,
                          labelColor: const Color(0xFFAC282C),
                          unselectedLabelColor: Colors.grey,
                          indicatorColor: const Color(0xFFAC282C),
                          tabs: const [
                            Tab(text: 'Transaksi Booth'),
                            Tab(text: 'Transaksi Aksesoris'),
                          ],
                        ),
                      ),
                      
                      // TabBarView for the lists
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildTransactionList(boothQueues, scrollController, true),
                            _buildTransactionList(aksesorisQueues, scrollController, false),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(fontSize: 10, color: color, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList(List<QueueModel> queues, ScrollController scrollController, bool isBooth) {
    if (queues.isEmpty) {
      return Center(
        child: Text(
          'Tidak ada transaksi',
          style: GoogleFonts.poppins(color: Colors.grey),
        ),
      );
    }
    
    final timeFormat = DateFormat('HH:mm');

    return ListView.builder(
      controller: scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
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
        
        // Penomoran ascending (1 terlama, karena sudah disort ascending)
        final transactionNumber = index + 1;
        
        final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
        final totalBayarStr = currency.format(q.totalPayment);
        
        final displayName = isBooth ? q.name : 'Transaksi $totalBayarStr';
        final dialogTitle = isBooth ? 'Transaksi ${q.name}' : 'Transaksi $transactionNumber';
        
        final timeDisplay = q.createdAt != null ? timeFormat.format(q.createdAt!) : '-';

        return InkWell(
          onTap: () => _showDetailDialog(q, isBooth, dialogTitle),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200, width: 1),
              ),
            ),
            child: Row(
              children: [
                // Nomor
                SizedBox(
                  width: 28,
                  child: Text(
                    '$transactionNumber.',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ),
                // Badge Icon
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
                  child: Text(
                    displayName,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ),
                Text(
                  timeDisplay,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDetailDialog(QueueModel q, bool isBooth, String titleStr) {
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                    border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        titleStr,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFAC282C),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(Icons.close, color: Color(0xFF64748B), size: 24),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isBooth) ...[
                        // Tampilan untuk Booth
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${q.totalStrips}x Strip',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              currency.format(q.totalPayment),
                              style: const TextStyle(
                                fontSize: 16,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Divider(color: Color(0xFFE2E8F0)),
                        const SizedBox(height: 16),
                      ] else if (q.items != null && q.items!.isNotEmpty) ...[
                        // Tampilan untuk Aksesoris
                        ...q.items!.map((item) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${item['qty']}x ${item['type']}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                Text(
                                  currency.format((item['price'] as int) * (item['qty'] as int)),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        const SizedBox(height: 8),
                        const Divider(color: Color(0xFFE2E8F0)),
                        const SizedBox(height: 16),
                      ],
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Bayar',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          Text(
                            currency.format(q.totalPayment),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFAC282C),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Metode',
                            style: TextStyle(
                              fontSize: 16,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          Text(
                            q.paymentMethod,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                      if (q.paymentMethod == 'Split' && q.splitPayments != null) ...[
                        const SizedBox(height: 8),
                        ...q.splitPayments!.entries.map((e) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '  • ${e.key}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                                Text(
                                  currency.format(e.value),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

