import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../widgets/shared_calendar_widget.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/firebase_service.dart';
import '../widgets/notification_bell.dart';

import '../models/event_model.dart';
import '../models/aksesoris_item_model.dart';
import 'kasir_screen.dart';
import 'master_event_screen.dart';
import 'report_screen.dart';

class LandingScreen extends StatefulWidget {
  final void Function(EventModel)? onBukaKasir;
  final String role;

  const LandingScreen({super.key, this.onBukaKasir, this.role = 'admin'});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  int _selectedIndex = 1; // Keeping this just in case other things break, wait, I will remove it.

  final TextEditingController _eventNameController = TextEditingController();
  final TextEditingController _searchLaporanController = TextEditingController();
  String _searchLaporanQuery = '';
  int? _selectedMonthFilter;
  bool _isFilterOpen = false;
  
  final TextEditingController _aksesorisNameController = TextEditingController();
  final TextEditingController _aksesorisPriceController = TextEditingController();
  final TextEditingController _aksesorisStockController = TextEditingController();
  final PageController _pageController = PageController();
  int _currentCatalogPage = 0;
  String _calendarViewMode = 'Bulan';

  // KPI Streams — must be stored so IndexedStack doesn't reset them
  late final Stream<int> _todayBoothStream;
  late final Stream<int> _last7DaysRevenueStream;
  late final Stream<int> _last7DaysBoothStream;
  late final Stream<int> _last7DaysAksesorisStream;

  @override
  void initState() {
    super.initState();
    _todayBoothStream = _firebaseService.todayBoothSelesaiCountStream;
    _last7DaysRevenueStream = _firebaseService.last7DaysRevenueStream;
    _last7DaysBoothStream = _firebaseService.last7DaysBoothSelesaiCountStream;
    _last7DaysAksesorisStream = _firebaseService.last7DaysAksesorisItemsSoldStream;
  }

  @override
  void dispose() {
    _eventNameController.dispose();
    _searchLaporanController.dispose();
    _aksesorisNameController.dispose();
    _aksesorisPriceController.dispose();
    _aksesorisStockController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Suaja ',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFAC282C),
                  letterSpacing: 0.5,
                ),
              ),
              TextSpan(
                text: 'PHOTOBOOTH',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0F172A),
                  letterSpacing: 2.5,
                ),
              ),
            ],
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
        child: Stack(
          fit: StackFit.expand,
          children: [
            SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  _buildKpiCards(),
                  const SizedBox(height: 20),
                  _buildCalendar(),
                  const SizedBox(height: 24),
                  _buildEventSessionsChart(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventSessionsChart() {
    return StreamBuilder<List<EventModel>>(
      stream: _firebaseService.eventsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        var events = snapshot.data ?? [];
        events.sort((a, b) => b.date.compareTo(a.date));
        final recentEvents = events.take(7).toList();
        final chartEvents = recentEvents.reversed.toList();
        
        if (chartEvents.isEmpty) {
          return const SizedBox();
        }

        final random = math.Random(42);

        return FutureBuilder<List<int>>(
          future: Future.wait(chartEvents.map((e) async {
            return await _firebaseService.getEventSessionCountByDate(e.id, e.date);
          })),
          builder: (context, futureSnapshot) {
            if (!futureSnapshot.hasData) {
              return const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            
            final sessionCounts = futureSnapshot.data!;
            
            int maxSession = 1;
            for (var count in sessionCounts) {
              if (count > maxSession) maxSession = count;
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.bar_chart, size: 20, color: Color(0xFFAC282C)),
                        const SizedBox(width: 8),
                        Text(
                          'Grafik Sesi Event',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1, color: Color(0xFFE2E8F0)),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 200,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(chartEvents.length, (i) {
                          final event = chartEvents[i];
                          final count = sessionCounts[i];
                          final color = Color((random.nextDouble() * 0xFFFFFF).toInt()).withValues(alpha: 1.0);
                          
                          final double heightRatio = count / maxSession;
                          double barHeight = heightRatio * 130.0; // slightly shorter to make room for text above
                          
                          return Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  '$count',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF334155),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  width: 30,
                                  height: barHeight,
                                  decoration: BoxDecoration(
                                    color: color,
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(4),
                                      topRight: Radius.circular(4),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  height: 32, // Fixed height ensures bottom of bars align perfectly
                                  child: Text(
                                    event.name,
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Color(0xFF64748B),
                                    ),
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
            );
          }
        );
      },
    );
  }

  Widget _buildKpiCards() {
    final isAdmin = widget.role == 'admin';
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    Widget kpiCard({
      required String label,
      required IconData icon,
      required Color iconColor,
      required Color bgColor,
      required Stream<dynamic> stream,
      String Function(dynamic)? formatter,
    }) {
      return StreamBuilder<dynamic>(
        stream: stream,
        builder: (context, snap) {
          final value = snap.data;
          final displayText = value == null
              ? '...'
              : (formatter != null ? formatter(value) : '$value');
          return Container(
            padding: const EdgeInsets.all(16),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, size: 17, color: iconColor),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        displayText,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    }

    final List<Widget> cards = isAdmin
        ? [
            kpiCard(
              label: 'Event Mendatang',
              icon: LucideIcons.calendarDays,
              iconColor: const Color(0xFFAC282C),
              bgColor: const Color(0xFFFEE2E2),
              stream: _firebaseService.getUpcomingEventDaysCount().asStream(),
            ),
            kpiCard(
              label: 'Pendapatan Minggu Ini',
              icon: LucideIcons.trendingUp,
              iconColor: const Color(0xFF059669),
              bgColor: const Color(0xFFD1FAE5),
              stream: _last7DaysRevenueStream,
              formatter: (v) => currency.format(v),
            ),
            kpiCard(
              label: 'Sesi Selesai Minggu Ini',
              icon: LucideIcons.checkCircle,
              iconColor: const Color(0xFF2563EB),
              bgColor: const Color(0xFFDBEAFE),
              stream: _last7DaysBoothStream,
            ),
            kpiCard(
              label: 'Item Aksesoris Terjual',
              icon: LucideIcons.shoppingBag,
              iconColor: const Color(0xFFD97706),
              bgColor: const Color(0xFFFEF3C7),
              stream: _last7DaysAksesorisStream,
            ),
          ]
        : [
            kpiCard(
              label: 'Event Mendatang',
              icon: LucideIcons.calendarDays,
              iconColor: const Color(0xFFAC282C),
              bgColor: const Color(0xFFFEE2E2),
              stream: _firebaseService.getUpcomingEventDaysCount().asStream(),
            ),
            kpiCard(
              label: 'Sesi Selesai Hari Ini',
              icon: LucideIcons.checkCircle,
              iconColor: const Color(0xFF059669),
              bgColor: const Color(0xFFD1FAE5),
              stream: _todayBoothStream,
            ),
          ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: isAdmin
          ? GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.4,
              children: cards,
            )
          : Row(
              children: [
                Expanded(child: cards[0]),
                const SizedBox(width: 12),
                Expanded(child: cards[1]),
              ],
            ),
    );
  }

  Widget _buildCalendar() {
    return StreamBuilder<List<EventModel>>(
      stream: _firebaseService.eventsStream,
      builder: (context, snapshot) {
        final events = snapshot.data ?? [];

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
        eventsMap.forEach((date, evs) {
          evs.sort((a, b) => a.time.compareTo(b.time));
        });

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(
            height: 650,
            child: SharedCalendarWidget(
            eventsMap: eventsMap,
            onEventTap: _openEventDialog,
            isReadOnly: true,
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopCards(BoxConstraints constraints) {
    final isDesktop = constraints.maxWidth > 800;
    
    return SizedBox(
      height: isDesktop ? 620 : 800,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentCatalogPage = index;
                    });
                  },
                  children: [
                    _buildCalendar(),
                    _buildAksesorisCatalogCard(),
                  ],
                ),
                if (isDesktop && _currentCatalogPage > 0)
                  Positioned(
                    left: 16,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(LucideIcons.chevronLeft, color: Color(0xFFAC282C)),
                        onPressed: () {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                      ),
                    ),
                  ),
                if (isDesktop && _currentCatalogPage < 1)
                  Positioned(
                    right: 16,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(LucideIcons.chevronRight, color: Color(0xFFAC282C)),
                        onPressed: () {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(2, (index) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 8,
                width: _currentCatalogPage == index ? 24 : 8,
                decoration: BoxDecoration(
                  color: _currentCatalogPage == index ? const Color(0xFFAC282C) : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildAksesorisCatalogCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Katalog Aksesoris',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => _showAddAksesorisDialog(),
                  icon: const Icon(LucideIcons.plus, size: 16),
                  label: const Text('Tambah Item'),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFFAC282C),
                    side: const BorderSide(color: Color(0xFFAC282C)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: dummyAksesorisItems.length,
              itemBuilder: (context, index) {
                final item = dummyAksesorisItems[index];
                return _buildAksesorisItemCard(item);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAksesorisItemCard(AksesorisItemModel item) {
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return InkWell(
      onTap: () => _showAddAksesorisDialog(existingItem: item),
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
                Text(
                  currency.format(item.price),
                  style: const TextStyle(color: Color(0xFFAC282C), fontWeight: FontWeight.w600),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: item.stock > 0 ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: item.stock > 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
              ),
              child: Text(
                'Stok: ${item.stock}',
                style: TextStyle(
                  color: item.stock > 0 ? const Color(0xFF059669) : const Color(0xFFDC2626),
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

  void _showAddAksesorisDialog({AksesorisItemModel? existingItem}) {
    showDialog(
      context: context,
      builder: (formContext) {
        return AksesorisFormDialog(
          existingItem: existingItem,
          dummyItems: [], // No need for dummyItems when using Firebase
          onSave: (updatedItem, isEdit) async {
            if (isEdit) {
              await _firebaseService.updateAccessory(updatedItem);
            } else {
              await _firebaseService.addAccessory(updatedItem);
            }
          },
          onDelete: (itemToDelete) async {
            await _firebaseService.deleteAccessory(itemToDelete.id);
          },
        );
      },
    );
  }

  void _openEventDialog(EventModel event) {
    if (widget.role == 'kasir') {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Buka Kasir', style: TextStyle(fontWeight: FontWeight.bold)),
            content: Text('Apakah Anda ingin membuka mode kasir untuk event:\n\n"${event.name}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFAC282C),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  if (widget.onBukaKasir != null) {
                    widget.onBukaKasir!(event);
                  }
                },
                child: const Text('Buka Kasir', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      );
      return;
    }

    showDialog(
      context: context,
      builder: (formContext) {
        return EventFormDialog(
          existingEvent: event,
          dummyEvents: [], // Not needed for firebase real-time stream
          readOnly: true,
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
                        onPressed: () {
                          if (showDeleteBtn) {
                            if (widget.onDelete != null && widget.existingEvent != null) {
                              widget.onDelete!(widget.existingEvent!);
                            }
                            Navigator.pop(context);
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

class AksesorisFormDialog extends StatefulWidget {
  final AksesorisItemModel? existingItem;
  final List<AksesorisItemModel> dummyItems;
  final Function(AksesorisItemModel, bool) onSave;
  final Function(AksesorisItemModel)? onDelete;

  const AksesorisFormDialog({
    Key? key,
    this.existingItem,
    required this.dummyItems,
    required this.onSave,
    this.onDelete,
  }) : super(key: key);

  @override
  State<AksesorisFormDialog> createState() => _AksesorisFormDialogState();
}

class _AksesorisFormDialogState extends State<AksesorisFormDialog> {
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _stockController;
  bool _isEdited = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existingItem?.name ?? '');
    
    String initialPrice = '';
    if (widget.existingItem != null) {
      String s = widget.existingItem!.price.toString();
      String result = '';
      for (int i = 0; i < s.length; i++) {
        if (i > 0 && i % 3 == 0) result = '.$result';
        result = s[s.length - 1 - i] + result;
      }
      initialPrice = result;
    }
    _priceController = TextEditingController(text: initialPrice);
    
    _stockController = TextEditingController(text: widget.existingItem != null ? widget.existingItem!.stock.toString() : '');

    _nameController.addListener(_markAsEdited);
    _priceController.addListener(_markAsEdited);
    _stockController.addListener(_markAsEdited);
  }

  void _markAsEdited() {
    if (!_isEdited) setState(() => _isEdited = true);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  void _saveItem() {
    if (_nameController.text.trim().isEmpty || _priceController.text.trim().isEmpty || _stockController.text.trim().isEmpty) {
      return;
    }

    final priceStr = _priceController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final price = int.tryParse(priceStr) ?? 0;
    final stock = int.tryParse(_stockController.text.trim()) ?? 0;

    final updatedItem = AksesorisItemModel(
      id: widget.existingItem?.id ?? 'a${widget.dummyItems.length + 1}_${DateTime.now().millisecondsSinceEpoch}',
      name: _nameController.text.trim(),
      price: price,
      stock: stock,
    );

    widget.onSave(updatedItem, widget.existingItem != null);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bool showDeleteBtn = widget.existingItem != null && !_isEdited;
    
    // Get unique item names for autocomplete
    final Iterable<String> existingNames = widget.dummyItems.map((e) => e.name).toSet();

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
                    widget.existingItem != null ? 'Detail Item' : 'Tambah Item',
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
                    Text('Nama Item', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF475569))),
                    const SizedBox(height: 8),
                    Autocomplete<String>(
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        if (textEditingValue.text.isEmpty) return const Iterable<String>.empty();
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
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Text('Harga (Rp)', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF475569))),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [CurrencyInputFormatter()],
                      decoration: InputDecoration(
                        hintText: '',
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Stok', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF475569))),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _stockController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: '',
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: showDeleteBtn ? () {
                          if (widget.onDelete != null && widget.existingItem != null) {
                            widget.onDelete!(widget.existingItem!);
                            Navigator.pop(context);
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
