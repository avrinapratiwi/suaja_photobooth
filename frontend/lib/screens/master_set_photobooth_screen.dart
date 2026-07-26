import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/firebase_service.dart';
import '../widgets/notification_bell.dart';
import '../widgets/delete_confirmation_dialog.dart';

import '../models/event_model.dart';
import '../models/set_photobooth_model.dart';
import 'kasir_screen.dart';
import 'report_screen.dart';

class MasterSetPhotoboothScreen extends StatefulWidget {
  final String? role;
  const MasterSetPhotoboothScreen({super.key, this.role});

  @override
  State<MasterSetPhotoboothScreen> createState() => _MasterSetPhotoboothScreenState();
}

class _MasterSetPhotoboothScreenState extends State<MasterSetPhotoboothScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  int _selectedIndex = 1; // Keeping this just in case other things break, wait, I will remove it.

  final TextEditingController _eventNameController = TextEditingController();
  final TextEditingController _searchLaporanController = TextEditingController();
  String _searchLaporanQuery = '';
  int? _selectedMonthFilter;
  bool _isFilterOpen = false;
  
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay = DateTime.now();

  final TextEditingController _setPhotoboothNameController = TextEditingController();
    final TextEditingController _setPhotoboothStockController = TextEditingController();
  final PageController _pageController = PageController();
  int _currentCatalogPage = 0;
  String _calendarViewMode = 'Bulan';

  @override
  void dispose() {
    _eventNameController.dispose();
    _searchLaporanController.dispose();
    _setPhotoboothNameController.dispose();
        _setPhotoboothStockController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
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
            'Set Photobooth',
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
        floatingActionButton: FloatingActionButton(
          onPressed: _showAddSetPhotoboothDialog,
          backgroundColor: const Color(0xFFAC282C),
          foregroundColor: Colors.white,
          child: const Icon(LucideIcons.plus),
        ),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
                child: TextField(
                  controller: _searchLaporanController,
                  onChanged: (value) {
                    setState(() {
                      _searchLaporanQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'carii...',
                    hintStyle: GoogleFonts.poppins(color: const Color(0xFF94A3B8)),
                    prefixIcon: const Icon(LucideIcons.search, color: Color(0xFF94A3B8)),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFAC282C), width: 1.5),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: StreamBuilder<List<SetPhotoboothModel>>(
                  stream: _firebaseService.setPhotoboothStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }
                    
                    final allItems = snapshot.data ?? [];
                    final filteredItems = allItems.where((item) {
                      return item.name.toLowerCase().contains(_searchLaporanQuery.toLowerCase());
                    }).toList();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 4),
                          child: Text(
                            '${filteredItems.length} Barang',
                            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFFAC282C)),
                          ),
                        ),
                        Expanded(
                          child: _buildAksesorisCatalogList(filteredItems),
                        ),
                      ],
                    );
                  }
                ),
              ),
            ],
          ),
        ),
      );
    });
  }


  Widget _buildAksesorisCatalogList(List<SetPhotoboothModel> filteredItems) {

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filteredItems.length,
      itemBuilder: (context, index) {
        final item = filteredItems[index];
        return _buildSetPhotoboothItemCard(item);
      },
    );
  }

  Widget _buildSetPhotoboothItemCard(SetPhotoboothModel item) {
    return InkWell(
      onTap: () => _showAddSetPhotoboothDialog(existingItem: item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                if (item.updatedAt != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _formatIndonesianDate(item.updatedAt!),
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: item.qty > 0 ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: item.qty > 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
              ),
              child: Text(
                'Jumlah: ${item.qty}',
                style: TextStyle(
                  color: item.qty > 0 ? const Color(0xFF059669) : const Color(0xFFDC2626),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  double _timeToDouble(String time) {
    try {
      final parts = time.split(':');
      if (parts.length >= 2) {
        final hours = double.parse(parts[0]);
        final minutes = double.parse(parts[1]);
        return hours + (minutes / 60.0);
      }
    } catch (e) {}
    return 0.0;
  }

  List<double> _parseTimeRange(String timeStr) {
    try {
      final parts = timeStr.split('-');
      final start = _timeToDouble(parts[0].trim());
      double end = start + 1.0;
      if (parts.length > 1) {
        end = _timeToDouble(parts[1].trim());
        if (end <= start) end = start + 1.0;
      }
      return [start, end];
    } catch (e) {
      return [0.0, 1.0];
    }
  }

  Color _getEventColor(String id) {
    final colors = [
      const Color(0xFF1A73E8), // Blue
      const Color(0xFFD93025), // Red
      const Color(0xFF188038), // Green
      const Color(0xFFF29900), // Yellow
      const Color(0xFF8E24AA), // Purple
      const Color(0xFFE67C73), // Light Red
    ];
    return colors[id.hashCode.abs() % colors.length];
  }

  Widget _buildCalendarContent(Map<DateTime, List<EventModel>> eventsMap) {
    if (_calendarViewMode == 'Event') {
      return _buildAgendaView(eventsMap);
    } else if (_calendarViewMode == 'Tahun') {
      return _buildYearView(eventsMap);
    } else if (_calendarViewMode == 'Hari') {
      return _buildDayView(eventsMap);
    } else if (_calendarViewMode == 'Minggu') {
      return _buildWeekView(eventsMap);
    }

    return Expanded(
      child: SingleChildScrollView(
        child: TableCalendar<EventModel>(
          firstDay: DateTime.utc(2020, 10, 16),
          lastDay: DateTime.utc(2030, 3, 14),
          focusedDay: _focusedDay,
          rowHeight: 90, 
          availableGestures: AvailableGestures.none,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          onPageChanged: (focusedDay) {
            setState(() {
              _focusedDay = focusedDay;
            });
          },
          headerStyle: HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            titleTextStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          calendarBuilders: CalendarBuilders(
            defaultBuilder: (context, day, focusedDay) => _buildMonthCell(day, eventsMap[DateTime(day.year, day.month, day.day)] ?? []),
            todayBuilder: (context, day, focusedDay) => _buildMonthCell(day, eventsMap[DateTime(day.year, day.month, day.day)] ?? [], isToday: true),
            outsideBuilder: (context, day, focusedDay) => _buildMonthCell(day, eventsMap[DateTime(day.year, day.month, day.day)] ?? [], isOutside: true),
            selectedBuilder: (context, day, focusedDay) => _buildMonthCell(day, eventsMap[DateTime(day.year, day.month, day.day)] ?? []),
          ),
        ),
      ),
    );
  }

  Widget _buildMonthCell(DateTime day, List<EventModel> events, {bool isToday = false, bool isOutside = false}) {
    return Container(
      margin: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        color: isToday ? const Color(0xFFE0F2FE) : (isOutside ? const Color(0xFFF8FAFC) : Colors.white),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2, right: 4),
            child: Text(
              '${day.day}',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                color: isOutside ? const Color(0xFF94A3B8) : (isToday ? const Color(0xFF1A73E8) : const Color(0xFF0F172A)),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              children: events.map((event) {
                final color = _getEventColor(event.id);
                return InkWell(
                  onTap: () => _openEventDialog(event),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      event.name,
                      style: TextStyle(
                        fontSize: 9,
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekView(Map<DateTime, List<EventModel>> eventsMap) {
    const double hourHeight = 60.0;
    DateTime startOfWeek = _focusedDay.subtract(Duration(days: _focusedDay.weekday % 7));
    
    return Expanded(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 50,
                  child: Column(
                    children: [
                      const SizedBox.shrink(),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    children: List.generate(7, (index) {
                      final day = startOfWeek.add(Duration(days: index));
                      final isToday = day.year == DateTime.now().year && day.month == DateTime.now().month && day.day == DateTime.now().day;
                      return Expanded(
                        child: Column(
                          children: [
                            Text(
                              DateFormat('EEE', 'en_US').format(day).toUpperCase(),
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isToday ? const Color(0xFF1A73E8) : Colors.grey),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: isToday ? const Color(0xFF1A73E8) : Colors.transparent,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '${day.day}',
                                style: TextStyle(fontSize: 14, color: isToday ? Colors.white : const Color(0xFF0F172A), fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: SingleChildScrollView(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 50,
                    child: Column(
                      children: List.generate(24, (index) {
                        if (index == 0) return const SizedBox(height: hourHeight);
                        final hour = index;
                        final displayHour = hour > 12 ? hour - 12 : hour;
                        final amPm = hour >= 12 ? 'PM' : 'AM';
                        return SizedBox(
                          height: hourHeight,
                          child: Center(
                            child: Text(
                              '$displayHour $amPm',
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: List.generate(7, (colIndex) {
                        final currentDay = startOfWeek.add(Duration(days: colIndex));
                        final dateKey = DateTime(currentDay.year, currentDay.month, currentDay.day);
                        final dayEvents = eventsMap[dateKey] ?? [];
                        return Expanded(
                          child: Container(
                            decoration: const BoxDecoration(
                              border: Border(left: BorderSide(color: Color(0xFFE2E8F0), width: 1.0)),
                            ),
                            child: Stack(
                              children: [
                                Column(
                                  children: List.generate(24, (index) {
                                    return Container(
                                      height: hourHeight,
                                      decoration: const BoxDecoration(
                                        border: Border(
                                          top: BorderSide(color: Color(0xFFE2E8F0), width: 1.0),
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                                ...dayEvents.map((e) {
                                  final range = _parseTimeRange(e.time);
                                  final color = _getEventColor(e.id);
                                  return Positioned(
                                    top: range[0] * hourHeight,
                                    height: (range[1] - range[0]) * hourHeight,
                                    left: 0,
                                    right: 2,
                                    child: InkWell(
                                      onTap: () => _openEventDialog(e),
                                      child: Container(
                                        margin: const EdgeInsets.only(top: 1, bottom: 1),
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: color.withValues(alpha: 0.2),
                                          border: Border(left: BorderSide(color: color, width: 3)),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          e.name,
                                          style: TextStyle(
                                            fontSize: 9,
                                            color: color,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openEventDialog(EventModel event) {
    showDialog(
      context: context,
      builder: (formContext) {
        return EventFormDialog(
          existingEvent: event,
          dummyEvents: dummyEvents,
          onSave: (updatedEvent, isEdit) {
            setState(() {
              final index = dummyEvents.indexWhere((e) => e.id == updatedEvent.id);
              if (index != -1) {
                dummyEvents[index] = updatedEvent;
              }
            });
          },
          onDelete: (eventToDelete) {
            setState(() {
              dummyEvents.removeWhere((e) => e.id == eventToDelete.id);
            });
          },
        );
      }
    );
  }

  Widget _buildAgendaView(Map<DateTime, List<EventModel>> eventsMap) {
    final sortedDates = eventsMap.keys.toList()..sort();
    
    if (sortedDates.isEmpty || eventsMap.values.every((l) => l.isEmpty)) {
      return const Expanded(
        child: Center(child: Text('Tidak ada event mendatang.')),
      );
    }
    
    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: sortedDates.length,
        itemBuilder: (context, index) {
          final date = sortedDates[index];
          final events = eventsMap[date]!;
          if (events.isEmpty) return const SizedBox.shrink();
          
          events.sort((a, b) => _timeToDouble(a.time).compareTo(_timeToDouble(b.time)));
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 80,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('EEE', 'en_US').format(date).toUpperCase(),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                      ),
                      Text(
                        '${date.day}',
                        style: TextStyle(
                          fontSize: 24, 
                          fontWeight: FontWeight.bold,
                          color: (date.year == DateTime.now().year && date.month == DateTime.now().month && date.day == DateTime.now().day) 
                            ? const Color(0xFF1A73E8) 
                            : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: events.map((event) {
                      final color = _getEventColor(event.id);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: InkWell(
                          onTap: () => _openEventDialog(event),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 70,
                                child: Text(
                                  event.time,
                                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border(left: BorderSide(color: color, width: 4)),
                                  ),
                                  child: Text(
                                    event.name,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: color,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildYearView(Map<DateTime, List<EventModel>> eventsMap) {
    final year = _focusedDay.year;
    final months = List.generate(12, (index) => index + 1);
    final monthNames = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    
    return Expanded(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(LucideIcons.chevronLeft),
                  onPressed: () => setState(() => _focusedDay = DateTime(_focusedDay.year - 1, _focusedDay.month, 1)),
                ),
                Text(
                  year.toString(),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.chevronRight),
                  onPressed: () => setState(() => _focusedDay = DateTime(_focusedDay.year + 1, _focusedDay.month, 1)),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: MediaQuery.of(context).size.width > 800 ? 3 : 2,
                childAspectRatio: 0.85,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: 12,
              itemBuilder: (context, index) {
                final month = months[index];
                
                final firstDayOfMonth = DateTime(year, month, 1);
                final daysInMonth = DateUtils.getDaysInMonth(year, month);
                final firstWeekday = firstDayOfMonth.weekday;
                final offset = firstWeekday == 7 ? 0 : firstWeekday;
                
                return InkWell(
                  onTap: () {
                    setState(() {
                      _focusedDay = DateTime(year, month, 1);
                      _calendarViewMode = 'Bulan';
                    });
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 8),
                        child: Text(
                          monthNames[index],
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: month == DateTime.now().month && year == DateTime.now().year ? const Color(0xFF1A73E8) : const Color(0xFF334155),
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: ['S', 'M', 'T', 'W', 'T', 'F', 'S'].map((dayChar) {
                          return Expanded(
                            child: Center(
                              child: Text(dayChar, style: const TextStyle(fontSize: 9, color: Colors.grey)),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 4),
                      Expanded(
                        child: GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 7,
                            childAspectRatio: 1.0,
                          ),
                          itemCount: 42,
                          itemBuilder: (context, dayIndex) {
                            if (dayIndex < offset || dayIndex >= offset + daysInMonth) {
                              return const SizedBox();
                            }
                            final dayNumber = dayIndex - offset + 1;
                            final dateKey = DateTime(year, month, dayNumber);
                            final hasEvent = eventsMap.containsKey(dateKey) && eventsMap[dateKey]!.isNotEmpty;
                            final isToday = dateKey.year == DateTime.now().year && dateKey.month == DateTime.now().month && dateKey.day == DateTime.now().day;
                            
                            return Center(
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: isToday ? const Color(0xFF1A73E8) : Colors.transparent,
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '$dayNumber',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: hasEvent ? FontWeight.bold : FontWeight.normal,
                                        color: isToday ? Colors.white : (hasEvent ? const Color(0xFF0F172A) : const Color(0xFF64748B)),
                                      ),
                                    ),
                                    if (hasEvent && !isToday)
                                      Container(
                                        width: 3,
                                        height: 3,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFAC282C),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayView(Map<DateTime, List<EventModel>> eventsMap) {
    final date = DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day);
    final events = eventsMap[date] ?? [];
    const double hourHeight = 60.0;
    
    return Expanded(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 50,
                  child: Column(
                    children: [
                      const SizedBox.shrink(),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(LucideIcons.chevronLeft, size: 20),
                        onPressed: () => setState(() => _selectedDay = _selectedDay!.subtract(const Duration(days: 1))),
                      ),
                      Column(
                        children: [
                          Text(
                            DateFormat('EEE', 'en_US').format(_selectedDay!).toUpperCase(),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(
                              color: Color(0xFF1A73E8),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${_selectedDay!.day}',
                              style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.chevronRight, size: 20),
                        onPressed: () => setState(() => _selectedDay = _selectedDay!.add(const Duration(days: 1))),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: SingleChildScrollView(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 50,
                    child: Column(
                      children: List.generate(24, (index) {
                        if (index == 0) return const SizedBox(height: hourHeight);
                        final hour = index;
                        final displayHour = hour > 12 ? hour - 12 : hour;
                        final amPm = hour >= 12 ? 'PM' : 'AM';
                        return SizedBox(
                          height: hourHeight,
                          child: Center(
                            child: Text(
                              '$displayHour $amPm',
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  Expanded(
                    child: Stack(
                      children: [
                        Column(
                          children: List.generate(24, (index) {
                            return Container(
                              height: hourHeight,
                              decoration: const BoxDecoration(
                                border: Border(
                                  top: BorderSide(color: Color(0xFFE2E8F0), width: 1.0),
                                ),
                              ),
                            );
                          }),
                        ),
                        ...events.map((e) {
                          final range = _parseTimeRange(e.time);
                          final startHour = range[0];
                          final endHour = range[1];
                          final color = _getEventColor(e.id);
                          return Positioned(
                            top: startHour * hourHeight,
                            height: (endHour - startHour) * hourHeight,
                            left: 0,
                            right: 8,
                            child: InkWell(
                              onTap: () => _openEventDialog(e),
                              child: Container(
                                margin: const EdgeInsets.only(top: 1, bottom: 1),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.2),
                                  border: Border(left: BorderSide(color: color, width: 4)),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  e.name,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: color,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }


  void _showAddSetPhotoboothDialog({SetPhotoboothModel? existingItem}) {
    showDialog(
      context: context,
      builder: (formContext) {
        return SetPhotoboothFormDialog(
          existingItem: existingItem,
          dummyItems: [], // No need for dummyItems when using Firebase
          onSave: (updatedItem, isEdit) async {
            if (isEdit) {
              await _firebaseService.updateSetPhotobooth(updatedItem);
            } else {
              await _firebaseService.addSetPhotobooth(updatedItem);
            }
          },
          onDelete: (itemToDelete) async {
            await _firebaseService.deleteSetPhotobooth(itemToDelete.id);
          },
        );
      },
    );
  }

}

class EventFormDialog extends StatefulWidget {
  final EventModel? existingEvent;
  final DateTime? initialDate;
  final Function(EventModel, bool) onSave;
  final Function(EventModel)? onDelete;
  final List<EventModel> dummyEvents;

  const EventFormDialog({
    Key? key,
    this.existingEvent,
    this.initialDate,
    required this.onSave,
    this.onDelete,
    required this.dummyEvents,
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
            Padding(
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
                    onChanged: (val) => _markEdited(),
                    decoration: InputDecoration(
                      hintText: 'Masukkan nama event...',
                      hintStyle: GoogleFonts.poppins(color: const Color(0xFF94A3B8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                        borderSide: const BorderSide(color: Color(0xFFAC282C)),
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
                              onTap: () async {
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
                                    const Icon(LucideIcons.calendar, size: 16, color: Color(0xFF64748B)),
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
                              onTap: () async {
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
                                    const Icon(LucideIcons.calendar, size: 16, color: Color(0xFF64748B)),
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
                        onTap: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: _selectedTime ?? TimeOfDay.now(),
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
                              const Icon(LucideIcons.clock, size: 16, color: Color(0xFF64748B)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
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
                            event.id != widget.existingEvent?.id && // don't compare with self when editing
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final int selectionIndexFromTheRight = newValue.text.length - newValue.selection.end;

    final stripped = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (stripped.isEmpty) {
      return const TextEditingValue(text: '');
    }
    
    String result = '';
    for (int i = 0; i < stripped.length; i++) {
      if (i > 0 && i % 3 == 0) {
        result = '.$result';
      }
      result = stripped[stripped.length - 1 - i] + result;
    }

    return TextEditingValue(
      text: result,
      selection: TextSelection.collapsed(offset: result.length - selectionIndexFromTheRight),
    );
  }
}

class SetPhotoboothFormDialog extends StatefulWidget {
  final SetPhotoboothModel? existingItem;
  final List<SetPhotoboothModel> dummyItems;
  final Function(SetPhotoboothModel, bool) onSave;
  final Function(SetPhotoboothModel)? onDelete;

  const SetPhotoboothFormDialog({
    Key? key,
    this.existingItem,
    required this.dummyItems,
    required this.onSave,
    this.onDelete,
  }) : super(key: key);

  @override
  State<SetPhotoboothFormDialog> createState() => _SetPhotoboothFormDialogState();
}

class _SetPhotoboothFormDialogState extends State<SetPhotoboothFormDialog> {
  late TextEditingController _nameController;
    late TextEditingController _stockController;
  bool _isEdited = false;
  final FirebaseService _firebaseService = FirebaseService();
  List<SetPhotoboothModel> _existingItemsList = [];
  bool _isDuplicate = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existingItem?.name ?? '');
    
        
    _stockController = TextEditingController(text: widget.existingItem != null ? widget.existingItem!.qty.toString() : '');

    _nameController.addListener(_markAsEdited);
        _stockController.addListener(_markAsEdited);

    _firebaseService.setPhotoboothStream.first.then((items) {
      if (mounted) setState(() => _existingItemsList = items);
    });
  }

  void _markAsEdited() {
    if (!_isEdited) setState(() => _isEdited = true);
    _checkDuplicate();
  }

  void _checkDuplicate() {
    final name = _nameController.text.trim().toLowerCase();
    
    if (name.isEmpty ) {
      if (_isDuplicate) setState(() => _isDuplicate = false);
      return;
    }

    bool found = _existingItemsList.any((item) => 
      item.name.toLowerCase() == name  && item.id != widget.existingItem?.id
    );

    if (_isDuplicate != found) {
      setState(() => _isDuplicate = found);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
        _stockController.dispose();
    super.dispose();
  }

  void _saveItem() {
    if (_nameController.text.trim().isEmpty || _stockController.text.trim().isEmpty) {
      return;
    }

        final stock = int.tryParse(_stockController.text.trim()) ?? 0;

    final updatedItem = SetPhotoboothModel(
      id: widget.existingItem?.id ?? 'a${widget.dummyItems.length + 1}_${DateTime.now().millisecondsSinceEpoch}',
      name: _nameController.text.trim(),
      qty: stock,
      updatedAt: DateTime.now(),
    );

    widget.onSave(updatedItem, widget.existingItem != null);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bool showDeleteBtn = widget.existingItem != null && !_isEdited;
    
    // Get unique item names for autocomplete
    final Iterable<String> existingNames = _existingItemsList.map((e) => e.name).toSet();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: MediaQuery.of(context).size.width > 500 ? 400 : MediaQuery.of(context).size.width * 0.9,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
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
                    widget.existingItem != null ? 'Detail Barang' : 'Tambah Barang',
                    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFFAC282C)),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(LucideIcons.x, size: 20, color: const Color(0xFF0F172A)),
                    splashRadius: 20,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Nama Barang', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF475569))),
                    const SizedBox(height: 8),
                    Autocomplete<String>(
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        if (textEditingValue.text.isEmpty) return existingNames;
                        return existingNames.where((String option) {
                          return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                        });
                      },
                      onSelected: (String selection) {
                        _nameController.text = selection;
                        _markAsEdited();
                      },
                      fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                        if (textEditingController.text != _nameController.text && !focusNode.hasFocus) {
                          textEditingController.text = _nameController.text;
                        }
                        textEditingController.addListener(() {
                          _nameController.text = textEditingController.text;
                        });
                        return TextField(
                          controller: textEditingController,
                          focusNode: focusNode,
                          decoration: InputDecoration(
                            hintText: '',
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.black)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.black)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFAC282C), width: 2)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        );
                      },
                    ),
                    if (_isDuplicate)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text('Item telah ada dalam database', style: GoogleFonts.poppins(fontSize: 12, color: Colors.red)),
                      ),
                    const SizedBox(height: 16),
                    Text('Jumlah', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF475569))),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _stockController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: '',
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.black)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.black)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFAC282C), width: 2)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: showDeleteBtn ? () async {
                          if (widget.onDelete != null && widget.existingItem != null) {
                            final bool? confirm = await showDeleteConfirmationDialog(
                              context: context,
                              title: 'Hapus Aksesoris',
                              content: 'Anda yakin ingin menghapus aksesoris "${widget.existingItem!.name}" secara permanen?',
                            );
                            if (confirm == true) {
                              widget.onDelete!(widget.existingItem!);
                              if (context.mounted) Navigator.pop(context);
                            }
                          }
                        } : _saveItem,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: showDeleteBtn ? const Color(0xFFDC2626) : const Color(0xFFAC282C),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                        child: Text(
                          showDeleteBtn ? 'Hapus Item' : 'Simpan',
                          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatIndonesianDate(DateTime date) {
  const months = ['januari', 'februari', 'maret', 'april', 'mei', 'juni', 'juli', 'agustus', 'september', 'oktober', 'november', 'desember'];
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '${date.day} ${months[date.month - 1]} $hour:$minute';
}
