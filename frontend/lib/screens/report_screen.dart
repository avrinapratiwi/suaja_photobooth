import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/firebase_service.dart';
import 'package:intl/intl.dart';
import '../widgets/notification_bell.dart';
import '../models/event_model.dart';
import '../widgets/past_event_card.dart';
import 'admin_event_detail_screen.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final Color _textColor = const Color(0xFF1E293B);
  final Color _mutedText = const Color(0xFF64748B);

  late final Stream<int> _revenueStream;
  late final Stream<int> _boothCountStream;

  @override
  void initState() {
    super.initState();
    _revenueStream = _firebaseService.allTimeRevenueStream;
    _boothCountStream = _firebaseService.allTimeBoothSelesaiCountStream;
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
        actions: [
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
            _buildKpiCards(),
            const SizedBox(height: 32),
            Text(
              'Riwayat Event',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _textColor),
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
              style: TextStyle(color: Colors.redAccent),
            ),
          );
        }

        final dbEvents = snapshot.data ?? [];
        List<EventModel> pastEvents = [];
        
        final now = DateTime.now();
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
                style: TextStyle(
                  fontSize: 16,
                  color: _mutedText,
                ),
              ),
            ),
          );
        }
        
        // Sort descending by date
        pastEvents.sort((a, b) => b.date.compareTo(a.date));

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: pastEvents.length,
          itemBuilder: (context, index) {
            final ev = pastEvents[index];
            return PastEventCard(
              event: ev,
              index: index,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AdminEventDetailScreen(event: ev),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildKpiCards() {
    final NumberFormat currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

    return Row(
      children: [
        Expanded(
          child: StreamBuilder<int>(
            stream: _revenueStream,
            builder: (context, snapshot) {
              final amount = snapshot.data ?? 0;
              return _buildModernKpiCard(
                title: 'Total Pendapatan',
                value: currencyFormatter.format(amount),
                icon: Icons.account_balance_wallet_rounded,
                color: const Color(0xFF10B981),
                isLoading: snapshot.connectionState == ConnectionState.waiting,
              );
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: StreamBuilder<int>(
            stream: _boothCountStream,
            builder: (context, snapshot) {
              final count = snapshot.data ?? 0;
              return _buildModernKpiCard(
                title: 'Total Sesi Booth',
                value: count.toString(),
                icon: Icons.camera_alt_rounded,
                color: const Color(0xFF3B82F6),
                isLoading: snapshot.connectionState == ConnectionState.waiting,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildModernKpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    bool isLoading = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: isLoading
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: color),
                      )
                    : FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          value,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
