import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/event_model.dart';
import '../services/firebase_service.dart';
import '../widgets/past_event_card.dart';
import 'admin_event_detail_screen.dart';

class DatabaseStorageScreen extends StatefulWidget {
  const DatabaseStorageScreen({super.key});

  @override
  State<DatabaseStorageScreen> createState() => _DatabaseStorageScreenState();
}

class _DatabaseStorageScreenState extends State<DatabaseStorageScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  
  bool _isSelectionMode = false;
  final Set<String> _selectedEventIds = {};

  void _toggleSelection(String eventId) {
    setState(() {
      if (_selectedEventIds.contains(eventId)) {
        _selectedEventIds.remove(eventId);
        if (_selectedEventIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedEventIds.add(eventId);
      }
    });
  }

  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Hapus Permanen',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
          ),
          content: Text(
            'Anda yakin ingin menghapus ${_selectedEventIds.length} event terpilih?\n\n'
            'Tindakan ini akan menghapus event beserta seluruh antrean (queues) dan checklist '
            'yang terhubung dengan event tersebut secara permanen dari database.',
            style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF64748B)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Batal',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: const Color(0xFF64748B)),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _performDeletion();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFAC282C),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                'Hapus',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performDeletion() async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: Color(0xFFAC282C))),
    );

    try {
      for (final eventId in _selectedEventIds) {
        await _firebaseService.deleteEventWithRelatedData(eventId);
      }
      
      if (!mounted) return;
      Navigator.pop(context); // hide loading
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Berhasil menghapus data permanen.', style: GoogleFonts.poppins()),
          backgroundColor: Colors.green,
        ),
      );

      setState(() {
        _selectedEventIds.clear();
        _isSelectionMode = false;
      });
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // hide loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menghapus data: $e', style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _isSelectionMode ? _buildSelectionAppBar() : _buildNormalAppBar(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildStorageSection(),
            _buildEventListSection(),
          ],
        ),
      ),
    );
  }

  AppBar _buildNormalAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(LucideIcons.arrowLeft, size: 20, color: Color(0xFF1E293B)),
        onPressed: () => Navigator.pop(context),
      ),
      titleSpacing: 0,
      title: Text(
        'Penyimpanan Database',
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF1E293B),
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: const Color(0xFFE2E8F0), height: 1),
      ),
    );
  }

  AppBar _buildSelectionAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFFAC282C),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(LucideIcons.x, size: 20, color: Colors.white),
        onPressed: () {
          setState(() {
            _isSelectionMode = false;
            _selectedEventIds.clear();
          });
        },
      ),
      titleSpacing: 0,
      title: Text(
        '${_selectedEventIds.length} terpilih',
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(LucideIcons.trash2, color: Colors.white),
          onPressed: _showDeleteConfirmationDialog,
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildStorageSection() {
    return FutureBuilder<int>(
      future: _firebaseService.getTotalDatabaseDocumentsCount(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(24.0),
            child: Center(child: CircularProgressIndicator(color: Color(0xFFAC282C))),
          );
        }

        final docCount = snapshot.data ?? 0;
        // Estimate: 1 doc = 1 KB. Free tier = 1 GB = 1,000,000 KB.
        final usedKb = docCount.toDouble();
        final maxKb = 1000000.0;
        final percentage = (usedKb / maxKb).clamp(0.0, 1.0);
        
        // Buat percentage lebih realistis terlihat di UI jika docCount kecil
        // agar bar tidak terlalu kosong jika data masih puluhan.
        // Kita hanya tambahkan min percentage sedikit (misal 1-5%) sebagai UI "minimum visible bar"
        final displayPercentage = (percentage < 0.01 && usedKb > 0) ? 0.01 : percentage;

        String usedDisplay;
        if (usedKb < 1000) {
          usedDisplay = '${usedKb.toStringAsFixed(1)} KB';
        } else {
          usedDisplay = '${(usedKb / 1000).toStringAsFixed(2)} MB';
        }

        return Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1E293B).withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Kapasitas Terpakai',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  Text(
                    '${(displayPercentage * 100).toStringAsFixed(1)}%',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFAC282C),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: displayPercentage,
                  minHeight: 10,
                  backgroundColor: const Color(0xFFF1F5F9),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFAC282C)),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    usedDisplay,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  Text(
                    '1 GB',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.info, size: 16, color: Color(0xFF3B82F6)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Estimasi penggunaan berdasarkan jumlah dokumen transaksi dan data event.',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFF1D4ED8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEventListSection() {
    return StreamBuilder<List<EventModel>>(
      stream: _firebaseService.eventsStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFAC282C)));
        }

        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        
        final pastEvents = snapshot.data!.where((e) => e.date.isBefore(today)).toList();
        
        if (pastEvents.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              'Belum ada riwayat event yang tersimpan.',
              style: GoogleFonts.poppins(color: const Color(0xFF64748B)),
            ),
          );
        }

        // Sort desc
        pastEvents.sort((a, b) => b.date.compareTo(a.date));

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Kelola Riwayat Event',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 16),
              ...pastEvents.asMap().entries.map((entry) {
                final index = entry.key;
                final event = entry.value;
                final isSelected = _selectedEventIds.contains(event.id);

                return PastEventCard(
                  event: event,
                  index: index,
                  isSelected: isSelected,
                  onLongPress: () {
                    setState(() {
                      _isSelectionMode = true;
                      _toggleSelection(event.id);
                    });
                  },
                  onTap: () {
                    if (_isSelectionMode) {
                      _toggleSelection(event.id);
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AdminEventDetailScreen(event: event),
                        ),
                      );
                    }
                  },
                );
              }),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }
}
