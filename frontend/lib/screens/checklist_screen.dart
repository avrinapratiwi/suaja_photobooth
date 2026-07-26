import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/event_model.dart';
import '../models/set_photobooth_model.dart';
import '../services/firebase_service.dart';
import '../widgets/notification_bell.dart';
import '../screens/main_screen.dart';

class ChecklistScreen extends StatefulWidget {
  final EventModel event;

  const ChecklistScreen({super.key, required this.event});

  @override
  State<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends State<ChecklistScreen> {
  // key: itemId, value: {masuk: bool, keluar: bool}
  final Map<String, Map<String, bool>> _checkState = {};
  final FirebaseService _firebaseService = FirebaseService();
  bool _isLoading = true;
  bool _isSaving = false;
  List<SetPhotoboothModel> _items = [];

  @override
  void initState() {
    super.initState();
    _loadExistingChecklist();
  }

  Future<void> _loadExistingChecklist() async {
    final saved = await _firebaseService.getChecklist(
      eventId: widget.event.id,
      date: widget.event.date,
    );
    if (mounted) {
      setState(() {
        for (var entry in saved.entries) {
          _checkState[entry.key] = Map<String, bool>.from(entry.value);
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _saveChecklist() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    String currentUserName = mainScreenKey.currentState?.widget.user.name ?? 'Kasir';

    final itemsData = _items.map((item) => {
      'item_id': item.id,
      'item_name': item.name,
      'qty': item.qty,
      'masuk': _checkState[item.id]?['masuk'] ?? false,
      'keluar': _checkState[item.id]?['keluar'] ?? false,
      'user_name': currentUserName,
    }).toList();

    await _firebaseService.saveChecklist(
      eventId: widget.event.id,
      date: widget.event.date,
      items: itemsData,
    );


    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Checklist berhasil disimpan',
            style: GoogleFonts.poppins(fontSize: 13),
          ),
          backgroundColor: const Color(0xFF059669),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Checklist Set',
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
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
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : StreamBuilder<List<SetPhotoboothModel>>(
                stream: _firebaseService.setPhotoboothStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting && _isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  _items = snapshot.data ?? [];

                  // Init state for new items only
                  for (var item in _items) {
                    _checkState.putIfAbsent(item.id, () => {'masuk': false, 'keluar': false});
                  }

                  final masukAll = _items.isNotEmpty && _items.every((i) => _checkState[i.id]?['masuk'] == true);
                  final keluarAll = _items.isNotEmpty && _items.every((i) => _checkState[i.id]?['keluar'] == true);

                  if (_items.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.packageOpen, size: 48, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          Text(
                            'Belum ada barang set photobooth',
                            style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF94A3B8)),
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    children: [
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            // Event name above status badge
                            Text(
                              widget.event.name,
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Status badge card
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  _statusBadge('Masuk', masukAll),
                                  const SizedBox(width: 12),
                                  _statusBadge('Keluar', keluarAll),
                                  const Spacer(),
                                  Text(
                                    '${_items.length} Barang',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Table card
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Table(
                                  columnWidths: const {
                                    0: FlexColumnWidth(3),
                                    1: FlexColumnWidth(1.2),
                                    2: FlexColumnWidth(1.3),
                                    3: FlexColumnWidth(1.3),
                                  },
                                  border: TableBorder(
                                    horizontalInside: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
                                  ),
                                  children: [
                                    // Header row
                                    TableRow(
                                      decoration: const BoxDecoration(color: Color(0xFFF8FAFC)),
                                      children: [
                                        _headerCell('Nama Barang'),
                                        _headerCell('Jml', center: true),
                                        _headerCell('Masuk', center: true),
                                        _headerCell('Keluar', center: true),
                                      ],
                                    ),
                                    // Data rows
                                    ..._items.asMap().entries.map((entry) {
                                      final i = entry.key;
                                      final item = entry.value;
                                      final masuk = _checkState[item.id]?['masuk'] ?? false;
                                      final keluar = _checkState[item.id]?['keluar'] ?? false;

                                      return TableRow(
                                        decoration: BoxDecoration(
                                          color: i.isEven ? Colors.white : const Color(0xFFFAFAFA),
                                        ),
                                        children: [
                                          _nameCell(item.name),
                                          _qtyCell(item.qty.toString()),
                                          _checkboxCell(
                                            value: masuk,
                                            onChanged: (v) => setState(() => _checkState[item.id]!['masuk'] = v ?? false),
                                          ),
                                          _checkboxCell(
                                            value: keluar,
                                            onChanged: (v) => setState(() => _checkState[item.id]!['keluar'] = v ?? false),
                                          ),
                                        ],
                                      );
                                    }),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Save button
                      Container(
                        color: Colors.white,
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _saveChecklist,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFAC282C),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            child: _isSaving
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : Text(
                                    'Simpan Checklist',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }

  Widget _statusBadge(String label, bool allChecked) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: allChecked
            ? const Color(0xFF059669).withValues(alpha: 0.1)
            : const Color(0xFFF59E0B).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: allChecked ? const Color(0xFF059669) : const Color(0xFFF59E0B),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            allChecked ? Icons.check_circle_outline_rounded : Icons.radio_button_unchecked_rounded,
            size: 13,
            color: allChecked ? const Color(0xFF059669) : const Color(0xFFF59E0B),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: allChecked ? const Color(0xFF059669) : const Color(0xFFF59E0B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerCell(String text, {bool center = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Text(
        text,
        textAlign: center ? TextAlign.center : TextAlign.left,
        style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF475569)),
      ),
    );
  }

  Widget _nameCell(String name) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Text(name, style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF0F172A))),
    );
  }

  Widget _qtyCell(String qty) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Text(
        qty,
        textAlign: TextAlign.center,
        style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF334155)),
      ),
    );
  }

  Widget _checkboxCell({required bool value, required Function(bool?) onChanged}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Checkbox(
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFFAC282C),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
        ),
      ),
    );
  }
}
