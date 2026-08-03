import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/event_model.dart';
import '../models/queue_model.dart';
import '../services/firebase_service.dart';
import '../screens/kasir_event_detail_screen.dart';
import '../utils/download_helper.dart';

// PDF imports
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class RekapDetailView extends StatefulWidget {
  final EventModel event;

  const RekapDetailView({
    super.key,
    required this.event,
  });

  @override
  State<RekapDetailView> createState() => _RekapDetailViewState();
}

class _RekapDetailViewState extends State<RekapDetailView> {
  final FirebaseService _firebaseService = FirebaseService();
  late Future<Map<String, dynamic>> _dataFuture;

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

  pw.Widget _buildPdfIndicatorRow(String label, String value,
      {PdfColor? valueColor, bool isBold = false}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label,
            style: pw.TextStyle(
                fontSize: 10,
                fontWeight:
                    isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        pw.Text(value,
            style: pw.TextStyle(
                fontSize: 10,
                fontWeight:
                    isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
                color: valueColor)),
      ],
    );
  }

  Future<void> _downloadReport(BuildContext context) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final event = widget.event;
      final data = await _firebaseService.getEventTransactions(
          event.id, event.date);
      final checklistData = await _firebaseService.getChecklistFull(
          eventId: event.id, date: event.date);

      final boothQueues = data['boothQueues'] as List<QueueModel>;
      final aksesorisQueues = data['aksesorisQueues'] as List<QueueModel>;
      final checklistItems = List<Map<String, dynamic>>.from(
          checklistData['items'] as List<dynamic>? ?? []);

      final timeRange = _getTimeRangeString(boothQueues, aksesorisQueues);

      // Cashier names
      final uniqueCashiers = <String>{};
      for (var q in boothQueues) {
        if (q.kasirName != null) uniqueCashiers.add(q.kasirName!);
      }
      for (var q in aksesorisQueues) {
        if (q.kasirName != null) uniqueCashiers.add(q.kasirName!);
      }
      final cashiersString =
          uniqueCashiers.isEmpty ? '-' : uniqueCashiers.join(', ');

      // Booth metrics
      int boothSelesai = data['boothSelesai'] as int? ?? 0;
      int boothBatal = data['boothBatal'] as int? ?? 0;
      int boothCash = data['boothCash'] as int? ?? 0;
      int boothQris = data['boothQris'] as int? ?? 0;
      int komisi = data['komisi'] as int? ?? 0;
      int subTotalBooth = data['subTotalBooth'] as int? ?? 0;

      // Aksesoris metrics
      int aksesorisItemTerjual = data['aksesorisItemTerjual'] as int? ?? 0;
      int aksesorisItemBatal = data['aksesorisItemBatal'] as int? ?? 0;
      int aksesorisCash = data['aksesorisCash'] as int? ?? 0;
      int aksesorisQris = data['aksesorisQris'] as int? ?? 0;

      final currency =
          NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
      final dtFormat = DateFormat('dd/MM/yy HH:mm');

      // Booth table data
      final boothDataList = <List<String>>[];
      for (var i = 0; i < boothQueues.length; i++) {
        final q = boothQueues[i];
        final timeStr =
            q.createdAt != null ? dtFormat.format(q.createdAt!) : '-';
        String pm = q.paymentMethod;
        if (q.paymentMethod == 'Split' && q.splitPayments != null) {
          pm =
              'Split\n(C:${currency.format(q.splitPayments!['Cash'] ?? 0)} / Q:${currency.format(q.splitPayments!['QRIS'] ?? 0)})';
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

      // Aksesoris table data
      final aksesorisDataList = <List<String>>[];
      for (var i = 0; i < aksesorisQueues.length; i++) {
        final q = aksesorisQueues[i];
        final timeStr =
            q.createdAt != null ? dtFormat.format(q.createdAt!) : '-';
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
          pm =
              'Split\n(C:${currency.format(q.splitPayments!['Cash'] ?? 0)} / Q:${currency.format(q.splitPayments!['QRIS'] ?? 0)})';
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

      // Checklist table data
      final checklistDataList = <List<String>>[];
      final checkUpdatedAt = checklistData['updatedAt'] as DateTime?;
      final checkDateStr =
          checkUpdatedAt != null ? dtFormat.format(checkUpdatedAt) : '-';
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

      // Build PDF
      final pdf = pw.Document();

      // Page 1: Booth
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (context) => [
            pw.Text('LAPORAN EVENT',
                style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: const PdfColor.fromInt(0xFFAC282C))),
            pw.SizedBox(height: 12),
            pw.Row(children: [
              pw.Text('nama event : ',
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 10)),
              pw.Text(event.name, style: const pw.TextStyle(fontSize: 10)),
            ]),
            pw.Row(children: [
              pw.Text('pukul      : ',
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 10)),
              pw.Text(timeRange, style: const pw.TextStyle(fontSize: 10)),
            ]),
            pw.Row(children: [
              pw.Text('kasir      : ',
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 10)),
              pw.Text(cashiersString,
                  style: const pw.TextStyle(fontSize: 10)),
            ]),
            pw.SizedBox(height: 20),
            pw.Text('BOOTH',
                style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: const PdfColor.fromInt(0xFF1E293B))),
            pw.SizedBox(height: 8),
            if (boothDataList.isEmpty)
              pw.Text('Tidak ada transaksi booth',
                  style:
                      pw.TextStyle(color: PdfColors.grey600, fontSize: 10))
            else
              pw.TableHelper.fromTextArray(
                headers: const [
                  'No','Tgl/Waktu','Pelanggan','Strip','Pembayaran','Total','Status','Kasir'
                ],
                data: boothDataList,
                headerStyle: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                    fontSize: 8),
                headerDecoration:
                    const pw.BoxDecoration(color: PdfColor.fromInt(0xFFAC282C)),
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
                  borderRadius:
                      const pw.BorderRadius.all(pw.Radius.circular(6)),
                ),
                child: pw.Column(children: [
                  _buildPdfIndicatorRow(
                      'Sesi Booth Selesai', '$boothSelesai'),
                  pw.SizedBox(height: 4),
                  _buildPdfIndicatorRow('Sesi Booth Batal', '$boothBatal'),
                  pw.SizedBox(height: 4),
                  _buildPdfIndicatorRow(
                      'Cash Booth', currency.format(boothCash)),
                  pw.SizedBox(height: 4),
                  _buildPdfIndicatorRow(
                      'QRIS Booth', currency.format(boothQris)),
                  pw.SizedBox(height: 4),
                  _buildPdfIndicatorRow(
                      'Komisi Panitia', '-${currency.format(komisi)}',
                      valueColor: PdfColors.red),
                  pw.Divider(color: PdfColors.grey300),
                  _buildPdfIndicatorRow(
                      'Total Cash Booth', currency.format(subTotalBooth),
                      isBold: true),
                ]),
              ),
            ),
          ],
        ),
      );

      // Page 2: Aksesoris
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (context) => [
            pw.Text('AKSESORIS',
                style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: const PdfColor.fromInt(0xFF1E293B))),
            pw.SizedBox(height: 8),
            if (aksesorisDataList.isEmpty)
              pw.Text('Tidak ada transaksi aksesoris',
                  style:
                      pw.TextStyle(color: PdfColors.grey600, fontSize: 10))
            else
              pw.TableHelper.fromTextArray(
                headers: const [
                  'No','Tgl/Waktu','Detail Item','Jml','Pembayaran','Total','Status','Kasir'
                ],
                data: aksesorisDataList,
                headerStyle: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                    fontSize: 8),
                headerDecoration:
                    const pw.BoxDecoration(color: PdfColor.fromInt(0xFFAC282C)),
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
                  borderRadius:
                      const pw.BorderRadius.all(pw.Radius.circular(6)),
                ),
                child: pw.Column(children: [
                  _buildPdfIndicatorRow(
                      'Item Terjual', '$aksesorisItemTerjual'),
                  pw.SizedBox(height: 4),
                  _buildPdfIndicatorRow(
                      'Item Dibatalkan', '$aksesorisItemBatal'),
                  pw.SizedBox(height: 4),
                  _buildPdfIndicatorRow(
                      'Cash Aksesoris', currency.format(aksesorisCash)),
                  pw.SizedBox(height: 4),
                  _buildPdfIndicatorRow(
                      'QRIS Aksesoris', currency.format(aksesorisQris)),
                ]),
              ),
            ),
          ],
        ),
      );

      // Page 3: Checklist
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (context) => [
            pw.Text('CHECKLIST SET',
                style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: const PdfColor.fromInt(0xFF1E293B))),
            pw.SizedBox(height: 8),
            if (checklistDataList.isEmpty)
              pw.Text('Belum ada data checklist',
                  style:
                      pw.TextStyle(color: PdfColors.grey600, fontSize: 10))
            else
              pw.TableHelper.fromTextArray(
                headers: const [
                  'No','Tgl/Waktu','Nama Barang','Jml','Masuk','Keluar','Kasir'
                ],
                data: checklistDataList,
                headerStyle: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                    fontSize: 8),
                headerDecoration:
                    const pw.BoxDecoration(color: PdfColor.fromInt(0xFFAC282C)),
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
      final filename =
          'Laporan_${event.name.replaceAll(' ', '_')}_$dateSlug.pdf';

      final pdfBytes = await pdf.save();
      downloadFile(filename, pdfBytes);
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Gagal mengunduh laporan: $e')),
      );
    } finally {
      navigator.pop(); // close loading dialog
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

    return FutureBuilder<Map<String, dynamic>>(
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

        return SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Event name
                Text(
                  widget.event.name,
                  style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A)),
                ),
                const SizedBox(height: 16),

                // Metrics grid
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
                        _buildMetricCard(
                            'Sesi Booth Selesai',
                            '${data['boothSelesai']}',
                            Icons.check_circle,
                            Colors.green),
                        _buildMetricCard(
                            'Sesi Booth Batal',
                            '${data['boothBatal']}',
                            Icons.cancel,
                            Colors.red),
                        _buildMetricCard(
                            'Cash Booth',
                            currency.format(data['boothCash']),
                            Icons.money,
                            Colors.purple),
                        _buildMetricCard(
                            'QRIS Booth',
                            currency.format(data['boothQris']),
                            Icons.qr_code,
                            Colors.purple),
                        _buildMetricCard(
                            'Komisi Panitia',
                            currency.format(data['komisi']),
                            Icons.money_off,
                            const Color(0xFF4B5320)),
                        _buildMetricCard(
                            'Total Cash Booth',
                            currency.format(data['subTotalBooth']),
                            Icons.account_balance_wallet,
                            Colors.blue),
                        _buildMetricCard(
                            'Item Terjual',
                            '${data['aksesorisItemTerjual'] ?? 0}',
                            Icons.check_circle,
                            Colors.green),
                        _buildMetricCard(
                            'Item Dibatalkan',
                            '${data['aksesorisItemBatal'] ?? 0}',
                            Icons.cancel,
                            Colors.red),
                        _buildMetricCard(
                            'Cash Aksesoris',
                            currency.format(data['aksesorisCash']),
                            Icons.money,
                            Colors.orange),
                        _buildMetricCard(
                            'QRIS Aksesoris',
                            currency.format(data['aksesorisQris']),
                            Icons.qr_code,
                            Colors.orange),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),

                // Action buttons row
                Row(
                  children: [
                    // Lihat Transaksi
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => KasirEventDetailScreen(
                                  event: widget.event),
                            ),
                          );
                        },
                        icon: const Icon(LucideIcons.arrowRight,
                            size: 18, color: Colors.white),
                        label: Text(
                          'Lihat Transaksi',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFAC282C),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Download
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _downloadReport(context),
                        icon: const Icon(LucideIcons.download,
                            size: 18, color: Colors.white),
                        label: Text(
                          'Download',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB), // Blue
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetricCard(
      String title, String value, IconData icon, Color color) {
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
                  style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: color,
                      fontWeight: FontWeight.w600),
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
              style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A)),
            ),
          ),
        ],
      ),
    );
  }
}
