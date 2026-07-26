import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/queue_model.dart';
import '../services/firebase_service.dart';
import '../models/aksesoris_item_model.dart';
import 'package:intl/intl.dart';
import '../models/event_model.dart';
import '../widgets/animated_event_card.dart';
import '../widgets/notification_bell.dart';
import '../models/user_model.dart';

class KasirScreen extends StatefulWidget {
  final String role;
  final EventModel? activeEvent;
  final UserModel? user;
  const KasirScreen({super.key, this.role = 'admin', this.activeEvent, this.user});

  @override
  State<KasirScreen> createState() => KasirScreenState();
}

class KasirScreenState extends State<KasirScreen> {
  final FirebaseService _firebaseService = FirebaseService();

  // Custom Colors for Light Theme (Tailwind Aesthetic)
  final Color _bgColor = const Color(0xFFF8FAFC); // Slate 50
  final Color _cardColor = Colors.white;
  final Color _primaryColor = const Color(0xFFAC282C); // Suaja Red
  final Color _grayText = const Color(0xFF64748B); // Slate 500
  final Color _greenText = const Color(0xFF10B981); // Emerald 500
  final Color _redIcon = const Color(0xFFEF4444); // Red 500
  final Color _mutedText = const Color(0xFF94A3B8); // Slate 400
  final Color _textColor = const Color(0xFF0F172A); // Slate 900
  final Color _borderColor = const Color(0xFFE2E8F0); // Slate 200

  String? _expandedQueueId;
  String _selectedTab = 'MENUNGGU'; // Default tab
  String _activeCashierType = 'Booth'; // Default cashier type
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _animatingOutIds = {};
  bool _isSelectionMode = false;
  final Set<String> _selectedQueueIds = {};
  
  bool _isViewingPOS = false;
  EventModel? _localActiveEvent;

  @override
  void initState() {
    super.initState();
    _localActiveEvent = widget.activeEvent;
    if (_localActiveEvent != null) {
      _isViewingPOS = true;
    }
  }

  @override
  void didUpdateWidget(covariant KasirScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.activeEvent != oldWidget.activeEvent && widget.activeEvent != null) {
      setState(() {
        _localActiveEvent = widget.activeEvent;
        _isViewingPOS = true;
      });
    }
  }

  // Public Getters for MainScreen PopScope
  bool get isViewingPOS => _isViewingPOS;
  bool get isSelectionMode => _isSelectionMode;

  // Public Methods for MainScreen PopScope
  void closePOS() {
    setState(() {
      _isViewingPOS = false;
    });
  }

  void cancelSelection() {
    setState(() {
      _isSelectionMode = false;
      _selectedQueueIds.clear();
    });
  }

  IconData _getDeterministicIcon(String name) {
    final icons = [
      LucideIcons.flower,
      LucideIcons.glasses,
      LucideIcons.sun,
      LucideIcons.star,
      LucideIcons.moon,
      LucideIcons.heart,
      LucideIcons.cloud,
      LucideIcons.zap,
      LucideIcons.umbrella,
      LucideIcons.camera,
      LucideIcons.gift,
      LucideIcons.smile,
      LucideIcons.crown,
      LucideIcons.watch,
    ];
    final hash = name.hashCode.abs();
    return icons[hash % icons.length];
  }


  List<Map<String, dynamic>> _aksesorisCart = [];
  String? _editingAksesorisId;
  bool _isCartExpanded = false;
  bool _isAksesorisSplitPayment = false;
  String _aksesorisPaymentMethod = 'Cash';
  String _aksesorisSplitMethod1 = 'QRIS';
  String _aksesorisSplitMethod2 = 'Cash';
  int _aksesorisSplitAmount1 = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddQueueSheet({QueueModel? existingQueue}) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: _AddQueueSheet(
          firebaseService: _firebaseService,
          primaryColor: _primaryColor,
          textColor: _textColor,
          kasirName: widget.user?.name,
          existingQueue: existingQueue,
          activeEvent: _localActiveEvent,
        ),
      ),
    );
  }

  Future<void> _updateStatusWithUndo(QueueModel q, String newStatus) async {
    final String oldStatus = q.status;

    // Mulai animasi
    setState(() {
      _animatingOutIds.add(q.id);
      _expandedQueueId = null;
    });

    // Tunggu animasi geser/hilang selesai
    await Future.delayed(const Duration(milliseconds: 300));

    // Eksekusi pemindahan data di database
    _firebaseService.updateStatus(q.id, newStatus);

    if (mounted) {
      setState(() {
        _animatingOutIds.remove(q.id);
      });

      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          elevation: 0,
          behavior: SnackBarBehavior.fixed,
          backgroundColor: Colors.transparent,
          padding: EdgeInsets.zero,
          duration: const Duration(seconds: 4),
          content: _SuccessSnackbarContent(
            message: 'Berhasil! Antrian dipindah ke $newStatus.',
            duration: const Duration(seconds: 4),
            onUndo: () {
              _firebaseService.updateStatus(q.id, oldStatus);
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isViewingPOS) {
      return _buildEventListView();
    }

    return _buildPOSView();
  }

  Widget _buildEventListView() {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Kasir',
          style: GoogleFonts.poppins(
            color: _textColor,
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
      body: StreamBuilder<List<EventModel>>(
        stream: _firebaseService.eventsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Terjadi kesalahan memuat event',
                style: GoogleFonts.poppins(color: _redIcon),
              ),
            );
          }

          final dbEvents = snapshot.data ?? [];
          if (dbEvents.isEmpty) {
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

          // Flatten multi-day events
          List<EventModel> flattenedEvents = [];
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);

          for (var event in dbEvents) {
            DateTime currentDate = DateTime(event.date.year, event.date.month, event.date.day);
            final endDate = DateTime(event.endDate.year, event.endDate.month, event.endDate.day);
            
            while (!currentDate.isAfter(endDate)) {
              if (!currentDate.isBefore(today)) {
                // Create a copy of the event for each specific day
                flattenedEvents.add(
                  EventModel(
                    id: event.id,
                    name: event.name,
                    date: currentDate,
                    endDate: currentDate, // For single day display
                    time: event.time,
                    sessionCount: event.sessionCount,
                  ),
                );
              }
              currentDate = currentDate.add(const Duration(days: 1));
            }
          }

          if (flattenedEvents.isEmpty) {
            return Center(
              child: Text(
                'Tidak ada event aktif.',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: const Color(0xFF64748B),
                ),
              ),
            );
          }

          // Sort ascending by date, then ascending by time
          flattenedEvents.sort((a, b) {
            final dateComparison = a.date.compareTo(b.date);
            if (dateComparison != 0) return dateComparison;
            return a.time.compareTo(b.time);
          });

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: flattenedEvents.length,
              itemBuilder: (context, index) {
                final ev = flattenedEvents[index];
                return AnimatedEventCard(
                  event: ev,
                  index: index,
                  onBukaKasir: () {
                    setState(() {
                      _localActiveEvent = ev;
                      _isViewingPOS = true;
                    });
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildPOSView() {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: _textColor),
          onPressed: () {
            setState(() {
              _isViewingPOS = false;
            });
          },
        ),
        title: Text(
          'Transaksi',
          style: GoogleFonts.poppins(
            color: _textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1),
        ),
        actions: const [
          NotificationBellWidget(),
          SizedBox(width: 16),
        ],
      ),
      floatingActionButton:
          (_activeCashierType == 'Booth' && _selectedTab == 'MENUNGGU')
          ? FloatingActionButton(
              onPressed: _showAddQueueSheet,
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(LucideIcons.plus),
            )
          : null,
      body: SafeArea(
        child: Stack(
          children: [
            StreamBuilder<List<QueueModel>>(
              stream: _firebaseService.activeQueuesStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      '${snapshot.error}',
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allQueues = snapshot.data!;

                // Filter by active cashier type, event ID, and event date
                final eventDate = _localActiveEvent?.date ?? DateTime.now();
                final eventId = _localActiveEvent?.id ?? '';
                final queues = allQueues
                    .where((q) {
                      if (q.type != _activeCashierType) return false;
                      if (q.eventId != eventId) return false;
                      if (q.createdAt == null) return false;
                      return q.createdAt!.year == eventDate.year &&
                             q.createdAt!.month == eventDate.month &&
                             q.createdAt!.day == eventDate.day;
                    })
                    .toList();

                // Sort ascending by createdAt so the oldest (smallest queue number) is at the top
                queues.sort((a, b) {
                  final aTime = a.createdAt ?? DateTime.now();
                  final bTime = b.createdAt ?? DateTime.now();
                  return aTime.compareTo(bTime);
                });

                return StreamBuilder<List<AksesorisItemModel>>(
                  stream: _firebaseService.accessoriesStream,
                  builder: (context, aksesorisSnapshot) {
                    final accessories = aksesorisSnapshot.data ?? [];
                    
                    // Calculate Metrics
                    int totalMenunggu = 0;
                    int totalSelesai = 0;
                    int totalBatal = queues.where((q) => q.status == 'BATAL').length;

                    if (_activeCashierType == 'Aksesoris') {
                      totalMenunggu = accessories.fold(0, (sum, item) => sum + item.stock);
                      
                      for (var q in queues) {
                        if (q.status == 'SELESAI') {
                          if (q.items != null) {
                            for (var item in q.items!) {
                              totalSelesai += (item['qty'] as num?)?.toInt() ?? 0;
                            }
                          }
                        }
                      }
                    } else {
                      totalMenunggu = queues.where((q) => q.status == 'MENUNGGU').length;
                      totalSelesai = queues.where((q) => q.status == 'SELESAI').length;
                    }

                    // Filter list based on selected tab and search query
                    final filteredQueues = queues
                        .where(
                          (q) =>
                              q.status == _selectedTab &&
                              q.name.toLowerCase().contains(
                                _searchQuery.toLowerCase(),
                              ),
                        )
                        .toList();

                    // For SELESAI and BATAL, sort by most recently acted upon (updatedAt descending)
                    if (_selectedTab != 'MENUNGGU') {
                      filteredQueues.sort((a, b) {
                        final aTime = a.updatedAt ?? a.createdAt ?? DateTime.now();
                        final bTime = b.updatedAt ?? b.createdAt ?? DateTime.now();
                        return bTime.compareTo(aTime); // descending
                      });
                    }

                    // Separate pinned and regular queues
                    List<QueueModel> pinnedQueues = filteredQueues
                        .where((q) => q.isPinned)
                        .toList();
                    List<QueueModel> regularQueues = filteredQueues
                        .where((q) => !q.isPinned)
                        .toList();

                    String emptyStateMessage = 'Tidak ada data $_selectedTab';
                    if (_activeCashierType == 'Booth') {
                      if (_selectedTab == 'MENUNGGU') emptyStateMessage = 'Tidak ada antrian menunggu';
                      else if (_selectedTab == 'SELESAI') emptyStateMessage = 'Belum ada antrian diselesaikan';
                    } else if (_activeCashierType == 'Aksesoris') {
                      if (_selectedTab == 'SELESAI') emptyStateMessage = 'Belum ada item terjual';
                    }

                    return CustomScrollView(
                  slivers: [
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _StickyTabsDelegate(
                        child: Container(
                          color: Colors.white,
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                          child: _buildMetricTabs(
                            totalMenunggu,
                            totalSelesai,
                            totalBatal,
                            allQueues,
                          ),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                        child: _buildSearchBar(),
                      ),
                    ),
                    if (_activeCashierType == 'Aksesoris' &&
                        _selectedTab == 'MENUNGGU')
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24.0,
                          vertical: 24.0,
                        ),
                        sliver: _buildAksesorisGrid(accessories),
                      )
                    else if (filteredQueues.isEmpty)
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24.0,
                          vertical: 24.0,
                        ),
                        sliver: SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: Center(
                              child: Text(
                                emptyStateMessage,
                                style: TextStyle(
                                  color: _mutedText,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24.0,
                          vertical: 24.0,
                        ),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final displayQueues = [...pinnedQueues, ...regularQueues];
                            final q = displayQueues[index];
                            final queueNumber = (queues.indexOf(q) + 1).toString();
                            return _buildQueueCard(q, queueNumber);
                          }, childCount: pinnedQueues.length + regularQueues.length),
                        ),
                      ),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 100), // padding for FAB
                    ),
                  ],
                );
              },
            );
          },
        ),
            if (_activeCashierType == 'Aksesoris' && _aksesorisCart.isNotEmpty) 
              _buildAksesorisCartSheet(),
          ],
        ),
      ),
    );
  }



  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        style: TextStyle(color: _textColor, fontSize: 16),
        decoration: InputDecoration(
          hintText: 'Cari...',
          hintStyle: TextStyle(color: _mutedText, fontSize: 16),
          prefixIcon: Icon(LucideIcons.search, color: _grayText),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(LucideIcons.x, color: _grayText),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildAksesorisGrid(List<AksesorisItemModel> accessories) {
        final filtered = accessories
            .where(
              (item) => item.name.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ),
            )
            .toList();

        filtered.sort((a, b) {
          int nameCompare = a.name.compareTo(b.name);
          if (nameCompare != 0) return nameCompare;
          return a.price.compareTo(b.price);
        });

        if (filtered.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text(
                  'Belum ada stok aksesoris',
                  style: TextStyle(
                    color: _mutedText,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        }

        return SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            mainAxisExtent: 160,
          ),
          delegate: SliverChildBuilderDelegate((context, index) {
            final item = filtered[index];
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _borderColor),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(_getDeterministicIcon(item.name), color: _primaryColor, size: 28),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Stok: ${item.stock}',
                          style: TextStyle(
                            color: _primaryColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    item.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _textColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    NumberFormat.currency(
                      locale: 'id_ID',
                      symbol: 'Rp',
                      decimalDigits: 0,
                    ).format(item.price),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _greenText,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (item.stock <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Stok habis!')),
                          );
                          return;
                        }
                        
                        setState(() {
                          final existingIndex = _aksesorisCart.indexWhere(
                            (cartItem) => cartItem['id'] == item.id,
                          );
                          if (existingIndex >= 0) {
                            _aksesorisCart[existingIndex]['qty'] += 1;
                          } else {
                            _aksesorisCart.add({
                              'id': item.id,
                              'type': item.name,
                              'price': item.price,
                              'qty': 1,
                            });
                          }
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Tambah',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }, childCount: filtered.length),
        );
  }

  Widget _buildMetricTabs(int menunggu, int selesai, int batal, List<QueueModel> allQueues) {
    return Container(
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (_activeCashierType != 'Booth') {
                        setState(() => _activeCashierType = 'Booth');
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _activeCashierType == 'Booth'
                            ? _primaryColor
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _activeCashierType == 'Booth'
                              ? _primaryColor
                              : _borderColor,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Booth',
                        style: TextStyle(
                          color: _activeCashierType == 'Booth'
                              ? Colors.white
                              : _mutedText,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (_activeCashierType != 'Aksesoris') {
                        setState(() => _activeCashierType = 'Aksesoris');
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _activeCashierType == 'Aksesoris'
                            ? _primaryColor
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _activeCashierType == 'Aksesoris'
                              ? _primaryColor
                              : _borderColor,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Aksesoris',
                        style: TextStyle(
                          color: _activeCashierType == 'Aksesoris'
                              ? Colors.white
                              : _mutedText,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isSelectionMode)
            _buildSelectionBar(allQueues)
          else ...[
            Divider(height: 1, color: _borderColor),
            Row(
              children: [
                Expanded(
                  child: _buildSingleMetricTab(
                    'MENUNGGU',
                    menunggu,
                    _grayText,
                    LucideIcons.timer,
                  ),
                ),
                Container(width: 1, height: 40, color: _borderColor),
                Expanded(
                  child: _buildSingleMetricTab(
                    'SELESAI',
                    selesai,
                    _greenText,
                    LucideIcons.checkCircle2,
                  ),
                ),
                if (widget.role != 'kasir') ...[
                  Container(width: 1, height: 40, color: _borderColor),
                  Expanded(
                    child: _buildSingleMetricTab(
                      'BATAL',
                      batal,
                      _redIcon,
                      LucideIcons.trash2,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSelectionBar(List<QueueModel> allQueues) {
    // Determine if we should pin or unpin. If ANY selected item is unpinned, we PIN.
    // If ALL selected items are pinned, we UNPIN.
    bool targetPinState = false;
    for (String id in _selectedQueueIds) {
      try {
        final q = allQueues.firstWhere((q) => q.id == id);
        if (!q.isPinned) {
          targetPinState = true;
          break;
        }
      } catch (_) {}
    }

    return Container(
      color: const Color(0xFFF1F5F9), // Light gray background for selection mode
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(LucideIcons.x, color: Color(0xFF64748B)),
            onPressed: cancelSelection,
          ),
          const SizedBox(width: 8),
          Text(
            '${_selectedQueueIds.length} Terpilih',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(
              targetPinState ? LucideIcons.pin : LucideIcons.pinOff,
              color: const Color(0xFF0F172A),
            ),
            onPressed: () async {
              for (String id in _selectedQueueIds) {
                await _firebaseService.toggleQueuePin(id, targetPinState);
              }
              cancelSelection();
            },
          ),
          IconButton(
            icon: const Icon(LucideIcons.trash2, color: Color(0xFFEF4444)),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  return Dialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hapus ${_selectedQueueIds.length} transaksi?',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFF64748B),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                                child: const Text(
                                  'Batal',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () {
                                  for (String id in _selectedQueueIds) {
                                    _firebaseService.updateStatus(id, 'BATAL');
                                  }
                                  setState(() {
                                    _isSelectionMode = false;
                                    _selectedQueueIds.clear();
                                  });
                                  Navigator.pop(context);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFEF4444),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  'Hapus Transaksi',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
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
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSingleMetricTab(
    String label,
    int count,
    Color accentColor,
    IconData icon,
  ) {
    final isSelected = _selectedTab == label;
    String displayLabel =
        label[0].toUpperCase() + label.substring(1).toLowerCase();
    IconData displayIcon = icon;

    if (_activeCashierType == 'Aksesoris') {
      if (label == 'MENUNGGU') {
        displayLabel = 'Stok';
        displayIcon = LucideIcons.box;
      } else if (label == 'SELESAI')
        displayLabel = 'Terjual';
      else if (label == 'BATAL')
        displayLabel = 'Batal';
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = label;
          _expandedQueueId = null;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: isSelected ? _primaryColor : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              displayLabel,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: _mutedText,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: accentColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQueueCard(QueueModel q, String queueNumber) {
    if (q.type == 'Aksesoris') {
      return _buildAksesorisCard(q, queueNumber);
    }

    final currency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final isExpanded = _expandedQueueId == q.id;

    Color statusColor;
    IconData statusIcon;
    switch (q.status) {
      case 'MENUNGGU':
        statusColor = _grayText;
        statusIcon = LucideIcons.pencil;
        break;
      case 'SELESAI':
        statusColor = _greenText;
        statusIcon = LucideIcons.pencil;
        break;
      case 'BATAL':
      default:
        statusColor = _redIcon;
        statusIcon = LucideIcons.trash2;
        break;
    }

    final isAnimatingOut = _animatingOutIds.contains(q.id);
    final isSelected = _selectedQueueIds.contains(q.id);

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: isAnimatingOut ? 0.0 : 1.0,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 300),
        offset: isAnimatingOut ? const Offset(1.0, 0.0) : Offset.zero,
        curve: Curves.easeIn,
        child: GestureDetector(
          onLongPress: () {
            setState(() {
              _isSelectionMode = true;
              _selectedQueueIds.add(q.id);
            });
          },
          onTap: () {
            if (_isSelectionMode) {
              setState(() {
                if (isSelected) {
                  _selectedQueueIds.remove(q.id);
                  if (_selectedQueueIds.isEmpty) {
                    _isSelectionMode = false;
                  }
                } else {
                  _selectedQueueIds.add(q.id);
                }
              });
              return;
            }
            if (q.status != 'MENUNGGU' &&
                !(q.status == 'SELESAI' &&
                    q.paymentMethod == 'Split' &&
                    q.splitPayments != null))
              return;
            setState(() {
              _expandedQueueId = isExpanded ? null : q.id;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFFF0FDF4)
                  : (q.status == 'BATAL'
                        ? const Color(0xFFF1F5F9)
                        : _cardColor),
              borderRadius: BorderRadius.circular(12), // Tailwind lg
              border: Border.all(
                color: isSelected
                    ? _greenText
                    : (isExpanded ? _primaryColor : _borderColor),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                if (isExpanded)
                  BoxShadow(
                    color: _primaryColor.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                else if (q.status != 'BATAL')
                  const BoxShadow(
                    color: Color(0x0A000000), // Tailwind shadow-sm
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
              ],
            ),
            child: Opacity(
              opacity: q.status == 'BATAL' ? 0.5 : 1.0,
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Queue Number Box
                      isSelected
                          ? Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: _greenText,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Center(
                                child: Icon(
                                  LucideIcons.check,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                            )
                          : Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: _bgColor,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: _borderColor),
                              ),
                              child: Center(
                                child: Text(
                                  queueNumber,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    color: _textColor,
                                  ),
                                ),
                              ),
                            ),
                      const SizedBox(width: 20),

                      // Customer Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              q.name,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _textColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  LucideIcons.layers,
                                  size: 14,
                                  color: _primaryColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${q.totalStrips} Strip',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: _primaryColor,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  child: Text(
                                    '•',
                                    style: TextStyle(color: _mutedText),
                                  ),
                                ),
                                Text(
                                  q.paymentMethod,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: _mutedText,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  child: Text(
                                    '•',
                                    style: TextStyle(color: _mutedText),
                                  ),
                                ),
                                Text(
                                  currency.format(q.totalPayment),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: _greenText,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Timestamp and Status Icon
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Icon(
                            LucideIcons.pin,
                            size: 10,
                            color: q.isPinned ? _primaryColor : Colors.transparent,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            DateFormat('HH:mm').format(
                              q.updatedAt ?? q.createdAt ?? DateTime.now(),
                            ),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: _mutedText,
                            ),
                          ),
                          if (q.status != 'BATAL') ...[
                            const SizedBox(height: 6),
                            GestureDetector(
                              onTap: () {
                                if (q.status == 'MENUNGGU' ||
                                    q.status == 'SELESAI') {
                                  _showAddQueueSheet(existingQueue: q);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: statusColor.withValues(alpha: 0.1),
                                ),
                                child: Icon(
                                  statusIcon,
                                  color: statusColor,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),

                  // Expanded Section
                  if (isExpanded) ...[
                    if (q.paymentMethod == 'Split' &&
                        q.splitPayments != null) ...[
                      const SizedBox(height: 16),
                      Divider(color: _borderColor, height: 1),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Detail Split: ${q.splitPayments!.entries.map((e) => '${e.key} Rp${NumberFormat('#,###', 'id_ID').format(e.value)}').join(' - ')}',
                          style: TextStyle(fontSize: 13, color: _mutedText),
                        ),
                      ),
                    ],
                    if (q.status == 'MENUNGGU') ...[
                      if (!(q.paymentMethod == 'Split' &&
                          q.splitPayments != null)) ...[
                        const SizedBox(height: 16),
                        Divider(color: _borderColor, height: 1),
                      ],
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: () => _updateStatusWithUndo(q, 'SELESAI'),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: _greenText,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'SELESAI',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAksesorisCard(QueueModel q, String queueNumber) {
    final currency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final isExpanded = _expandedQueueId == q.id;
    final isSelected = _selectedQueueIds.contains(q.id);
    final isAnimatingOut = _animatingOutIds.contains(q.id);

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: isAnimatingOut ? 0.0 : 1.0,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 300),
        offset: isAnimatingOut ? const Offset(1.0, 0.0) : Offset.zero,
        curve: Curves.easeIn,
        child: GestureDetector(
          onLongPress: () {
            setState(() {
              _isSelectionMode = true;
              _selectedQueueIds.add(q.id);
            });
          },
          onTap: () {
            if (_isSelectionMode) {
              setState(() {
                if (isSelected) {
                  _selectedQueueIds.remove(q.id);
                  if (_selectedQueueIds.isEmpty) {
                    _isSelectionMode = false;
                  }
                } else {
                  _selectedQueueIds.add(q.id);
                }
              });
              return;
            }
            if (q.status == 'BATAL') return;
            _showAksesorisDetailDialog(q);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFFF0FDF4)
                  : (q.status == 'BATAL' ? const Color(0xFFF1F5F9) : _cardColor),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? _greenText
                    : (isExpanded ? _primaryColor : _borderColor),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                if (isExpanded)
                  BoxShadow(
                    color: _primaryColor.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                else if (q.status != 'BATAL')
                  const BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
              ],
            ),
            child: Opacity(
              opacity: q.status == 'BATAL' ? 0.5 : 1.0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      isSelected
                          ? Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: _greenText,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Center(
                                child: Icon(
                                  LucideIcons.check,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                            )
                          : Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: _bgColor,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: _borderColor),
                              ),
                              child: Center(
                                child: Text(
                                  queueNumber,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    color: _textColor,
                                  ),
                                ),
                              ),
                            ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [

                            Row(
                              children: [
                                Icon(
                                  LucideIcons.shoppingBag,
                                  size: 14,
                                  color: _primaryColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${q.items?.length ?? 0} Item',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: _primaryColor,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  child: Text(
                                    '•',
                                    style: TextStyle(color: _mutedText),
                                  ),
                                ),
                                Text(
                                  q.paymentMethod,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: _mutedText,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  child: Text(
                                    '•',
                                    style: TextStyle(color: _mutedText),
                                  ),
                                ),
                                Text(
                                  currency.format(q.totalPayment),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: _greenText,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Icon(
                            LucideIcons.pin,
                            size: 10,
                            color: q.isPinned ? _primaryColor : Colors.transparent,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            DateFormat('HH:mm').format(
                              q.updatedAt ?? q.createdAt ?? DateTime.now(),
                            ),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: _mutedText,
                            ),
                          ),
                          if (q.status != 'BATAL') ...[
                            const SizedBox(height: 12),
                            InkWell(
                              onTap: () {
                                setState(() {
                                  _editingAksesorisId = q.id;
                                  _aksesorisCart =
                                      List<Map<String, dynamic>>.from(
                                        q.items ?? [],
                                      );
                                  if (q.paymentMethod == 'Split' &&
                                      q.splitPayments != null) {
                                    _isAksesorisSplitPayment = true;
                                    var entries = q.splitPayments!.entries
                                        .toList();
                                    if (entries.isNotEmpty) {
                                      _aksesorisSplitMethod1 = entries[0].key;
                                      _aksesorisSplitAmount1 =
                                          entries[0].value as int;
                                    }
                                    if (entries.length > 1) {
                                      _aksesorisSplitMethod2 = entries[1].key;
                                    }
                                  } else {
                                    _isAksesorisSplitPayment = false;
                                    _aksesorisPaymentMethod = q.paymentMethod;
                                  }
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: _bgColor,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  LucideIcons.pencil,
                                  size: 16,
                                  color: _primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),

                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAksesorisCartSheet() {
    int totalPrice = _aksesorisCart.fold(
      0,
      (sum, item) => sum + ((item['price'] as int) * (item['qty'] as int)),
    );
    final currency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.2,
      maxChildSize: 1.0,
      snap: true,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              children: [
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _aksesorisCart.clear();
                          _editingAksesorisId = null;
                        });
                      },
                      child: const Text(
                        'batalkan',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w300,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _aksesorisCart.length,
                  itemBuilder: (context, index) {
                    final item = _aksesorisCart[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['type'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  currency.format(item['price']),
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(LucideIcons.minusCircle),
                                color: Colors.grey,
                                onPressed: () {
                                  setState(() {
                                    if (item['qty'] > 1) {
                                      item['qty'] -= 1;
                                    } else {
                                      _aksesorisCart.removeAt(index);
                                    }
                                  });
                                },
                              ),
                              Text(
                                '${item['qty']}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(LucideIcons.plusCircle),
                                color: _primaryColor,
                                onPressed: () {
                                  setState(() {
                                    item['qty'] += 1;
                                  });
                                },
                              ),
                            ],
                          ),
                          Expanded(
                            flex: 2,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                currency.format(
                                  (item['price'] as int) * (item['qty'] as int),
                                ),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Bayar',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          Text(
                            currency.format(totalPrice),
                            style: TextStyle(
                              color: _primaryColor,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Metode Pembayaran',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          Row(
                            children: [
                              const Text(
                                'Pisah Pembayaran',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Switch(
                                value: _isAksesorisSplitPayment,
                                onChanged: (val) {
                                  setState(() {
                                    _isAksesorisSplitPayment = val;
                                  });
                                },
                                activeColor: _primaryColor,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (!_isAksesorisSplitPayment)
                        Row(
                          children: [
                            Expanded(
                              child: _buildAksesorisPaymentButton(
                                'QRIS',
                                LucideIcons.qrCode,
                                _primaryColor,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildAksesorisPaymentButton(
                                'Cash',
                                LucideIcons.banknote,
                                _primaryColor,
                              ),
                            ),
                          ],
                        )
                      else
                        Column(
                          children: [
                            _buildAksesorisSplitPaymentRow(
                              label: 'Pembayaran 1',
                              method: _aksesorisSplitMethod1,
                              amount: _aksesorisSplitAmount1,
                              onMethodChanged: (val) =>
                                  setState(() => _aksesorisSplitMethod1 = val!),
                              onAmountChanged: (val) => setState(() {
                                _aksesorisSplitAmount1 =
                                    int.tryParse(
                                      val.replaceAll(RegExp(r'[^0-9]'), ''),
                                    ) ??
                                    0;
                                if (_aksesorisSplitAmount1 > totalPrice) {
                                  _aksesorisSplitAmount1 = totalPrice;
                                }
                              }),
                              primaryColor: _primaryColor,
                              isReadOnlyAmount: false,
                            ),
                            const SizedBox(height: 16),
                            _buildAksesorisSplitPaymentRow(
                              label: 'Pembayaran 2 (Sisa)',
                              method: _aksesorisSplitMethod2,
                              amount: totalPrice - _aksesorisSplitAmount1,
                              onMethodChanged: (val) =>
                                  setState(() => _aksesorisSplitMethod2 = val!),
                              onAmountChanged: null,
                              primaryColor: _primaryColor,
                              isReadOnlyAmount: true,
                            ),
                          ],
                        ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            QueueModel newTransaction;
                            if (_editingAksesorisId != null) {
                              newTransaction = QueueModel(
                                id: _editingAksesorisId!,
                                eventId: _localActiveEvent?.id ?? '',
                                name: 'Pelanggan Aksesoris',
                                kasirName: widget.user?.name,
                                totalStrips: 0,
                                totalPayment: totalPrice,
                                paymentMethod: _isAksesorisSplitPayment
                                    ? 'Split'
                                    : _aksesorisPaymentMethod,
                                splitPayments: _isAksesorisSplitPayment
                                    ? {
                                        _aksesorisSplitMethod1:
                                            _aksesorisSplitAmount1,
                                        _aksesorisSplitMethod2:
                                            totalPrice - _aksesorisSplitAmount1,
                                      }
                                    : null,
                                status: 'SELESAI',
                                type: 'Aksesoris',
                                items: List<Map<String, dynamic>>.from(
                                  _aksesorisCart,
                                ),
                              );
                              await _firebaseService.updateQueue(
                                newTransaction,
                              );
                            } else {
                              newTransaction = QueueModel(
                                id: DateTime.now().millisecondsSinceEpoch
                                    .toString(),
                                eventId: _localActiveEvent?.id ?? '',
                                name: 'Pelanggan Aksesoris',
                                kasirName: widget.user?.name,
                                totalStrips: 0,
                                totalPayment: totalPrice,
                                paymentMethod: _isAksesorisSplitPayment
                                    ? 'Split'
                                    : _aksesorisPaymentMethod,
                                splitPayments: _isAksesorisSplitPayment
                                    ? {
                                        _aksesorisSplitMethod1:
                                            _aksesorisSplitAmount1,
                                        _aksesorisSplitMethod2:
                                            totalPrice - _aksesorisSplitAmount1,
                                      }
                                    : null,
                                status: 'SELESAI',
                                type: 'Aksesoris',
                                items: List<Map<String, dynamic>>.from(
                                  _aksesorisCart,
                                ),
                              );
                              await _firebaseService.addQueue(newTransaction);
                            }

                            if (mounted) {
                              setState(() {
                                _aksesorisCart.clear();
                                _editingAksesorisId = null;
                                _isAksesorisSplitPayment = false;
                                _aksesorisPaymentMethod = 'Cash';
                              });

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  elevation: 0,
                                  behavior: SnackBarBehavior.fixed,
                                  backgroundColor: Colors.transparent,
                                  padding: EdgeInsets.zero,
                                  duration: const Duration(seconds: 4),
                                  content: const _SuccessSnackbarContent(
                                    message: 'Pembayaran Aksesoris Berhasil!',
                                    duration: Duration(seconds: 4),
                                  ),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            _editingAksesorisId != null
                                ? 'Simpan Perubahan'
                                : 'Bayar',
                            style: const TextStyle(
                              fontSize: 18,
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
      },
    );
  }

  Widget _buildAksesorisPaymentButton(
    String method,
    IconData icon,
    Color primaryColor,
  ) {
    final isSelected = _aksesorisPaymentMethod == method;
    return InkWell(
      onTap: () => setState(() => _aksesorisPaymentMethod = method),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor.withValues(alpha: 0.1)
              : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.black12,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? primaryColor : const Color(0xFF64748B),
              size: 28,
            ),
            const SizedBox(height: 12),
            Text(
              method,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? primaryColor : const Color(0xFF64748B),
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAksesorisSplitPaymentRow({
    required String label,
    required String method,
    required int amount,
    required void Function(String?)? onMethodChanged,
    required void Function(String)? onAmountChanged,
    required Color primaryColor,
    required bool isReadOnlyAmount,
  }) {
    final currency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );
    final bool isMobile = MediaQuery.of(context).size.width < 600;

    Widget methodWidget = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: method,
              isExpanded: true,
              items: ['QRIS', 'Cash'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(
                    value,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                );
              }).toList(),
              onChanged: onMethodChanged,
            ),
          ),
        ),
      ],
    );

    Widget amountWidget = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Nominal',
          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: isReadOnlyAmount
              ? currency.format(amount)
              : (amount > 0 ? NumberFormat('#,###', 'id_ID').format(amount) : ''),
          key: isReadOnlyAmount ? ValueKey(amount) : null,
          readOnly: isReadOnlyAmount,
          keyboardType: TextInputType.number,
          inputFormatters: [CurrencyInputFormatter()],
          onChanged: onAmountChanged,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isReadOnlyAmount ? const Color(0xFF64748B) : Colors.black,
          ),
          decoration: InputDecoration(
            prefixText: isReadOnlyAmount ? '' : 'Rp ',
            filled: isReadOnlyAmount,
            fillColor: isReadOnlyAmount
                ? const Color(0xFFF1F5F9)
                : Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
          ),
        ),
      ],
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [methodWidget, const SizedBox(height: 12), amountWidget],
      );
    } else {
      return Row(
        children: [
          Expanded(flex: 2, child: methodWidget),
          const SizedBox(width: 12),
          Expanded(flex: 3, child: amountWidget),
        ],
      );
    }
  }

  void _showAksesorisDetailDialog(QueueModel q) {
    final currency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                    border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Detail Transaksi',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFAC282C),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(
                          LucideIcons.x,
                          color: Color(0xFF64748B),
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                if (q.items != null && q.items!.isNotEmpty) ...[
                  ...q.items!.map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${item['qty']}x ${item['type']}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            currency.format(
                              (item['price'] as int) * (item['qty'] as int),
                            ),
                            style: const TextStyle(
                              fontSize: 16,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 8),
                  const Divider(color: Color(0xFFE2E8F0)),
                  const SizedBox(height: 16),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Bayar',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    Text(
                      currency.format(q.totalPayment),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Metode',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    Text(
                      q.paymentMethod,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                if (q.paymentMethod == 'Split' && q.splitPayments != null) ...[
                  const SizedBox(height: 8),
                  ...q.splitPayments!.entries.map((e) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '  • ${e.key}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          Text(
                            currency.format(e.value),
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],

              ],
              ),
            ),
          ],
        ),
      ),
    );
  },
    );
  }
}

// ==========================================
// Bottom Sheet Form Component
// ==========================================

class _AddQueueSheet extends StatefulWidget {
  final FirebaseService firebaseService;
  final Color primaryColor;
  final Color textColor;
  final String? kasirName;
  final QueueModel? existingQueue;
  final EventModel? activeEvent;

  const _AddQueueSheet({
    super.key,
    required this.firebaseService,
    required this.primaryColor,
    required this.textColor,
    this.kasirName,
    this.existingQueue,
    this.activeEvent,
  });

  @override
  State<_AddQueueSheet> createState() => _AddQueueSheetState();
}

class _AddQueueSheetState extends State<_AddQueueSheet> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  int _selectedStrips = 2;
  String _paymentMethod = 'QRIS';

  // Split payment state
  bool _isSplitPayment = false;
  String _splitMethod1 = 'QRIS';
  String _splitMethod2 = 'Cash';
  int _splitAmount1 = 0;

  int get _currentTotalPrice => 20000 + ((_selectedStrips - 2) ~/ 2) * 5000;
  int get _splitAmount2 => _currentTotalPrice - _splitAmount1;

  @override
  void initState() {
    super.initState();
    if (widget.existingQueue != null) {
      _nameController.text = widget.existingQueue!.name;
      _selectedStrips = widget.existingQueue!.totalStrips;
      _paymentMethod = widget.existingQueue!.paymentMethod;

      if (_paymentMethod == 'Split' &&
          widget.existingQueue!.splitPayments != null) {
        _isSplitPayment = true;
        final splits = widget.existingQueue!.splitPayments!;
        if (splits.keys.length >= 2) {
          _splitMethod1 = splits.keys.elementAt(0);
          _splitAmount1 = splits[_splitMethod1] as int;
          _splitMethod2 = splits.keys.elementAt(1);
        }
      }
    }
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      final isEditing = widget.existingQueue != null;

      final queue = QueueModel(
        id: isEditing ? widget.existingQueue!.id : '',
        eventId: isEditing ? widget.existingQueue!.eventId : (widget.activeEvent?.id ?? ''),
        name: _nameController.text.trim().toUpperCase(),
        totalStrips: _selectedStrips,
        totalPayment: _currentTotalPrice,
        paymentMethod: _isSplitPayment ? 'Split' : _paymentMethod,
        splitPayments: _isSplitPayment
            ? {_splitMethod1: _splitAmount1, _splitMethod2: _splitAmount2}
            : null,
        kasirName: isEditing ? widget.existingQueue!.kasirName : widget.kasirName,
        status: isEditing ? widget.existingQueue!.status : 'MENUNGGU',
        createdAt: isEditing ? widget.existingQueue!.createdAt : DateTime.now(),
      );

      try {
        if (isEditing) {
          await widget.firebaseService.updateQueue(queue);
        } else {
          await widget.firebaseService.addQueue(queue);
        }

        if (mounted) {
          Navigator.pop(context); // Close bottom sheet
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              elevation: 0,
              behavior: SnackBarBehavior.fixed,
              backgroundColor: Colors.transparent,
              padding: EdgeInsets.zero,
              duration: const Duration(seconds: 4),
              content: _SuccessSnackbarContent(
                message: isEditing
                    ? 'Berhasil! Data pelanggan diubah.'
                    : 'Berhasil! Pelanggan baru ditambahkan.',
                duration: const Duration(seconds: 4),
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(color: Color(0x1A000000), blurRadius: 20, spreadRadius: 0),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9), // Grey background for header
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.existingQueue != null
                      ? 'Edit Pelanggan'
                      : 'Tambah Pelanggan',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: widget.primaryColor,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(
                    LucideIcons.x,
                    color: Color(0xFF64748B),
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Nama Pelanggan',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        Text(
                          ' *',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: widget.primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.characters,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: widget.textColor,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Ketik nama pelanggan...',
                        hintStyle: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontWeight: FontWeight.w300,
                          fontStyle: FontStyle.italic,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFFE2E8F0),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFFE2E8F0),
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (val) => val == null || val.isEmpty
                          ? 'Nama wajib diisi'
                          : null,
                    ),
                    const SizedBox(height: 32),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Jumlah Strip',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Stepper
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(32),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _selectedStrips <= 2
                                          ? const Color(0xFFE2E8F0)
                                          : widget.primaryColor,
                                      border: Border.all(
                                        color: _selectedStrips <= 2
                                            ? const Color(0xFFE2E8F0)
                                            : widget.primaryColor,
                                      ),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Color(0x1A000000),
                                          blurRadius: 4,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: IconButton(
                                      iconSize: 16,
                                      padding: const EdgeInsets.all(4),
                                      constraints: const BoxConstraints(),
                                      onPressed: _selectedStrips <= 2
                                          ? null
                                          : () => setState(
                                              () => _selectedStrips -= 2,
                                            ),
                                      icon: const Icon(LucideIcons.minus),
                                      color: _selectedStrips <= 2
                                          ? Colors.black26
                                          : Colors.white,
                                    ),
                                  ),
                                  Container(
                                    width: 32,
                                    alignment: Alignment.center,
                                    child: Text(
                                      '$_selectedStrips',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: widget.textColor,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: widget.primaryColor,
                                      border: Border.all(
                                        color: widget.primaryColor,
                                      ),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Color(0x1A000000),
                                          blurRadius: 4,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: IconButton(
                                      iconSize: 16,
                                      padding: const EdgeInsets.all(4),
                                      constraints: const BoxConstraints(),
                                      onPressed: () =>
                                          setState(() => _selectedStrips += 2),
                                      icon: const Icon(LucideIcons.plus),
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        // Total Price
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Total Bayar',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              height:
                                  46, // Sesuaikan persis dengan tinggi stepper (46px)
                              alignment: Alignment.centerLeft,
                              child: Text(
                                currency.format(_currentTotalPrice),
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  color: widget.primaryColor,
                                  height:
                                      1.0, // Menghindari jarak berlebih pada teks
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Metode Pembayaran',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'Pisah Pembayaran',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            Switch(
                              value: _isSplitPayment,
                              onChanged: (val) {
                                setState(() {
                                  _isSplitPayment = val;
                                });
                              },
                              activeColor: widget.primaryColor,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (!_isSplitPayment)
                      Row(
                        children: [
                          Expanded(
                            child: _buildPaymentButton(
                              'QRIS',
                              LucideIcons.qrCode,
                              widget.primaryColor,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildPaymentButton(
                              'Cash',
                              LucideIcons.banknote,
                              widget.primaryColor,
                            ),
                          ),
                        ],
                      )
                    else
                      Column(
                        children: [
                          _buildSplitPaymentRow(
                            label: 'Pembayaran 1',
                            method: _splitMethod1,
                            amount: _splitAmount1,
                            onMethodChanged: (val) =>
                                setState(() => _splitMethod1 = val!),
                            onAmountChanged: (val) => setState(() {
                              _splitAmount1 =
                                  int.tryParse(
                                    val.replaceAll(RegExp(r'[^0-9]'), ''),
                                  ) ??
                                  0;
                              if (_splitAmount1 > _currentTotalPrice) {
                                _splitAmount1 = _currentTotalPrice;
                              }
                            }),
                            primaryColor: widget.primaryColor,
                            isReadOnlyAmount: false,
                          ),
                          const SizedBox(height: 16),
                          _buildSplitPaymentRow(
                            label: 'Pembayaran 2 (Sisa)',
                            method: _splitMethod2,
                            amount: _splitAmount2,
                            onMethodChanged: (val) =>
                                setState(() => _splitMethod2 = val!),
                            onAmountChanged: null,
                            primaryColor: widget.primaryColor,
                            isReadOnlyAmount: true,
                          ),
                        ],
                      ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        onPressed: _submit,
                        child: Text(
                          widget.existingQueue != null ? 'SIMPAN' : 'TAMBAH',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSplitPaymentRow({
    required String label,
    required String method,
    required int amount,
    required void Function(String?)? onMethodChanged,
    required void Function(String)? onAmountChanged,
    required Color primaryColor,
    required bool isReadOnlyAmount,
  }) {
    final currency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );
    final bool isMobile = MediaQuery.of(context).size.width < 600;

    Widget methodWidget = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: method,
              isExpanded: true,
              items: ['QRIS', 'Cash'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(
                    value,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                );
              }).toList(),
              onChanged: onMethodChanged,
            ),
          ),
        ),
      ],
    );

    Widget amountWidget = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Nominal',
          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: isReadOnlyAmount
              ? currency.format(amount)
              : (amount > 0 ? NumberFormat('#,###', 'id_ID').format(amount) : ''),
          key: isReadOnlyAmount ? ValueKey(amount) : null,
          readOnly: isReadOnlyAmount,
          keyboardType: TextInputType.number,
          inputFormatters: [CurrencyInputFormatter()],
          onChanged: onAmountChanged,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isReadOnlyAmount ? const Color(0xFF64748B) : Colors.black,
          ),
          decoration: InputDecoration(
            prefixText: isReadOnlyAmount ? '' : 'Rp ',
            filled: isReadOnlyAmount,
            fillColor: isReadOnlyAmount
                ? const Color(0xFFF1F5F9)
                : Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
          ),
        ),
      ],
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [methodWidget, const SizedBox(height: 12), amountWidget],
      );
    } else {
      return Row(
        children: [
          Expanded(flex: 2, child: methodWidget),
          const SizedBox(width: 12),
          Expanded(flex: 3, child: amountWidget),
        ],
      );
    }
  }

  Widget _buildPaymentButton(String method, IconData icon, Color primaryColor) {
    final isSelected = _paymentMethod == method;
    return InkWell(
      onTap: () => setState(() => _paymentMethod = method),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor.withValues(alpha: 0.1)
              : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.black12,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? primaryColor : const Color(0xFF64748B),
              size: 28,
            ),
            const SizedBox(height: 12),
            Text(
              method,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? primaryColor : const Color(0xFF64748B),
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }


}

class _StickyTabsDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _StickyTabsDelegate({required this.child});

  @override
  double get minExtent => 176.0;
  @override
  double get maxExtent => 176.0;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: const Color(0xFFE2E8F0))),
        boxShadow: overlapsContent
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ]
            : [],
      ),
      child: child,
    );
  }

  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return true;
  }
}

class _SuccessSnackbarContent extends StatelessWidget {
  final String message;
  final Duration duration;
  final VoidCallback? onUndo;

  const _SuccessSnackbarContent({
    required this.message,
    required this.duration,
    this.onUndo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 10,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                const Icon(
                  LucideIcons.checkCircle2,
                  color: Colors.green,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (onUndo != null)
                  InkWell(
                    onTap: () {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      onUndo!();
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: Colors.green.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Text(
                        'UNDO',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: 1.0),
            duration: duration,
            builder: (context, value, child) {
              return LinearProgressIndicator(
                value: value,
                backgroundColor: Colors.transparent,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                minHeight: 4,
              );
            },
          ),
        ],
      ),
    );
  }
}

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;
    final intValue = int.tryParse(newValue.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    final newString = NumberFormat('#,###', 'id_ID').format(intValue);
    return TextEditingValue(
      text: newString,
      selection: TextSelection.collapsed(offset: newString.length),
    );
  }
}
