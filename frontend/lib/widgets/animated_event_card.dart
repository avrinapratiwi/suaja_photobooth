import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/event_model.dart';
import '../models/queue_model.dart';
import '../services/firebase_service.dart';
import '../screens/report_screen.dart';
import '../screens/checklist_screen.dart';
import '../utils/business_day_utils.dart';

class AnimatedEventCard extends StatefulWidget {
  final EventModel event;
  final int index;
  final VoidCallback? onBukaKasir;

  const AnimatedEventCard({
    Key? key,
    required this.event,
    required this.index,
    this.onBukaKasir,
  }) : super(key: key);

  @override
  State<AnimatedEventCard> createState() => _AnimatedEventCardState();
}

class _AnimatedEventCardState extends State<AnimatedEventCard> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final now = BusinessDayUtils.getBusinessDay();
    final todayDate = DateTime(now.year, now.month, now.day);
    final eventDate = DateTime(widget.event.date.year, widget.event.date.month, widget.event.date.day);
    final isPast = eventDate.isBefore(todayDate);
    final isToday = eventDate.isAtSameMomentAs(todayDate);

    final endDate = DateTime(widget.event.endDate.year, widget.event.endDate.month, widget.event.endDate.day);
    final isSingleDay = eventDate.isAtSameMomentAs(endDate);

    final dateFormat = DateFormat('EEEE, d MMMM', 'id_ID');
    String dateDisplay;
    if (isToday) {
      dateDisplay = isSingleDay ? 'Hari ini' : 'Hari ini - ${dateFormat.format(widget.event.endDate)}';
    } else {
      dateDisplay = isSingleDay ? dateFormat.format(widget.event.date) : '${dateFormat.format(widget.event.date)} - ${dateFormat.format(widget.event.endDate)}';
    }
    
    final startTime = widget.event.time.split('-')[0].trim();
    final timeDisplay = isPast 
        ? (widget.event.time.contains('-') ? widget.event.time : '$startTime - Selesai')
        : '$startTime - Selesai';

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (widget.index * 100).clamp(0, 1000)), // Maksimum delay 1 detik agar tidak terlalu lama
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          onTap: () {
            if (eventDate.isAfter(todayDate)) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Transaksi untuk event ini belum dimulai.'),
                  backgroundColor: Color(0xFF64748B),
                ),
              );
            } else if (isPast) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ReportScreen()),
              );
            } else {
              if (widget.onBukaKasir != null) {
                widget.onBukaKasir!();
              }
            }
          },
          child: AnimatedScale(
            scale: _isPressed ? 0.98 : (_isHovered ? 1.02 : 1.0),
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeInOut,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFAC282C),
                  width: _isHovered ? 1.5 : 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFAC282C).withValues(alpha: _isHovered ? 0.3 : 0.15),
                    blurRadius: _isHovered ? 15 : 8,
                    spreadRadius: _isHovered ? 2 : 0,
                    offset: _isHovered ? const Offset(0, 4) : const Offset(0, 2),
                  )
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.event.name,
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          if (isToday) const BlinkingDot(),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        dateDisplay,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: isToday ? const Color(0xFFAC282C) : const Color(0xFF64748B),
                          fontWeight: isToday ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            timeDisplay,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                          StreamBuilder<List<QueueModel>>(
                            stream: FirebaseService().activeQueuesStream,
                            builder: (context, snapshot) {
                              int sessionCount = widget.event.sessionCount;
                              if (snapshot.hasData) {
                                sessionCount = snapshot.data!.where((q) {
                                  if (q.eventId != widget.event.id) return false;
                                  if (q.status != 'SELESAI') return false;
                                  if (q.type != 'Booth') return false;
                                  if (q.createdAt == null) return false;
                                  final qDate = BusinessDayUtils.getBusinessDayFor(q.createdAt!);
                                  return qDate.year == eventDate.year &&
                                         qDate.month == eventDate.month &&
                                         qDate.day == eventDate.day;
                                }).length;
                              }
                              return Text(
                                '$sessionCount Sesi',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF0F172A),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      if (isToday) ...[
                        const SizedBox(height: 10),
                        const Divider(height: 1, color: Color(0xFFE2E8F0)),
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChecklistScreen(event: widget.event),
                              ),
                            );
                          },
                          child: Text(
                            'Checklist Set Perlengkapan',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFFAC282C),
                              decoration: TextDecoration.underline,
                              decorationColor: const Color(0xFFAC282C),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class BlinkingDot extends StatefulWidget {
  const BlinkingDot({super.key});

  @override
  State<BlinkingDot> createState() => _BlinkingDotState();
}

class _BlinkingDotState extends State<BlinkingDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: 10,
        height: 10,
        decoration: const BoxDecoration(
          color: Color(0xFFAC282C), // Warna merah (Suaja primary)
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
