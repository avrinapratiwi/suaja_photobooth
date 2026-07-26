import 'package:flutter/material.dart';
import '../widgets/shared_calendar_widget.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/firebase_service.dart';
import '../widgets/notification_bell.dart';
import '../widgets/delete_confirmation_dialog.dart';

import '../models/event_model.dart';
import '../models/aksesoris_item_model.dart';
import 'kasir_screen.dart';
import 'report_screen.dart';

class MasterEventScreen extends StatefulWidget {
  final String? role;

  const MasterEventScreen({super.key, this.role});

  @override
  State<MasterEventScreen> createState() => _MasterEventScreenState();
}

class _MasterEventScreenState extends State<MasterEventScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final TextEditingController _eventNameController = TextEditingController();
  final TextEditingController _searchLaporanController = TextEditingController();
  String _searchLaporanQuery = '';
  int? _selectedMonthFilter;
  bool _isFilterOpen = false;
  


  @override
  void dispose() {
    _eventNameController.dispose();
    _searchLaporanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Schedule Event',
          style: GoogleFonts.poppins(
            color: const Color(0xFF1E293B),
            fontWeight: FontWeight.bold,
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
        child: _buildCalendarCard(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddEventDialog,
        backgroundColor: const Color(0xFFAC282C),
        child: const Icon(LucideIcons.plus, color: Colors.white),
      ),
    );
  }

  Widget _buildCalendar() {
    return Container();
  }

  void _showAddEventDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return EventFormDialog(
          initialDate: DateTime.now(),
          dummyEvents: [],
          onSave: (newEvent, isEdit) async {
            await _firebaseService.addEvent(newEvent);
          },
        );
      },
    );
  }

  Widget _buildCalendarCard() {
    return StreamBuilder<List<EventModel>>(
      stream: _firebaseService.eventsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(
            padding: EdgeInsets.all(40),
            child: CircularProgressIndicator(),
          ));
        }

        final events = snapshot.data ?? [];

        // Extract events for marker mapping
        Map<DateTime, List<EventModel>> eventsMap = {};
        for (var event in events) {
          DateTime currentDate = DateTime(event.date.year, event.date.month, event.date.day);
          final endDate = DateTime(event.endDate.year, event.endDate.month, event.endDate.day);
          while (!currentDate.isAfter(endDate)) {
            if (eventsMap[currentDate] == null) eventsMap[currentDate] = [];
            eventsMap[currentDate]!.add(event);
            currentDate = currentDate.add(const Duration(days: 1));
          }
        }
        
        // Sort events by time
        eventsMap.forEach((date, evs) {
          evs.sort((a, b) => a.time.compareTo(b.time));
        });

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SharedCalendarWidget(
            eventsMap: eventsMap,
            onEventTap: _openEventDialog,
            isReadOnly: false,
            showHeaderLabel: false,
            useCard: false,
          ),
        );
      }
    );
  }

  void _openEventDialog(EventModel event) {
    showDialog(
      context: context,
      builder: (formContext) {
        return EventFormDialog(
          existingEvent: event,
          dummyEvents: [],
          onSave: (updatedEvent, isEdit) async {
            if (isEdit) {
              await _firebaseService.updateEvent(updatedEvent);
            } else {
              await _firebaseService.addEvent(updatedEvent);
            }
          },
          onDelete: (eventToDelete) async {
            await _firebaseService.deleteEvent(eventToDelete.id);
          },
        );
      }
    );
  }

}

class CustomTimePickerDialog extends StatefulWidget {
  final TimeOfDay initialTime;
  const CustomTimePickerDialog({Key? key, required this.initialTime}) : super(key: key);

  @override
  State<CustomTimePickerDialog> createState() => _CustomTimePickerDialogState();
}

class _CustomTimePickerDialogState extends State<CustomTimePickerDialog> {
  late TextEditingController _hourController;
  late TextEditingController _minuteController;
  bool _isAm = true;

  @override
  void initState() {
    super.initState();
    int h = widget.initialTime.hour;
    _isAm = h < 12;
    if (h == 0) h = 12;
    if (h > 12) h -= 12;
    
    _hourController = TextEditingController(text: h.toString());
    _minuteController = TextEditingController(text: widget.initialTime.minute.toString().padLeft(2, '0'));
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      title: Text(
        'Masukkan Waktu',
        style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      content: SingleChildScrollView(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Hour
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Center(
                child: TextField(
                  controller: _hourController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(fontSize: 32, color: const Color(0xFF0F172A)),
                  decoration: const InputDecoration(border: InputBorder.none),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Text(':', style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
            ),
            // Minute
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Center(
                child: TextField(
                  controller: _minuteController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(fontSize: 32, color: const Color(0xFF0F172A)),
                  decoration: const InputDecoration(border: InputBorder.none),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // AM/PM Toggle
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE2E8F0)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () => setState(() => _isAm = true),
                    child: Container(
                      width: 50,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _isAm ? const Color(0xFFE0E7FF) : Colors.white,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                      ),
                      child: Center(
                        child: Text(
                          'AM', 
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold, 
                            color: _isAm ? const Color(0xFF4F46E5) : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Container(height: 1, color: const Color(0xFFE2E8F0), width: 50),
                  InkWell(
                    onTap: () => setState(() => _isAm = false),
                    child: Container(
                      width: 50,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: !_isAm ? const Color(0xFFE0E7FF) : Colors.white,
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
                      ),
                      child: Center(
                        child: Text(
                          'PM', 
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold, 
                            color: !_isAm ? const Color(0xFF4F46E5) : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context), 
          child: Text('Batal', style: GoogleFonts.poppins(color: const Color(0xFF64748B))),
        ),
        TextButton(
          onPressed: () {
            int h = int.tryParse(_hourController.text) ?? 0;
            int m = int.tryParse(_minuteController.text) ?? 0;
            if (h > 12) h = 12;
            if (m > 59) m = 59;
            
            if (h == 12 && _isAm) h = 0;
            if (h < 12 && !_isAm) h += 12;
            Navigator.pop(context, TimeOfDay(hour: h, minute: m));
          },
          child: Text('OK', style: GoogleFonts.poppins(color: const Color(0xFFAC282C), fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}

class EventFormDialog extends StatefulWidget {
  final EventModel? existingEvent;
  final DateTime? initialDate;
  final Function(EventModel, bool) onSave;
  final Function(EventModel)? onDelete;
  final List<EventModel> dummyEvents;
  final bool readOnly;

  const EventFormDialog({
    Key? key,
    this.existingEvent,
    this.initialDate,
    required this.onSave,
    this.onDelete,
    required this.dummyEvents,
    this.readOnly = false,
  }) : super(key: key);

  @override
  State<EventFormDialog> createState() => _EventFormDialogState();
}

class _EventFormDialogState extends State<EventFormDialog> {
  late TextEditingController _eventNameController;
  DateTime? _selectedDate;
  DateTime? _selectedEndDate;
  TimeOfDay? _selectedTime;
  bool _isEdited = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingEvent != null) {
      _eventNameController = TextEditingController(text: widget.existingEvent!.name);
      _selectedDate = widget.existingEvent!.date;
      _selectedEndDate = widget.existingEvent!.endDate;
      
      final timeParts = widget.existingEvent!.time.split('-')[0].trim().split(':');
      if (timeParts.length == 2) {
        _selectedTime = TimeOfDay(hour: int.parse(timeParts[0]), minute: int.parse(timeParts[1]));
      }
    } else {
      _eventNameController = TextEditingController();
      _selectedDate = widget.initialDate ?? DateTime.now();
      _selectedEndDate = widget.initialDate ?? DateTime.now();
      _selectedTime = TimeOfDay.now();
    }
  }

  @override
  void dispose() {
    _eventNameController.dispose();
    super.dispose();
  }

  void _markEdited() {
    if (!_isEdited) setState(() => _isEdited = true);
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.existingEvent != null;
    final showDeleteBtn = isEditMode && !_isEdited;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      backgroundColor: Colors.white,
      child: SizedBox(
        width: MediaQuery.of(context).size.width > 500 ? 400 : MediaQuery.of(context).size.width * 0.9,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9), // Grey background for header
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditMode ? 'Detail Event' : 'Tambah Event',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFAC282C),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.x, color: Color(0xFF64748B)),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nama Event',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _eventNameController,
                    readOnly: widget.readOnly,
                    onChanged: widget.readOnly ? null : (val) => _markEdited(),
                    decoration: InputDecoration(
                      hintText: 'Masukkan nama event...',
                      hintStyle: GoogleFonts.poppins(color: const Color(0xFF94A3B8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      filled: widget.readOnly,
                      fillColor: widget.readOnly ? const Color(0xFFF1F5F9) : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tanggal Mulai',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: widget.readOnly ? null : () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: _selectedDate ?? DateTime.now(),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2030),
                                );
                                if (date != null) {
                                  setState(() {
                                    _selectedDate = date;
                                    if (_selectedEndDate == null || _selectedEndDate!.isBefore(_selectedDate!)) {
                                      _selectedEndDate = date;
                                    }
                                    _markEdited();
                                  });
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: widget.readOnly ? const Color(0xFFF1F5F9) : null,
                                  border: Border.all(color: const Color(0xFFCBD5E1)),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _selectedDate != null
                                          ? DateFormat('dd/MM/yyyy').format(_selectedDate!)
                                          : 'Pilih Tanggal',
                                      style: GoogleFonts.poppins(
                                        color: _selectedDate != null ? Colors.black : const Color(0xFF94A3B8),
                                      ),
                                    ),
                                    if (!widget.readOnly) const Icon(LucideIcons.calendar, size: 16, color: Color(0xFF64748B)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tanggal Selesai',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: widget.readOnly ? null : () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: _selectedEndDate ?? _selectedDate ?? DateTime.now(),
                                  firstDate: _selectedDate ?? DateTime(2020),
                                  lastDate: DateTime(2030),
                                );
                                if (date != null) {
                                  setState(() {
                                    _selectedEndDate = date;
                                    _markEdited();
                                  });
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: widget.readOnly ? const Color(0xFFF1F5F9) : null,
                                  border: Border.all(color: const Color(0xFFCBD5E1)),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _selectedEndDate != null
                                          ? DateFormat('dd/MM/yyyy').format(_selectedEndDate!)
                                          : 'Pilih Tanggal',
                                      style: GoogleFonts.poppins(
                                        color: _selectedEndDate != null ? Colors.black : const Color(0xFF94A3B8),
                                      ),
                                    ),
                                    if (!widget.readOnly) const Icon(LucideIcons.calendar, size: 16, color: Color(0xFF64748B)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Jam Mulai',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: widget.readOnly ? null : () async {
                          final time = await showDialog<TimeOfDay>(
                            context: context,
                            builder: (context) => CustomTimePickerDialog(
                              initialTime: _selectedTime ?? TimeOfDay.now(),
                            ),
                          );
                          if (time != null) {
                            setState(() {
                              _selectedTime = time;
                              _markEdited();
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: widget.readOnly ? const Color(0xFFF1F5F9) : null,
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _selectedTime != null
                                    ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
                                    : 'Pilih Jam',
                                style: GoogleFonts.poppins(
                                  color: _selectedTime != null ? Colors.black : const Color(0xFF94A3B8),
                                ),
                              ),
                              if (!widget.readOnly) const Icon(LucideIcons.clock, size: 16, color: Color(0xFF64748B)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (!widget.readOnly) ...[  
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (showDeleteBtn) {
                            if (widget.onDelete != null && widget.existingEvent != null) {
                              final bool? confirm = await showDeleteConfirmationDialog(
                                context: context,
                                title: 'Hapus Event',
                                content: 'Anda yakin ingin menghapus event "${widget.existingEvent!.name}" secara permanen?',
                              );
                              if (confirm == true) {
                                widget.onDelete!(widget.existingEvent!);
                                if (context.mounted) Navigator.pop(context);
                              }
                            }
                            return;
                          }

                          final name = _eventNameController.text.trim();
                          if (name.isNotEmpty && _selectedDate != null && _selectedEndDate != null && _selectedTime != null) {
                            final newTime = '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}';
                            
                            // Check for duplicates
                            final isDuplicate = widget.dummyEvents.any((event) => 
                              event.id != widget.existingEvent?.id &&
                              event.name.toLowerCase() == name.toLowerCase() &&
                              event.date.year == _selectedDate!.year &&
                              event.date.month == _selectedDate!.month &&
                              event.date.day == _selectedDate!.day &&
                              event.time.split('-')[0].trim() == newTime
                            );

                            if (isDuplicate) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Gagal menyimpan! Event "$name" sudah ada pada tanggal dan jam tersebut.'),
                                  backgroundColor: const Color(0xFFAC282C),
                                ),
                              );
                              return;
                            }

                            final updatedEvent = EventModel(
                              id: widget.existingEvent?.id ?? 'e${widget.dummyEvents.length + 1}',
                              name: name,
                              date: _selectedDate!,
                              endDate: _selectedEndDate!,
                              time: newTime,
                              sessionCount: widget.existingEvent?.sessionCount ?? 0,
                            );
                            
                            widget.onSave(updatedEvent, isEditMode);
                            Navigator.pop(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: showDeleteBtn ? Colors.red : const Color(0xFFAC282C),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          showDeleteBtn ? 'Hapus Event' : 'Simpan',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            ),
            ),
          ],
        ),
      ),
    );
  }
}
