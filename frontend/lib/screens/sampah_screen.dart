import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../models/queue_model.dart';
import '../services/firebase_service.dart';
import '../widgets/delete_confirmation_dialog.dart';

class SampahScreen extends StatefulWidget {
  const SampahScreen({super.key});

  @override
  State<SampahScreen> createState() => _SampahScreenState();
}

class _SampahScreenState extends State<SampahScreen> {
  final FirebaseService _firebaseService = FirebaseService();

  // Custom Colors
  final Color _bgColor = const Color(0xFFF8FAFC);
  final Color _cardColor = Colors.white;
  final Color _primaryColor = const Color(0xFFAC282C);
  final Color _textColor = const Color(0xFF1E293B);
  final Color _grayText = const Color(0xFF64748B);

  Future<void> _handleRestore(QueueModel queue) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore Antrian'),
        content: Text('Apakah Anda yakin ingin mengembalikan antrian ${queue.name} ke status MENUNGGU?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: _primaryColor, foregroundColor: Colors.white),
            child: const Text('Restore'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _firebaseService.updateStatus(queue.id, 'MENUNGGU');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${queue.name} berhasil direstore')),
        );
      }
    }
  }

  Future<void> _handleHardDelete(QueueModel queue) async {
    final bool? confirm = await showDeleteConfirmationDialog(
      context: context,
      title: 'Hapus Permanen',
      content: 'Tindakan ini akan menghapus antrian ${queue.name} secara permanen dari database. Lanjutkan?',
    );

    if (confirm == true) {
      await _firebaseService.deleteQueue(queue.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${queue.name} dihapus permanen')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Riwayat Batal (Sampah)',
          style: GoogleFonts.poppins(
            color: _textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1),
        ),
      ),
      body: StreamBuilder<List<QueueModel>>(
        stream: _firebaseService.activeQueuesStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final queues = snapshot.data!;
          final cancelledQueues = queues.where((q) => q.status == 'BATAL').toList();
          cancelledQueues.sort((a, b) => (b.updatedAt ?? b.createdAt ?? DateTime.now()).compareTo(a.updatedAt ?? a.createdAt ?? DateTime.now()));

          if (cancelledQueues.isEmpty) {
            return const Center(
              child: Text(
                'Tidak ada data sampah.',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: cancelledQueues.length,
            itemBuilder: (context, index) {
              final q = cancelledQueues[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _cardColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0A000000),
                      blurRadius: 10,
                      offset: Offset(0, 4),
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
                          q.name,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _textColor,
                          ),
                        ),
                        Text(
                          DateFormat('HH:mm').format(q.updatedAt ?? q.createdAt ?? DateTime.now()),
                          style: TextStyle(color: _grayText, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Total: Rp ${NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0).format(q.totalPayment)}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _handleRestore(q),
                          icon: const Icon(LucideIcons.rotateCcw, size: 16),
                          label: const Text('Restore'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _primaryColor,
                            side: BorderSide(color: _primaryColor),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () => _handleHardDelete(q),
                          icon: const Icon(LucideIcons.trash2, size: 16),
                          label: const Text('Hapus'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
