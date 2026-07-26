import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/event_model.dart';
import '../services/firebase_service.dart';

class PastEventCard extends StatefulWidget {
  final EventModel event;
  final int index;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isSelected;

  const PastEventCard({
    Key? key,
    required this.event,
    required this.index,
    this.onTap,
    this.onLongPress,
    this.isSelected = false,
  }) : super(key: key);

  @override
  State<PastEventCard> createState() => _PastEventCardState();
}

class _PastEventCardState extends State<PastEventCard> {
  final FirebaseService _firebaseService = FirebaseService();
  bool _isHovered = false;
  bool _isPressed = false;
  
  late Future<Map<String, dynamic>> _summaryFuture;

  @override
  void initState() {
    super.initState();
    _summaryFuture = _firebaseService.getEventSummary(widget.event.id, widget.event.date);
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEEE, d MMMM yyyy', 'id_ID');
    final timeFormat = DateFormat('HH:mm');
    String dateDisplay = dateFormat.format(widget.event.date);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (widget.index * 100).clamp(0, 1000)),
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
            if (widget.onTap != null) {
              widget.onTap!();
            }
          },
          onLongPress: () {
            if (widget.onLongPress != null) {
              widget.onLongPress!();
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
                color: widget.isSelected ? const Color(0xFFFEE2E2) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: widget.isSelected ? const Color(0xFFAC282C) : (_isHovered ? const Color(0xFFAC282C) : const Color(0xFFAC282C)),
                  width: widget.isSelected ? 2.5 : (_isHovered ? 1.5 : 1.0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFAC282C).withValues(alpha: widget.isSelected ? 0.4 : (_isHovered ? 0.3 : 0.15)),
                    blurRadius: _isHovered ? 15 : 8,
                    spreadRadius: _isHovered ? 2 : 0,
                    offset: _isHovered ? const Offset(0, 4) : const Offset(0, 2),
                  )
                ],
              ),
              child: FutureBuilder<Map<String, dynamic>>(
                future: _summaryFuture,
                builder: (context, snapshot) {
                  String timeDisplay = 'Memuat...';
                  String sessionDisplay = '...';
                  
                  if (snapshot.hasData) {
                    final data = snapshot.data!;
                    final startTime = data['startTime'] as DateTime?;
                    final endTime = data['endTime'] as DateTime?;
                    final sessionCount = data['sessionCount'] as int;
                    
                    if (startTime != null) {
                      String startStr = timeFormat.format(startTime);
                      String endStr = endTime != null ? timeFormat.format(endTime) : 'Selesai';
                      timeDisplay = '$startStr - $endStr';
                    } else {
                      timeDisplay = 'Tidak ada transaksi';
                    }
                    sessionDisplay = '$sessionCount Sesi';
                  } else if (snapshot.hasError) {
                    timeDisplay = 'Error';
                    sessionDisplay = '-';
                  }

                  return Material(
                    color: Colors.transparent,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.event.name,
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            dateDisplay,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: const Color(0xFF64748B),
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
                              Text(
                                sessionDisplay,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
