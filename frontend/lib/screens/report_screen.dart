import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/firebase_service.dart';
import 'package:intl/intl.dart';
import '../widgets/notification_bell.dart';
import '../models/event_model.dart';
import '../models/queue_model.dart';
import 'admin_event_detail_screen.dart';
import '../utils/business_day_utils.dart';
import '../utils/download_helper.dart';

// PDF Package Imports
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final Color _textColor = const Color(0xFF1E293B);
  final Color _mutedText = const Color(0xFF64748B);
  static const Color _borderColor = Color(0xFFE2E8F0);
  static const Color _headerBg = Color(0xFFE57373); // Pastel Red header

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

  pw.Widget _buildPdfIndicatorRow(String label, String value, {PdfColor? valueColor, bool isBold = false}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: pw.TextStyle(fontSize: 10, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        pw.Text(value, style: pw.TextStyle(fontSize: 10, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal, color: valueColor)),
      ],
    );
  }

  Future<void> _downloadReport(BuildContext context, EventModel event) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    // Show Loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final data = await _firebaseService.getEventTransactions(event.id, event.date);
      final checklistData = await _firebaseService.getChecklistFull(eventId: event.id, date: event.date);

      final boothQueues = data['boothQueues'] as List<QueueModel>;
      final aksesorisQueues = data['aksesorisQueues'] as List<QueueModel>;
      final checklistItems = List<Map<String, dynamic>>.from(checklistData['items'] as List<dynamic>? ?? []);

      final timeRange = _getTimeRangeString(boothQueues, aksesorisQueues);

      // Calculate unique cashier names
      final uniqueCashiers = <String>{};
      for (var q in boothQueues) {
        if (q.kasirName != null) uniqueCashiers.add(q.kasirName!);
      }
      for (var q in aksesorisQueues) {
        if (q.kasirName != null) uniqueCashiers.add(q.kasirName!);
      }
      final cashiersString = uniqueCashiers.isEmpty ? '-' : uniqueCashiers.join(', ');

      // Metrics for Booth
      int boothSelesai = data['boothSelesai'] as int? ?? 0;
      int boothBatal = data['boothBatal'] as int? ?? 0;
      int boothCash = data['boothCash'] as int? ?? 0;
      int boothQris = data['boothQris'] as int? ?? 0;
      int komisi = data['komisi'] as int? ?? 0;
      int subTotalBooth = data['subTotalBooth'] as int? ?? 0;

      // Metrics for Aksesoris
      int aksesorisItemTerjual = data['aksesorisItemTerjual'] as int? ?? 0;
      int aksesorisItemBatal = data['aksesorisItemBatal'] as int? ?? 0;
      int aksesorisCash = data['aksesorisCash'] as int? ?? 0;
      int aksesorisQris = data['aksesorisQris'] as int? ?? 0;

      final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
      final dtFormat = DateFormat('dd/MM/yy HH:mm');

      // Generate Tables Data
      final boothDataList = <List<String>>[];
      for (var i = 0; i < boothQueues.length; i++) {
        final q = boothQueues[i];
        final timeStr = q.createdAt != null ? dtFormat.format(q.createdAt!) : '-';
        String pm = q.paymentMethod;
        if (q.paymentMethod == 'Split' && q.splitPayments != null) {
          pm = 'Split\n(C:${currency.format(q.splitPayments!['Cash'] ?? 0)} / Q:${currency.format(q.splitPayments!['QRIS'] ?? 0)})';
        }
        boothDataList.add([
          '${i + 1}',
          timeStr,
          q.name,
          '${q.totalStrips}',
          pm,
          currency.format(q.totalPayment),
          q.status,
          q.kasirName ?? '-',
        ]);
      }

      final aksesorisDataList = <List<String>>[];
      for (var i = 0; i < aksesorisQueues.length; i++) {
        final q = aksesorisQueues[i];
        final timeStr = q.createdAt != null ? dtFormat.format(q.createdAt!) : '-';
        int totalQty = 0;
        final detailsList = <String>[];
        if (q.items != null) {
          for (var item in q.items!) {
            final qty = (item['qty'] as num?)?.toInt() ?? 0;
            totalQty += qty;
            detailsList.add('${qty}x ${item['type']}');
          }
        }
        final detailItemStr = detailsList.join('\n');
        String pm = q.paymentMethod;
        if (q.paymentMethod == 'Split' && q.splitPayments != null) {
          pm = 'Split\n(C:${currency.format(q.splitPayments!['Cash'] ?? 0)} / Q:${currency.format(q.splitPayments!['QRIS'] ?? 0)})';
        }
        aksesorisDataList.add([
          '${i + 1}',
          timeStr,
          detailItemStr,
          '$totalQty',
          pm,
          currency.format(q.totalPayment),
          q.status,
          q.kasirName ?? '-',
        ]);
      }

      final checklistDataList = <List<String>>[];
      final checkUpdatedAt = checklistData['updatedAt'] as DateTime?;
      final checkDateStr = checkUpdatedAt != null ? dtFormat.format(checkUpdatedAt) : '-';
      for (var i = 0; i < checklistItems.length; i++) {
        final item = checklistItems[i];
        final masuk = ((item['masuk'] as bool?) ?? false) ? 'V' : 'X';
        final keluar = ((item['keluar'] as bool?) ?? false) ? 'V' : 'X';
        checklistDataList.add([
          '${i + 1}',
          checkDateStr,
          item['item_name'] ?? '-',
          '${item['qty'] ?? 0}',
          masuk,
          keluar,
          item['user_name'] ?? '-',
        ]);
      }

      // Generate PDF Document
      final pdf = pw.Document();

      // Page 1: Booth Section
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (context) => [
            pw.Text('LAPORAN EVENT', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFFAC282C))),
            pw.SizedBox(height: 12),
            pw.Row(children: [
              pw.Text('nama event : ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
              pw.Text(event.name, style: const pw.TextStyle(fontSize: 10)),
            ]),
            pw.Row(children: [
              pw.Text('pukul      : ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
              pw.Text(timeRange, style: const pw.TextStyle(fontSize: 10)),
            ]),
            pw.Row(children: [
              pw.Text('kasir      : ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
              pw.Text(cashiersString, style: const pw.TextStyle(fontSize: 10)),
            ]),
            pw.SizedBox(height: 20),
            pw.Text('BOOTH', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF1E293B))),
            pw.SizedBox(height: 8),
            if (boothDataList.isEmpty)
              pw.Text('Tidak ada transaksi booth', style: pw.TextStyle(color: PdfColors.grey600, fontSize: 10))
            else
              pw.TableHelper.fromTextArray(
                headers: const ['No', 'Tgl/Waktu', 'Pelanggan', 'Strip', 'Pembayaran', 'Total', 'Status', 'Kasir'],
                data: boothDataList,
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 8),
                headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFAC282C)),
                cellStyle: const pw.TextStyle(fontSize: 7),
                cellHeight: 20,
                cellAlignments: {
                  0: pw.Alignment.center,
                  1: pw.Alignment.center,
                  2: pw.Alignment.centerLeft,
                  3: pw.Alignment.center,
                  4: pw.Alignment.centerLeft,
                  5: pw.Alignment.centerRight,
                  6: pw.Alignment.center,
                  7: pw.Alignment.centerLeft,
                },
              ),
            pw.SizedBox(height: 12),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Container(
                width: 220,
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                ),
                child: pw.Column(
                  children: [
                    _buildPdfIndicatorRow('Sesi Booth Selesai', '$boothSelesai'),
                    pw.SizedBox(height: 4),
                    _buildPdfIndicatorRow('Sesi Booth Batal', '$boothBatal'),
                    pw.SizedBox(height: 4),
                    _buildPdfIndicatorRow('Cash Booth', currency.format(boothCash)),
                    pw.SizedBox(height: 4),
                    _buildPdfIndicatorRow('QRIS Booth', currency.format(boothQris)),
                    pw.SizedBox(height: 4),
                    _buildPdfIndicatorRow('Komisi Panitia', '-${currency.format(komisi)}', valueColor: PdfColors.red),
                    pw.Divider(color: PdfColors.grey300),
                    _buildPdfIndicatorRow('Total Cash Booth', currency.format(subTotalBooth), isBold: true),
                  ],
                ),
              ),
            ),
          ],
        ),
      );

      // Page 2: Aksesoris Section
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (context) => [
            pw.Text('AKSESORIS', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF1E293B))),
            pw.SizedBox(height: 8),
            if (aksesorisDataList.isEmpty)
              pw.Text('Tidak ada transaksi aksesoris', style: pw.TextStyle(color: PdfColors.grey600, fontSize: 10))
            else
              pw.TableHelper.fromTextArray(
                headers: const ['No', 'Tgl/Waktu', 'Detail Item', 'Jml', 'Pembayaran', 'Total', 'Status', 'Kasir'],
                data: aksesorisDataList,
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 8),
                headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFAC282C)),
                cellStyle: const pw.TextStyle(fontSize: 7),
                cellHeight: 20,
                cellAlignments: {
                  0: pw.Alignment.center,
                  1: pw.Alignment.center,
                  2: pw.Alignment.centerLeft,
                  3: pw.Alignment.center,
                  4: pw.Alignment.centerLeft,
                  5: pw.Alignment.centerRight,
                  6: pw.Alignment.center,
                  7: pw.Alignment.centerLeft,
                },
              ),
            pw.SizedBox(height: 12),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Container(
                width: 220,
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                ),
                child: pw.Column(
                  children: [
                    _buildPdfIndicatorRow('Item Terjual', '$aksesorisItemTerjual'),
                    pw.SizedBox(height: 4),
                    _buildPdfIndicatorRow('Item Dibatalkan', '$aksesorisItemBatal'),
                    pw.SizedBox(height: 4),
                    _buildPdfIndicatorRow('Cash Aksesoris', currency.format(aksesorisCash)),
                    pw.SizedBox(height: 4),
                    _buildPdfIndicatorRow('QRIS Aksesoris', currency.format(aksesorisQris)),
                  ],
                ),
              ),
            ),
          ],
        ),
      );

      // Page 3: Checklist Set Section
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (context) => [
            pw.Text('CHECKLIST SET', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF1E293B))),
            pw.SizedBox(height: 8),
            if (checklistDataList.isEmpty)
              pw.Text('Belum ada data checklist', style: pw.TextStyle(color: PdfColors.grey600, fontSize: 10))
            else
              pw.TableHelper.fromTextArray(
                headers: const ['No', 'Tgl/Waktu', 'Nama Barang', 'Jml', 'Masuk', 'Keluar', 'Kasir'],
                data: checklistDataList,
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 8),
                headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFAC282C)),
                cellStyle: const pw.TextStyle(fontSize: 7),
                cellHeight: 20,
                cellAlignments: {
                  0: pw.Alignment.center,
                  1: pw.Alignment.center,
                  2: pw.Alignment.centerLeft,
                  3: pw.Alignment.center,
                  4: pw.Alignment.center,
                  5: pw.Alignment.center,
                  6: pw.Alignment.centerLeft,
                },
              ),
          ],
        ),
      );

      final dateSlug = DateFormat('yyyyMMdd').format(event.date);
      final filename = 'Laporan_${event.name.replaceAll(' ', '_')}_$dateSlug.pdf';

      // Convert PDF to Uint8List and trigger download
      final pdfBytes = await pdf.save();
      downloadFile(filename, pdfBytes);
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Gagal mendownload laporan: $e')),
      );
    } finally {
      navigator.pop(); // Close loading indicator
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 16,
        title: Text(
          'Laporan',
          style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.bold, color: _textColor),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: const [
          NotificationBellWidget(),
          SizedBox(width: 16),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Riwayat Event',
              style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: _textColor),
            ),
            const SizedBox(height: 16),
            _buildPastEventsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildPastEventsList() {
    return StreamBuilder<List<EventModel>>(
      stream: _firebaseService.eventsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Terjadi kesalahan memuat riwayat event',
              style: GoogleFonts.poppins(color: Colors.redAccent),
            ),
          );
        }

        final dbEvents = snapshot.data ?? [];
        List<EventModel> pastEvents = [];

        final now = BusinessDayUtils.getBusinessDay();
        final today = DateTime(now.year, now.month, now.day);

        for (var event in dbEvents) {
          DateTime currentDate = DateTime(event.date.year, event.date.month, event.date.day);
          final endDate = DateTime(event.endDate.year, event.endDate.month, event.endDate.day);

          while (!currentDate.isAfter(endDate)) {
            if (currentDate.isBefore(today) || currentDate.isAtSameMomentAs(today)) {
              pastEvents.add(
                EventModel(
                  id: event.id,
                  name: event.name,
                  date: currentDate,
                  endDate: currentDate,
                  time: event.time,
                  sessionCount: event.sessionCount,
                ),
              );
            }
            currentDate = currentDate.add(const Duration(days: 1));
          }
        }

        if (pastEvents.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                'Tidak ada riwayat event.',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: _mutedText,
                ),
              ),
            ),
          );
        }

        // Sort descending by date
        pastEvents.sort((a, b) => b.date.compareTo(a.date));

        return LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 700;
            if (isDesktop) {
              return _buildEventHistoryTable(pastEvents);
            } else {
              return _buildEventHistoryCards(pastEvents);
            }
          },
        );
      },
    );
  }

  Widget _buildEventHistoryTable(List<EventModel> events) {
    const headers = ['No', 'Hari/Tanggal', 'Pukul', 'Event', 'Aksi'];
    const columnWidths = [
      FixedColumnWidth(40),
      FixedColumnWidth(110),
      FixedColumnWidth(80),
      FlexColumnWidth(2),
      FixedColumnWidth(180),
    ];

    final rows = events.asMap().entries.map((entry) {
      final i = entry.key;
      final ev = entry.value;
      final isEven = i % 2 == 0;

      final dayName = DateFormat('EEEE', 'id_ID').format(ev.date);
      final dateStr = DateFormat('dd MMM yyyy', 'id_ID').format(ev.date);

      final cellBg = isEven ? Colors.white : const Color(0xFFF8FAFC);

      return TableRow(
        decoration: BoxDecoration(color: cellBg),
        children: [
          GestureDetector(
            onTap: () => _navigateToDetail(ev),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
              child: Text('${i + 1}', style: _ts(), textAlign: TextAlign.center),
            ),
          ),
          GestureDetector(
            onTap: () => _navigateToDetail(ev),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
              child: Text('$dayName,\n$dateStr', style: _ts()),
            ),
          ),
          GestureDetector(
            onTap: () => _navigateToDetail(ev),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
              child: Text(ev.time, style: _ts()),
            ),
          ),
          GestureDetector(
            onTap: () => _navigateToDetail(ev),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
              child: Text(ev.name, style: _ts(11.0, FontWeight.w600)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 32,
                  child: ElevatedButton.icon(
                    onPressed: () => _navigateToDetail(ev),
                    icon: const Icon(LucideIcons.search, size: 12, color: Color(0xFF1E40AF)),
                    label: Text('Lihat', style: _ts(10.0, FontWeight.bold, const Color(0xFF1E40AF))),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFBFDBFE), // Pastel Blue
                      foregroundColor: const Color(0xFF1E40AF),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 32,
                  child: ElevatedButton.icon(
                    onPressed: () => _downloadReport(context, ev),
                    icon: const Icon(LucideIcons.download, size: 12, color: Color(0xFF92400E)),
                    label: Text('Download', style: _ts(10.0, FontWeight.bold, const Color(0xFF92400E))),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFDE68A), // Pastel Amber
                      foregroundColor: const Color(0xFF92400E),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }).toList();

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
                  minWidth: constraints.maxWidth > 650 ? constraints.maxWidth : 650,
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
                    TableRow(
                      decoration: const BoxDecoration(color: _headerBg),
                      children: headers.map((header) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
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

  // ── Mobile Card List ──────────────────────────────────────────
  Widget _buildEventHistoryCards(List<EventModel> events) {
    return Column(
      children: events.asMap().entries.map((entry) {
        final i = entry.key;
        final ev = entry.value;
        final dayName = DateFormat('EEEE', 'id_ID').format(ev.date);
        final dateStr = DateFormat('dd MMM yyyy', 'id_ID').format(ev.date);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: _borderColor),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: InkWell(
            onTap: () => _navigateToDetail(ev),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Number badge + Event name
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: _headerBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${i + 1}',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          ev.name,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Date & time row
                  Row(
                    children: [
                      const Icon(LucideIcons.calendarDays, size: 14, color: Color(0xFF64748B)),
                      const SizedBox(width: 6),
                      Text(
                        '$dayName, $dateStr',
                        style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF64748B)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(LucideIcons.clock, size: 14, color: Color(0xFF64748B)),
                      const SizedBox(width: 6),
                      Text(
                        ev.time,
                        style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF64748B)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _navigateToDetail(ev),
                          icon: const Icon(LucideIcons.search, size: 14, color: Color(0xFF1E40AF)),
                          label: Text('Lihat', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF1E40AF))),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFBFDBFE), // Pastel Blue
                            foregroundColor: const Color(0xFF1E40AF),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _downloadReport(context, ev),
                          icon: const Icon(LucideIcons.download, size: 14, color: Color(0xFF92400E)),
                          label: Text('Download', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF92400E))),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFDE68A), // Pastel Amber
                            foregroundColor: const Color(0xFF92400E),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  void _navigateToDetail(EventModel event) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminEventDetailScreen(event: event),
      ),
    );
  }

  TextStyle _ts([double size = 10.0, FontWeight weight = FontWeight.normal, Color color = const Color(0xFF1E293B)]) =>
      GoogleFonts.poppins(fontSize: size, fontWeight: weight, color: color);
}
