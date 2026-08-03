import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/notification_bell.dart';
import '../services/firebase_service.dart';
import '../models/event_model.dart';
import '../widgets/past_event_card.dart';
import '../widgets/rekap_detail_view.dart';
import '../utils/business_day_utils.dart';

class RekapScreen extends StatefulWidget {
  const RekapScreen({super.key});

  @override
  State<RekapScreen> createState() => _RekapScreenState();
}

class _RekapScreenState extends State<RekapScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  EventModel? _selectedEvent;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: _selectedEvent != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () {
                  setState(() {
                    _selectedEvent = null;
                  });
                },
              )
            : null,
        title: Text(
          _selectedEvent != null ? 'Rekap Hari Ini' : 'Rekap Laporan',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
        ),
        actions: const [
          NotificationBellWidget(),
          SizedBox(width: 8),
        ],
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1),
        ),
      ),
      body: _selectedEvent != null
          ? RekapDetailView(event: _selectedEvent!)
          : _buildEventList(),
    );
  }

  Widget _buildEventList() {
    return StreamBuilder<List<EventModel>>(
      stream: _firebaseService.eventsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Terjadi kesalahan memuat data',
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
            child: Text(
              'Tidak ada event.',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: const Color(0xFF64748B),
              ),
            ),
          );
        }
        
        // Sort descending by date
        pastEvents.sort((a, b) => b.date.compareTo(a.date));

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: pastEvents.length,
            itemBuilder: (context, index) {
              final ev = pastEvents[index];
              return PastEventCard(
                event: ev,
                index: index,
                onTap: () {
                  setState(() {
                    _selectedEvent = ev;
                  });
                },
              );
            },
          ),
        );
      },
    );
  }
}
